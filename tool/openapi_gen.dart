// 契约代码生成器（人工维护的工具）：把 vendored OpenAPI 规格翻译成 Dart 契约模型与路径表。
//
// 用法：
//   dart run tool/openapi_gen.dart           # 生成 lib/api/generated/*.dart
//   dart run tool/openapi_gen.dart --check   # 只校验生成物与规格是否同步（漂移则退出码 1）
//
// 事实源：openapi/drone-backend.openapi.json（backend 仓 spec/openapi/ 导出，sha256 对账）。
// 生成物必须提交入库且禁止手改；后端契约变更后重跑本脚本并评审 diff。
//
// 说明：本文件刻意使用字符串拼接而不是插值——拼接能保证「生成器源码里不出现插值语法」，
// 从而在生成「含插值的 Dart 代码」时不会误触发插值。
// ignore_for_file: prefer_interpolation_to_compose_strings
import 'dart:convert';
import 'dart:io';

import 'sha256.dart';

const String specPath = 'openapi/drone-backend.openapi.json';
const String modelsPath = 'lib/api/generated/openapi_models.dart';
const String pathsPath = 'lib/api/generated/openapi_paths.dart';

/// 本端调用的端点清单（消费清单，人工维护）。
/// 新增调用点必须在此登记；门禁测试会核对「登记表 ↔ 代码」双向一致。
const List<List<String>> endpoints = <List<String>>[
  <String>['get', '/task/init'],
  <String>['post', '/task/create'],
  <String>['get', '/task/list'],
  <String>['get', '/task/detail'],
  <String>['delete', '/task/delete'],
  <String>['post', '/task/confirm'],
  <String>['get', '/task/{taskNum}/applications'],
  <String>['get', '/task/{taskNum}/chat-sessions'],
  <String>['get', '/chat/session/list'],
  <String>['post', '/chat/session/create'],
  <String>['get', '/chat/Message/messages/{sessionId}'],
  <String>['post', '/chat/Message/send'],
  <String>['get', '/chat/Message/unread/count'],
  <String>['post', '/chat/Message/read'],
  <String>['get', '/rider/square'],
  <String>['get', '/rider/recommended'],
  <String>['get', '/rider/my-tasks'],
  <String>['get', '/rider/my-tasks/history'],
  <String>['post', '/rider/cancel'],
  <String>['post', '/rider/complete'],
  <String>['post', '/rider/register'],
  <String>['get', '/rider/stats'],
  <String>['get', '/rider/drone/list'],
  <String>['post', '/rider/drone/bind'],
  <String>['delete', '/rider/drone/unbind'],
  <String>['get', '/api/aircraft-models'],
  <String>['post', '/user/login'],
  <String>['post', '/user/register'],
  <String>['post', '/user/refresh'],
  <String>['post', '/live/get'],
  <String>['post', '/live/leave'],
  <String>['get', '/order/list'],
  <String>['get', '/order/detail'],
  <String>['post', '/pay/{orderNum}'],
  <String>['get', '/tasks/{taskNum}/attachments'],
  <String>['post', '/tasks/{taskNum}/attachments/upload-url'],
];

void main(List<String> args) {
  final bool check = args.contains('--check');
  final File specFile = File(specPath);
  if (!specFile.existsSync()) {
    stderr.writeln('[openapi] 缺少 vendored 规格 ' + specPath);
    stderr.writeln('[openapi] 先运行：dart run tool/openapi_sync.dart');
    exit(1);
  }
  final List<int> bytes = specFile.readAsBytesSync();
  final String sha = sha256Hex(bytes);
  final Map<String, dynamic> spec = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  final Map<String, dynamic> paths = spec['paths'] as Map<String, dynamic>;
  final Map<String, dynamic> schemas =
      (spec['components'] as Map<String, dynamic>)['schemas'] as Map<String, dynamic>;

  final Generator generator = Generator(paths: paths, schemas: schemas, sha: sha);
  final Map<String, String> outputs = <String, String>{};
  try {
    outputs[modelsPath] = generator.buildModels();
    outputs[pathsPath] = generator.buildPaths();
  } on StateError catch (error) {
    stderr.writeln('[openapi] FAIL：' + error.message);
    exit(1);
  }

  int drift = 0;
  outputs.forEach((String path, String content) {
    final File file = File(path);
    final String existing = file.existsSync() ? file.readAsStringSync() : '';
    if (existing == content) {
      return;
    }
    drift++;
    if (check) {
      stderr.writeln('[openapi] 生成物与规格不同步：' + path);
    } else {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(content);
      stdout.writeln('[openapi] 已写入 ' + path + '（' + content.length.toString() + ' 字节）');
    }
  });

  if (check) {
    if (drift > 0) {
      stderr.writeln('[openapi] FAIL：' + drift.toString() + ' 个生成物过期，请运行 dart run tool/openapi_gen.dart');
      exit(1);
    }
    stdout.writeln('[openapi] OK：生成物与规格同步（sha256=' + sha +
        '，端点=' + endpoints.length.toString() + '）');
    return;
  }
  stdout.writeln('[openapi] sha256=' + sha +
      ' 端点=' + endpoints.length.toString() +
      ' 变更文件=' + drift.toString());
}

