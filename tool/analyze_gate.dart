// flutter/dart analyze 基线门禁（CI 与本地共用）。
//
//   dart run tool/analyze_gate.dart                      # 校验：ERROR 或相对基线新增问题 → 退出码 1
//   dart run tool/analyze_gate.dart --update             # 收紧基线：只允许减少；有任何增加则拒绝写入
//   dart run tool/analyze_gate.dart --update --allow-increase   # 显式放宽（仅限人工、需在 PR 中说明；CI 从不使用）
//   dart run tool/analyze_gate.dart --compare-baseline <基线旧版本文件>
//                                                        # 基线文件本身只减不增：与目标分支版本比较
//   dart run tool/analyze_gate.dart --self-test          # 门禁自身的解析/判定自测
//
// 规则：
//   - 运行 `dart analyze --format=machine --fatal-infos`。退出码语义：0 无问题、1 仅 INFO、2 有 WARNING、
//     3 有 ERROR；其他退出码（如 64 用法错误、255 崩溃）一律失败。并且退出码必须与解析出的最高严重级别
//     一致，否则视为分析未正常完成或输出格式变化，失败（不会把崩溃当成「0 条问题」放过）。
//   - ERROR：一律失败，不进基线。
//   - WARNING / INFO：与 tool/analyze_baseline.txt 比较。按「严重级别|诊断码|文件」计数（不含行号，
//     避免无关改动导致行号漂移误报）；任一键的数量超过基线即失败。
//   - 问题比基线少：通过，并提示执行 --update 收紧基线。
import 'dart:convert';
import 'dart:io';

const baselinePath = 'tool/analyze_baseline.txt';
const _severityCode = {'INFO': 1, 'WARNING': 2, 'ERROR': 3};

class AnalyzeResult {
  AnalyzeResult(this.counts, this.errors);
  final Map<String, int> counts; // WARNING/INFO：键 → 数量
  final List<String> errors; // ERROR 明细
  int get total => counts.values.fold(0, (a, b) => a + b);
}

