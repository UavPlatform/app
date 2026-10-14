// 契约门禁测试（api_contract_test）：
//  1) vendored 规格 sha256 与 .sha256 / ApiPaths.generatedFromSha256 三方对账；
//  2) 本端调用的端点登记表逐条存在于 vendored 规格（method + path）；
//  3) lib/**（lib/api/generated 除外）不得残留与契约路径同名的后端路径字面量；
//  4) 生成契约模型可解析。
//
// 运行：cd app && flutter test test/api_contract_test.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uav_pilot_app/api/generated/openapi_models.dart';
import 'package:uav_pilot_app/api/generated/openapi_paths.dart';

// 与 tool/openapi_gen.dart 的 endpoints 登记表核对，新增调用点必须两边同时登记。
import '../tool/openapi_gen.dart' show endpoints;
import '../tool/sha256.dart';

/// 本端实际调用的后端端点（method, path）。
///
/// 35 条为既有调用点清单；第 36 条 POST /user/refresh 是 http_client.dart 的
/// token 刷新调用——契约里存在该路径，因此必须登记并走 ApiPaths.userRefresh，
/// 不能残留字面量。TASK-APP-005 追加 3 条：飞手任务详情 / 应征 / 确认订单。
/// TASK-APP-004 追加 1 条：用户选定飞手下单（select-rider）。
const List<List<String>> calledEndpoints = <List<String>>[
  <String>['get', '/task/init'],
  <String>['post', '/task/create'],
  <String>['get', '/task/list'],
  <String>['get', '/task/detail'],
  <String>['delete', '/task/delete'],
  <String>['post', '/task/confirm'],
  <String>['post', '/task/{taskNum}/select-rider'],
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
  <String>['get', '/rider/task/detail'],
  <String>['post', '/rider/apply'],
  <String>['post', '/rider/confirm-order'],
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
  <String>['get', '/order/stats'],
  <String>['get', '/order/sold'],
  <String>['get', '/order/pending-review'],
  <String>['post', '/pay/{orderNum}'],
  <String>['get', '/tasks/{taskNum}/attachments'],
  <String>['post', '/tasks/{taskNum}/attachments/upload-url'],
  <String>['post', '/tasks/{taskNum}/attachments/confirm-upload'],
  <String>['post', '/review/submit'],
  <String>['get', '/review/{orderNum}'],
  <String>['get', '/review/my'],
  <String>['get', '/rider/info'],
  <String>['patch', '/rider/info'],
];

/// GoRouter 页面路由与契约路径同名时的白名单。
///
/// /rider/register 是 App 内飞手注册页的导航路由（GoRoute path / context.push），
/// 不经过 HttpClient，因此不是后端调用点；除此之外任何与契约路径同名的 lib
/// 字符串字面量都视为漏网的后端调用点。
const Set<String> navigationRouteLiterals = <String>{'/rider/register'};

/// 契约路径（含 {param} 模板）集合。
Set<String> specPathSet = <String>{};

/// 扫描单份源码，返回与契约路径同名的字符串字面量（含行号）。
List<String> scanBackendPathLiterals(String source) {
  // 单引号/双引号字符串字面量（路径字面量均不含转义引号）。
  final RegExp literal = RegExp("'([^'\\\\]*)'|\"([^\"\\\\]*)\"");
  final List<String> found = <String>[];
  final List<String> lines = const LineSplitter().convert(source);
  for (int index = 0; index < lines.length; index++) {
    for (final RegExpMatch match in literal.allMatches(lines[index])) {
      final String value = match.group(1) ?? match.group(2) ?? '';
      if (value.isEmpty) {
        continue;
      }
      // 契约路径可能被写成带或不带前导 '/' 的形式，这里统一归一化后比对。
      final String normalized = value.startsWith('/') ? value : '/$value';
      if (specPathSet.contains(normalized) &&
          !navigationRouteLiterals.contains(normalized)) {
        found.add('line ${index + 1}: $value');
      }
    }
  }
  return found;
}