String? refName(dynamic schema) {
  if (schema is Map && schema[r'$ref'] is String) {
    return (schema[r'$ref'] as String).split('/').last;
  }
  return null;
}

class Generator {
  Generator({required this.paths, required this.schemas, required this.sha});

  final Map<String, dynamic> paths;
  final Map<String, dynamic> schemas;
  final String sha;

  final Set<String> needed = <String>{};

  bool isEnvelope(String name) => name.startsWith('Result');

  Map<String, dynamic> operation(String path, String method) {
    final dynamic item = paths[path];
    if (item is! Map) {
      throw StateError('契约里没有路径 ' + path + '（本端调用点与契约不一致）');
    }
    final dynamic op = item[method];
    if (op is! Map) {
      throw StateError('契约里 ' + path + ' 没有 ' + method + ' 方法（本端调用点与契约不一致）');
    }
    return op as Map<String, dynamic>;
  }

  Map<String, dynamic> resolve(dynamic schema) {
    final String? ref = refName(schema);
    if (ref == null) {
      return schema as Map<String, dynamic>;
    }
    final dynamic target = schemas[ref];
    if (target is! Map) {
      throw StateError('契约里没有 schema：' + ref);
    }
    return target as Map<String, dynamic>;
  }

  void visit(dynamic schema) {
    if (schema is! Map) {
      return;
    }
    final String? ref = refName(schema);
    if (ref != null) {
      if (needed.add(ref)) {
        visit(schemas[ref]);
      }
      return;
    }
    final dynamic props = schema['properties'];
    if (props is Map) {
      for (final dynamic value in props.values) {
        visit(value);
      }
    }
    visit(schema['items']);
    visit(schema['additionalProperties']);
    for (final String key in <String>['allOf', 'oneOf', 'anyOf']) {
      final dynamic list = schema[key];
      if (list is List) {
        for (final dynamic part in list) {
          visit(part);
        }
      }
    }
  }

  dynamic jsonContent(dynamic content) {
    if (content is Map) {
      final dynamic json = content['application/json'];
      if (json is Map) {
        return json['schema'];
      }
      for (final dynamic value in content.values) {
        if (value is Map && value['schema'] != null) {
          return value['schema'];
        }
      }
    }
    return null;
  }

  void collect() {
    for (final List<String> endpoint in endpoints) {
      final Map<String, dynamic> op = operation(endpoint[1], endpoint[0]);
      final dynamic params = op['parameters'];
      if (params is List) {
        for (final dynamic param in params) {
          visit((param as Map<String, dynamic>)['schema']);
        }
      }
      final dynamic body = op['requestBody'];
      if (body is Map) {
        visit(jsonContent(body['content']));
      }
      final dynamic responses = op['responses'];
      if (responses is Map) {
        for (final dynamic response in responses.values) {
          if (response is Map) {
            visit(jsonContent(response['content']));
          }
        }
      }
    }
  }