class GateFailure implements Exception {
  GateFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// 解析 machine 格式输出并校验与退出码一致。[root] 用于把绝对路径转成仓库相对路径。
AnalyzeResult evaluate(int exitCode, String output, String root) {
  if (exitCode < 0 || exitCode > 3) {
    throw GateFailure('dart analyze 异常退出（退出码 $exitCode，非问题退出码 0–3）：\n$output');
  }
  final counts = <String, int>{};
  final errors = <String>[];
  var maxCode = 0;
  for (final raw in output.split('\n')) {
    final line = raw.trimRight();
    final parts = line.split('|');
    if (parts.length < 8) continue; // 非诊断行（如 "Running build hooks..."）
    final severity = parts[0].trim();
    final code = _severityCode[severity];
    if (code == null) {
      throw GateFailure('无法识别的诊断行（输出格式可能已变化）：$line');
    }
    if (code > maxCode) maxCode = code;
    // Machine output escapes Windows backslashes; normalize both forms.
    var file = parts[3].replaceAll(RegExp(r'\\+'), '/');
    final prefix = '${root.replaceAll('\\', '/')}/';
    if (file.startsWith(prefix)) file = file.substring(prefix.length);
    if (severity == 'ERROR') {
      errors.add('$file:${parts[4]} ${parts[2]} ${parts.sublist(7).join('|')}');
      continue;
    }
    final key = '$severity|${parts[2]}|$file';
    counts[key] = (counts[key] ?? 0) + 1;
  }
  if (maxCode != exitCode) {
    throw GateFailure(
      'dart analyze 退出码 $exitCode 与解析出的最高严重级别 $maxCode 不一致，'
      '分析可能未正常完成或输出格式已变化：\n$output',
    );
  }
  return AnalyzeResult(counts, errors);
}

Map<String, int> parseBaseline(String text) {
  final baseline = <String, int>{};
  for (final line in text.split('\n')) {
    if (line.trim().isEmpty || line.startsWith('#')) continue;
    final tab = line.lastIndexOf('\t');
    if (tab < 0) throw GateFailure('基线行格式错误：$line');
    baseline[line.substring(0, tab)] = int.parse(
      line.substring(tab + 1).trim(),
    );
  }
  return baseline;
}

String formatBaseline(Map<String, int> counts) {
  final keys = counts.keys.toList()..sort();
  final buf = StringBuffer()
    ..writeln(
      '# analyze 基线：严重级别|诊断码|文件<TAB>数量。由 dart run tool/analyze_gate.dart --update 生成，只减不增。',
    );
  for (final k in keys) {
    buf.writeln('$k\t${counts[k]}');
  }
  return buf.toString();
}

/// [current] 相对 [allowed] 的增加项（新键或数量变多）。
List<String> increases(Map<String, int> current, Map<String, int> allowed) => [
  for (final e in current.entries)
    if (e.value > (allowed[e.key] ?? 0))
      '${e.key}: ${e.value}（允许 ${allowed[e.key] ?? 0}）',
];

Future<void> main(List<String> args) async {
  try {
    if (args.contains('--self-test')) {
      selfTest();
      return;
    }
    final cmp = args.indexOf('--compare-baseline');
    if (cmp >= 0) {
      compareBaseline(args[cmp + 1]);
      return;
    }
    await gate(
      update: args.contains('--update'),
      allowIncrease: args.contains('--allow-increase'),
    );
  } on GateFailure catch (e) {
    stderr.writeln(e.message);
    exit(1);
  }
}

/// 基线文件只减不增：当前 tool/analyze_baseline.txt 相对目标分支版本 [oldPath] 不得新增键或增加数量。
void compareBaseline(String oldPath) {
  final oldFile = File(oldPath);
  if (!oldFile.existsSync() || oldFile.lengthSync() == 0) {
    stdout.writeln('目标分支没有基线文件（首次引入门禁），跳过基线比较。');
    return;
  }
  final current = parseBaseline(File(baselinePath).readAsStringSync());
  final old = parseBaseline(oldFile.readAsStringSync());
  final added = increases(current, old);
  if (added.isNotEmpty) {
    throw GateFailure(
      'tool/analyze_baseline.txt 相对目标分支被放宽（基线只减不增）：\n${added.join('\n')}',
    );
  }
  stdout.writeln('基线未放宽（当前 ${current.length} 个键，目标分支 ${old.length} 个键）。');
}

Future<void> gate({required bool update, required bool allowIncrease}) async {
  final result = await Process.run(
    'dart',
    ['analyze', '--format=machine', '--fatal-infos'],
    runInShell: true,
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  final analyzed = evaluate(
    result.exitCode,
    '${result.stdout}\n${result.stderr}',
    Directory.current.path,
  );
  stdout.writeln(
    'analyze: error=${analyzed.errors.length}, warning/info=${analyzed.total}',
  );
  if (analyzed.errors.isNotEmpty) {
    throw GateFailure('存在 ERROR（不允许进入基线）：\n${analyzed.errors.join('\n')}');
  }
  final baselineFile = File(baselinePath);
  final baseline = baselineFile.existsSync()
      ? parseBaseline(baselineFile.readAsStringSync())
      : <String, int>{};
  final added = increases(analyzed.counts, baseline);

  if (update) {
    if (added.isNotEmpty && !allowIncrease) {
      throw GateFailure(
        '拒绝写入：新基线相对现有基线有增加（--update 只允许收紧）：\n${added.join('\n')}\n'
        '确需放宽请修复问题；人工放宽须加 --allow-increase 并在 PR 中说明。',
      );
    }
    baselineFile.writeAsStringSync(formatBaseline(analyzed.counts));
    stdout.writeln(
      '已写入 $baselinePath（${analyzed.counts.length} 个键，${analyzed.total} 条）',
    );
    return;
  }

  final baselineTotal = baseline.values.fold<int>(0, (a, b) => a + b);
  if (added.isNotEmpty) {
    throw GateFailure(
      '相对基线新增了 analyze 问题（基线 $baselineTotal 条，当前 ${analyzed.total} 条）：\n'
      '${added.join('\n')}\n请修复；确属误报时在代码处用 // ignore: 并说明原因。',
    );
  }
  if (analyzed.total < baselineTotal) {
    stdout.writeln(
      '问题比基线少（${analyzed.total} < $baselineTotal）：请执行 dart run tool/analyze_gate.dart --update 收紧基线。',
    );
  }
  stdout.writeln(
    'analyze 门禁通过（当前 ${analyzed.total} 条，基线 $baselineTotal 条，无新增）。',
  );
}

void selfTest() {
  var n = 0;
  void expectFail(String name, void Function() body) {
    try {
      body();
    } on GateFailure {
      n++;
      return;
    }
    throw StateError('自测失败：$name 应当判定失败');
  }

  void check(String name, bool ok) {
    if (!ok) throw StateError('自测失败：$name');
    n++;
  }

  const root = '/repo';
  const warn =
      'WARNING|STATIC_WARNING|UNUSED_LOCAL_VARIABLE|/repo/lib/a.dart|1|18|1|unused';
  const info =
      'INFO|HINT|DEPRECATED_MEMBER_USE|/repo/lib/b.dart|3|5|4|deprecated';
  const err =
      'ERROR|COMPILE_TIME_ERROR|RETURN_OF_INVALID_TYPE|/repo/lib/c.dart|1|12|3|bad';

  check('无问题 → 0 条', evaluate(0, 'Running build hooks...\n', root).total == 0);
  final r = evaluate(2, '$info\n$warn\n', root);
  check(
    '解析 WARNING/INFO 与相对路径',
    r.counts['WARNING|UNUSED_LOCAL_VARIABLE|lib/a.dart'] == 1 &&
        r.counts['INFO|DEPRECATED_MEMBER_USE|lib/b.dart'] == 1,
  );
  check('ERROR 单独记录', evaluate(3, '$err\n', root).errors.length == 1);
  check(
    'UTF-8 workspace paths remain relative',
    evaluate(
          1,
          utf8.decode(
            utf8.encode(
              'INFO|HINT|DEPRECATED_MEMBER_USE|C:/工作区/应用/lib/b.dart|3|5|4|deprecated',
            ),
          ),
          'C:/工作区/应用',
        ).counts['INFO|DEPRECATED_MEMBER_USE|lib/b.dart'] ==
        1,
  );
  check(
    'Windows 转义路径使用仓库相对路径',
    evaluate(
          1,
          r'INFO|HINT|DEPRECATED_MEMBER_USE|D:\\repo\\lib\\b.dart|3|5|4|deprecated',
          r'D:\repo',
        ).counts['INFO|DEPRECATED_MEMBER_USE|lib/b.dart'] ==
        1,
  );
  expectFail('崩溃退出码 255', () => evaluate(255, 'Unhandled exception', root));
  expectFail(
    '用法错误退出码 64',
    () => evaluate(64, 'Directory or file doesn\'t exist', root),
  );
  expectFail('退出码 2 但没有任何诊断行（输出不可解析）', () => evaluate(2, 'garbage', root));
  expectFail('退出码 0 却有 WARNING（不一致）', () => evaluate(0, warn, root));
  expectFail(
    '未知严重级别',
    () => evaluate(1, 'FATAL|X|Y|/repo/a.dart|1|1|1|m', root),
  );
  check('增加检测：新键', increases({'k': 1}, {}).length == 1);
  check('增加检测：数量变多', increases({'k': 3}, {'k': 2}).length == 1);
  check('减少不算增加', increases({'k': 1}, {'k': 2, 'j': 1}).isEmpty);
  check('基线往返', parseBaseline(formatBaseline({'a|b|c': 2}))['a|b|c'] == 2);
  stdout.writeln('analyze_gate 自测通过（$n 项）。');
}