void main() {
  final Directory libDir = Directory('lib');
  final File specFile = File('openapi/drone-backend.openapi.json');
  final Map<String, dynamic> spec =
      jsonDecode(utf8.decode(specFile.readAsBytesSync()))
          as Map<String, dynamic>;
  final Map<String, dynamic> specPaths = spec['paths'] as Map<String, dynamic>;
  specPathSet = specPaths.keys.toSet();

  group('契约事实源对账（sha256）', () {
    test(
      'vendored 规格 sha256 == .sha256 记录 == ApiPaths.generatedFromSha256',
      () {
        final String computed = sha256File(
          'openapi/drone-backend.openapi.json',
        );
        final String recorded = File(
          'openapi/drone-backend.openapi.sha256',
        ).readAsStringSync().trim().split(RegExp(r'\s+')).first;
        expect(computed, recorded, reason: 'vendored 规格与 .sha256 记录不一致');
        expect(
          ApiPaths.generatedFromSha256,
          recorded,
          reason: '生成路径表的事实源版本与 vendored 规格不一致',
        );
      },
    );
  });

  group('调用端点登记表', () {
    test('每条登记端点都存在于 vendored 规格（method + path）', () {
      expect(calledEndpoints, hasLength(49));
      for (final List<String> endpoint in calledEndpoints) {
        final String method = endpoint[0].toLowerCase();
        final String path = endpoint[1];
        expect(
          specPaths.containsKey(path),
          isTrue,
          reason: 'vendored 规格缺少路径 $path',
        );
        final Map<String, dynamic> item =
            specPaths[path] as Map<String, dynamic>;
        expect(
          item.containsKey(method),
          isTrue,
          reason: 'vendored 规格缺少方法 ${method.toUpperCase()} $path',
        );
      }
    });

    test('登记表与生成器 endpoints 一致（新增调用点必须登记）', () {
      String key(List<String> endpoint) =>
          '${endpoint[0].toLowerCase()} ${endpoint[1]}';
      expect(calledEndpoints.map(key).toSet(), endpoints.map(key).toSet());
    });

    test(
      '登记表无重复（含交易统计 /order/stats、/order/sold、/order/pending-review 等共 49 条）',
      () {
        String key(List<String> endpoint) =>
            '${endpoint[0].toLowerCase()} ${endpoint[1]}';
        expect(calledEndpoints.map(key).toSet(), hasLength(49));
      },
    );
  });

  group('后端路径字面量零残留', () {
    test('lib/**（lib/api/generated 除外）无与契约路径同名的字面量', () {
      final List<String> violations = <String>[];
      for (final FileSystemEntity entity in libDir.listSync(recursive: true)) {
        if (entity is! File) {
          continue;
        }
        final String path = entity.path.replaceAll('\\', '/');
        if (!path.endsWith('.dart') || path.contains('/api/generated/')) {
          continue;
        }
        for (final String found in scanBackendPathLiterals(
          entity.readAsStringSync(),
        )) {
          violations.add('$path $found');
        }
      }
      expect(
        violations,
        isEmpty,
        reason: '发现残留的后端路径字面量：\n${violations.join('\n')}',
      );
    });

    test('扫描器能识别带/不带前导斜杠的契约路径', () {
      expect(
        scanBackendPathLiterals("dio.get('/task/detail');"),
        isNotEmpty,
        reason: '带前导斜杠的残留必须被识别',
      );
      expect(
        scanBackendPathLiterals('final path = "task/detail";'),
        isNotEmpty,
        reason: '不带前导斜杠的残留必须被识别',
      );
      expect(
        scanBackendPathLiterals("context.push('/rider/register');"),
        isEmpty,
        reason: '导航路由白名单不应误报',
      );
    });
  });

  group('生成契约模型', () {
    test('ApiTaskVo 按契约字段解析', () {
      final ApiTaskVo c = ApiTaskVo.fromJson(<String, dynamic>{'taskNum': 'X'});
      expect(c.taskNum, 'X');
      expect(c.id, isNull);
    });

    test('ApiTaskVo 嵌套 WaypointVo 解析', () {
      final ApiTaskVo c = ApiTaskVo.fromJson(<String, dynamic>{
        'taskNum': 'X',
        'waypoints': <dynamic>[
          <String, dynamic>{
            'id': 1,
            'orderIndex': 0,
            'longitude': 1.5,
            'latitude': 2.5,
          },
        ],
      });
      expect(c.waypoints, hasLength(1));
      expect(c.waypoints!.single.latitude, 2.5);
    });

    test('ApiResult 信封解析业务数据', () {
      final ApiResult<ApiSessionVO> envelope = ApiResult<ApiSessionVO>.fromJson(
        <String, dynamic>{
          'success': true,
          'code': 200,
          'data': <String, dynamic>{
            'id': 3,
            'name': '会话',
            'type': 0,
            'userIds': <int>[1],
          },
        },
        ApiSessionVO.fromJson,
      );
      expect(envelope.success, isTrue);
      expect(envelope.code, 200);
      expect(envelope.data!.name, '会话');
    });
  });
}