  /// allOf 拍平：契约里 Java 继承关系会展开成 allOf，Dart 侧合并成一个类。
  Map<String, dynamic> merged(String name) {
    final Map<String, dynamic> root =
        resolve(<String, dynamic>{r'$ref': '#/components/schemas/' + name});
    final Map<String, dynamic> properties = <String, dynamic>{};
    final Set<String> required = <String>{};
    void absorb(Map<String, dynamic> part) {
      final dynamic props = part['properties'];
      if (props is Map) {
        properties.addAll(props.cast<String, dynamic>());
      }
      final dynamic req = part['required'];
      if (req is List) {
        required.addAll(req.cast<String>());
      }
    }
    final dynamic allOf = root['allOf'];
    if (allOf is List) {
      for (final dynamic part in allOf) {
        absorb(resolve(part));
      }
    }
    absorb(root);
    return <String, dynamic>{'properties': properties, 'required': required.toList()};
  }

  String typeOf(dynamic schema, bool nullable) {
    final String suffix = nullable ? '?' : '';
    final String? ref = refName(schema);
    if (ref != null) {
      if (isEnvelope(ref)) {
        return 'ApiResult<dynamic>' + suffix;
      }
      return 'Api' + ref + suffix;
    }
    final dynamic type = schema is Map ? schema['type'] : null;
    if (type == 'array') {
      return 'List<' + typeOf(schema['items'], false) + '>' + suffix;
    }
    if (type == 'integer') {
      return 'int' + suffix;
    }
    if (type == 'number') {
      return 'double' + suffix;
    }
    if (type == 'boolean') {
      return 'bool' + suffix;
    }
    if (type == 'string') {
      return 'String' + suffix;
    }
    if (type == 'object' || (schema is Map && schema['properties'] is Map)) {
      return 'Map<String, dynamic>' + suffix;
    }
    return 'dynamic';
  }

  String itemReader(dynamic item) {
    final String? ref = refName(item);
    if (ref != null) {
      return 'Api' + ref + '.fromJson(e as Map<String, dynamic>)';
    }
    final dynamic type = item is Map ? item['type'] : null;
    if (type == 'integer') {
      return '(e as num).toInt()';
    }
    if (type == 'number') {
      return '(e as num).toDouble()';
    }
    if (type == 'boolean') {
      return 'e as bool';
    }
    if (type == 'string') {
      return 'e as String';
    }
    return 'e';
  }

  String readExpr(dynamic schema, String key, bool nullable) {
    final String access = "json['" + key + "']";
    final String? ref = refName(schema);
    if (ref != null) {
      if (isEnvelope(ref)) {
        return access;
      }
      final String call = 'Api' + ref + '.fromJson(' + access + ' as Map<String, dynamic>)';
      if (nullable) {
        return '(' + access + ' == null ? null : ' + call + ')';
      }
      return call;
    }
    final dynamic type = schema is Map ? schema['type'] : null;
    if (type == 'integer') {
      return nullable
          ? '(' + access + ' as num?)?.toInt()'
          : '((' + access + ' as num?)?.toInt() ?? 0)';
    }
    if (type == 'number') {
      return nullable
          ? '(' + access + ' as num?)?.toDouble()'
          : '((' + access + ' as num?)?.toDouble() ?? 0)';
    }
    if (type == 'boolean') {
      return nullable ? access + ' as bool?' : '((' + access + ' as bool?) ?? false)';
    }
    if (type == 'string') {
      return nullable ? access + ' as String?' : '((' + access + ' as String?) ?? "")';
    }
    if (type == 'array') {
      final String item = typeOf(schema['items'], false);
      if (item.startsWith('Map') || item == 'dynamic') {
        return access + ' as List<dynamic>?';
      }
      final String mapped = '(' + access + ' as List<dynamic>?)?.map((dynamic e) => ' +
          itemReader(schema['items']) + ').toList()';
      return nullable ? mapped : '(' + mapped + ' ?? <' + item + '>[])';
    }
    if (type == 'object') {
      return access + ' as Map<String, dynamic>?';
    }
    return access;
  }

  String writeExpr(dynamic schema, String field) {
    final String? ref = refName(schema);
    if (ref != null && !isEnvelope(ref)) {
      return field + '?.toJson()';
    }
    return field;
  }

  String header(String what) {
    return '// GENERATED — DO NOT EDIT.\n'
        '// ' + what + '\n'
        '// 生成命令：dart run tool/openapi_gen.dart\n'
        '// 事实源：openapi/drone-backend.openapi.json (sha256: ' + sha + ')\n'
        '// ignore_for_file: type=lint, unused_element, unused_field, prefer_final_fields';
  }

