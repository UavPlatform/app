// flutter/dart analyze 基线门禁（CI 与本地共用）。
//
//   dart run tool/analyze_gate.dart            # 校验：有新增问题则退出码 1
//   dart run tool/analyze_gate.dart --update   # 按当前结果重写基线（问题减少后执行并提交）
//
// 规则：
//   - ERROR：一律失败，不进基线。
//   - WARNING / INFO：与 tool/analyze_baseline.txt 比较。按「严重级别|诊断码|文件」计数（不含行号，
//     避免无关改动导致行号漂移误报）；任一键的数量超过基线即失败。
//   - 问题比基线少：通过，并提示执行 --update 收紧基线。
// 基线来自 main 既有问题（引入门禁时 1 WARNING + 21 INFO），目标是只减不增。
import 'dart:io';

const baselinePath = 'tool/analyze_baseline.txt';

Future<void> main(List<String> args) async {
  final update = args.contains('--update');
  final result = await Process.run('dart', ['analyze', '--format=machine'], runInShell: true);
  final root = Directory.current.path;
  final current = <String, int>{};
  var errors = 0;
  final errorLines = <String>[];
  // machine 格式：SEVERITY|TYPE|CODE|FILE|LINE|COLUMN|LENGTH|MESSAGE（输出在 stderr 或 stdout，视版本而定）
  final lines = '${result.stdout}\n${result.stderr}'.split('\n');
  for (final line in lines) {
    final parts = line.split('|');
    if (parts.length < 8) continue;
    final severity = parts[0].trim();
    if (!const {'ERROR', 'WARNING', 'INFO'}.contains(severity)) continue;
    var file = parts[3];
    if (file.startsWith(root)) file = file.substring(root.length + 1);
    file = file.replaceAll('\\', '/');
    if (severity == 'ERROR') {
      errors++;
      errorLines.add('$file:${parts[4]} ${parts[2]} ${parts.sublist(7).join('|')}');
      continue;
    }
    final key = '$severity|${parts[2]}|$file';
    current[key] = (current[key] ?? 0) + 1;
  }
  final total = current.values.fold<int>(0, (a, b) => a + b);
  stdout.writeln('analyze: error=$errors, warning/info=$total');
  if (errors > 0) {
    stderr.writeln('存在 ERROR（不允许进入基线）：');
    errorLines.forEach(stderr.writeln);
    exit(1);
  }

  if (update) {
    final keys = current.keys.toList()..sort();
    final buf = StringBuffer()
      ..writeln('# analyze 基线：严重级别|诊断码|文件<TAB>数量。由 dart run tool/analyze_gate.dart --update 生成，只减不增。');
    for (final k in keys) {
      buf.writeln('$k\t${current[k]}');
    }
    File(baselinePath).writeAsStringSync(buf.toString());
    stdout.writeln('已写入 $baselinePath（${keys.length} 个键，$total 条）');
    return;
  }

  final baseline = <String, int>{};
  for (final line in File(baselinePath).readAsLinesSync()) {
    if (line.trim().isEmpty || line.startsWith('#')) continue;
    final tab = line.lastIndexOf('\t');
    baseline[line.substring(0, tab)] = int.parse(line.substring(tab + 1));
  }
  final added = <String>[];
  for (final e in current.entries) {
    final allowed = baseline[e.key] ?? 0;
    if (e.value > allowed) added.add('${e.key}: ${e.value}（基线 $allowed）');
  }
  final baselineTotal = baseline.values.fold<int>(0, (a, b) => a + b);
  if (added.isNotEmpty) {
    stderr.writeln('相对基线新增了 analyze 问题（基线 $baselineTotal 条，当前 $total 条）：');
    added.forEach(stderr.writeln);
    stderr.writeln('请修复；确属误报时在代码处用 // ignore: 并说明原因。');
    exit(1);
  }
  if (total < baselineTotal) {
    stdout.writeln('问题比基线少（$total < $baselineTotal）：请执行 dart run tool/analyze_gate.dart --update 收紧基线。');
  }
  stdout.writeln('analyze 门禁通过（当前 $total 条，基线 $baselineTotal 条，无新增）。');
}
