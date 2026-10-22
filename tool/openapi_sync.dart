// 把 backend 仓导出的 OpenAPI 规格 vendor 到本仓（消费侧事实源副本）。
//
// 用法：dart run tool/openapi_sync.dart
//   OPENAPI_SOURCE 环境变量可覆盖来源路径（默认 ../backend/spec/openapi/drone-backend.openapi.json）。
//
// 注意：正常情况下由 .github/workflows/contract-sync.yml 自动同步，无需手动执行。
// 手动执行仅用于紧急情况或本地开发调试。
// ignore_for_file: prefer_interpolation_to_compose_strings
import 'dart:convert';
import 'dart:io';

import 'sha256.dart';

const String defaultSource = '../backend/spec/openapi/drone-backend.openapi.json';
const String target = 'openapi/drone-backend.openapi.json';
const String shaTarget = 'openapi/drone-backend.openapi.sha256';

void main() {
  final String source = Platform.environment['OPENAPI_SOURCE'] ?? defaultSource;
  final File sourceFile = File(source);
  if (!sourceFile.existsSync()) {
    stderr.writeln('[openapi] 找不到来源规格：' + source);
    exit(1);
  }
  final List<int> bytes = sourceFile.readAsBytesSync();
  final String sha = sha256Hex(bytes);
  final Map<String, dynamic> spec = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  final Map<String, dynamic> paths = spec['paths'] as Map<String, dynamic>;
  int operations = 0;
  for (final dynamic item in paths.values) {
    operations += (item as Map<String, dynamic>)
        .keys
        .where((String key) => key != 'parameters')
        .length;
  }

  File(target).writeAsBytesSync(bytes);
  File(shaTarget).writeAsStringSync(sha + '  drone-backend.openapi.json\n');

  stdout.writeln('[openapi] vendor 完成');
  stdout.writeln('          source  = ' + source);
  stdout.writeln('          spec    = ' + target);
  stdout.writeln('          bytes   = ' + bytes.length.toString() +
      '  operations = ' + operations.toString());
  stdout.writeln('          sha256  = ' + sha);
  stdout.writeln('[openapi] 下一步：dart run tool/openapi_gen.dart');
}