  String buildModels() {
    collect();
    final List<String> names =
        needed.where((String name) => !isEnvelope(name)).toList()..sort();
    final StringBuffer out = StringBuffer();
    out.writeln(header('契约模型：后端 components.schemas 的 Dart 映射。'));
    out.writeln();
    out.writeln('/// 后端统一返回体 Result<T> 的契约映射。');
    out.writeln('///');
    out.writeln('/// 可空性取自契约的 required 列表：springdoc 不把基本类型标为 required，');
    out.writeln('/// 因此除显式 required 外一律可空（业务侧的默认值收敛在各自模型适配器里）。');
    out.writeln('class ApiResult<T> {');
    out.writeln('  const ApiResult({this.success, this.code, this.errorCode, this.message, this.data});');
    out.writeln();
    out.writeln('  final bool? success;');
    out.writeln('  final int? code;');
    out.writeln('  final String? errorCode;');
    out.writeln('  final String? message;');
    out.writeln('  final T? data;');
    out.writeln();
    out.writeln('  factory ApiResult.fromJson(');
    out.writeln('    Map<String, dynamic> json,');
    out.writeln('    T Function(Map<String, dynamic> json) parseData,');
    out.writeln('  ) {');
    out.writeln('    final dynamic raw = json["data"];');
    out.writeln('    return ApiResult<T>(');
    out.writeln('      success: json["success"] as bool?,');
    out.writeln('      code: (json["code"] as num?)?.toInt(),');
    out.writeln('      errorCode: json["errorCode"] as String?,');
    out.writeln('      message: json["message"] as String?,');
    out.writeln('      data: raw == null ? null : parseData(raw as Map<String, dynamic>),');
    out.writeln('    );');
    out.writeln('  }');
    out.writeln('}');

    for (final String name in names) {
      final Map<String, dynamic> shape = merged(name);
      final Map<String, dynamic> props = shape['properties'] as Map<String, dynamic>;
      final Set<String> required = (shape['required'] as List<String>).toSet();
      out.writeln();
      out.writeln('/// 契约 components.schemas.' + name);
      out.writeln('class Api' + name + ' {');
      if (props.isEmpty) {
        out.writeln('  const Api' + name + '();');
        out.writeln();
        out.writeln('  factory Api' + name + '.fromJson(Map<String, dynamic> json) => const Api' + name + '();');
        out.writeln('  Map<String, dynamic> toJson() => <String, dynamic>{};');
        out.writeln('}');
        continue;
      }
      final List<String> ctor = <String>[];
      final List<String> reads = <String>[];
      final List<String> writes = <String>[];
      props.forEach((String key, dynamic schema) {
        final bool isRequired = required.contains(key);
        final bool nullable = !isRequired;
        out.writeln('  final ' + typeOf(schema, nullable) + ' ' + key + ';');
        ctor.add(isRequired ? 'required this.' + key : 'this.' + key);
        reads.add('    ' + key + ': ' + readExpr(schema, key, nullable) + ',');
        if (isRequired) {
          writes.add("    json['" + key + "'] = " + writeExpr(schema, key) + ';');
        } else {
          writes.add('    if (' + key + ' != null) {');
          writes.add("      json['" + key + "'] = " + writeExpr(schema, key) + ';');
          writes.add('    }');
        }
      });
      out.writeln();
      out.writeln('  const Api' + name + '({' + ctor.join(', ') + '});');
      out.writeln();
      out.writeln('  factory Api' + name + '.fromJson(Map<String, dynamic> json) => Api' + name + '(');
      for (final String line in reads) {
        out.writeln(line);
      }
      out.writeln('  );');
      out.writeln();
      out.writeln('  Map<String, dynamic> toJson() {');
      out.writeln('    final Map<String, dynamic> json = <String, dynamic>{};');
      for (final String line in writes) {
        out.writeln(line);
      }
      out.writeln('    return json;');
      out.writeln('  }');
      out.writeln('}');
    }
    return out.toString();
  }

  String camel(String raw) {
    final List<String> parts = raw
        .split(RegExp('[^A-Za-z0-9]+'))
        .where((String part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'root';
    }
    final StringBuffer buffer = StringBuffer(parts.first.toLowerCase());
    for (final String part in parts.skip(1)) {
      buffer.write(part.substring(0, 1).toUpperCase() + part.substring(1));
    }
    return buffer.toString();
  }

  String nameOf(String path) =>
      camel(path.replaceAll(RegExp('[{][^}]*[}]'), '/').replaceAll(RegExp('/+'), '/'));

  String buildPaths() {
    final StringBuffer out = StringBuffer();
    out.writeln(header('契约路径表：调用点只允许通过本表拼 URL。'));
    out.writeln();
    out.writeln('/// 后端端点路径与查询参数的契约映射：路径写错、必填查询参数漏传都会在编译期暴露。');
    out.writeln('class ApiPaths {');
    out.writeln('  ApiPaths._();');
    out.writeln();
    out.writeln("  static const String generatedFromSha256 = '" + sha + "';");
    final Set<String> used = <String>{};
    for (final List<String> endpoint in endpoints) {
      final String method = endpoint[0];
      final String path = endpoint[1];
      final Map<String, dynamic> op = operation(path, method);
      final String base = nameOf(path);
      String name = base;
      if (!used.add(name)) {
        name = method.toLowerCase() + base.substring(0, 1).toUpperCase() + base.substring(1);
        used.add(name);
      }
      out.writeln();
      out.writeln('  /// ' + method.toUpperCase() + ' ' + path);
      out.writeln("  static const String " + name + " = '" + path + "';");

      final List<Map<String, dynamic>> pathParams = <Map<String, dynamic>>[];
      final List<Map<String, dynamic>> queryParams = <Map<String, dynamic>>[];
      final dynamic params = op['parameters'];
      if (params is List) {
        for (final dynamic raw in params) {
          final Map<String, dynamic> param = raw as Map<String, dynamic>;
          if (param['in'] == 'path') {
            pathParams.add(param);
          } else if (param['in'] == 'query') {
            queryParams.add(param);
          }
        }
      }

      if (pathParams.isNotEmpty) {
        final List<String> args = <String>[];
        for (final Map<String, dynamic> param in pathParams) {
          args.add(typeOf(param['schema'], false) + ' ' + (param['name'] as String));
        }
        final List<String> parts = <String>[];
        final RegExp re = RegExp('[{]([^}]+)[}]');
        int last = 0;
        for (final RegExpMatch match in re.allMatches(path)) {
          final String segment = path.substring(last, match.start);
          if (segment.isNotEmpty) {
            parts.add("'" + segment + "'");
          }
          final String paramName = match.group(1)!;
          Map<String, dynamic>? declared;
          for (final Map<String, dynamic> param in pathParams) {
            if (param['name'] == paramName) {
              declared = param;
            }
          }
          if (declared == null) {
            throw StateError('路径 ' + path + ' 的参数 ' + paramName + ' 未在契约 parameters 中声明');
          }
          final String type = typeOf(declared['schema'], false);
          parts.add(type == 'String'
              ? 'Uri.encodeComponent(' + paramName + ')'
              : paramName + '.toString()');
          last = match.end;
        }
        final String tail = path.substring(last);
        if (tail.isNotEmpty) {
          parts.add("'" + tail + "'");
        }
        out.writeln('  static String ' + name + 'Path(' + args.join(', ') + ') => ' +
            parts.join(' + ') + ';');
      }

      if (queryParams.isNotEmpty) {
        final List<String> args = <String>[];
        final List<String> entries = <String>[];
        for (final Map<String, dynamic> param in queryParams) {
          final bool isRequired = param['required'] == true;
          final String paramName = param['name'] as String;
          args.add((isRequired ? 'required ' : '') +
              typeOf(param['schema'], !isRequired) +
              ' ' +
              paramName);
          entries.add("'" + paramName + "': " + paramName);
        }
        out.writeln('  static Map<String, dynamic> ' + name + 'Query({' + args.join(', ') + '}) =>');
        out.writeln('      <String, dynamic>{' + entries.join(', ') + '};');
      }
    }
    out.writeln('}');
    return out.toString();
  }
}
