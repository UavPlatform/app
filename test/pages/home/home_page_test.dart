// 首页吊运发单（REQ-APP-002 / ADR-0003）widget 测试：
//  1. 表单校验：类别必选、重量必填且为正数、终点必选；
//  2. 发布仅 TRANSPORT：提交体携带货物字段与起终点航点、不含价格字段、不调用支付接口；
//  3. 本人已发任务卡片：进行中展示、完成态隐藏；
//  4. 首页收敛：无服务四宫格、热门飞手、任务广场。

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/generated/openapi_models.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/pages/home/home_page.dart';
import 'package:uav_pilot_app/pages/home/map_picker_page.dart';
import 'package:uav_pilot_app/providers/auth_provider.dart';
import 'package:uav_pilot_app/services/token_storage.dart';

import '../../test_support.dart';

const MethodChannel _locationChannel = MethodChannel('com.fuwaki.app/location');

/// 首页桩：/task/init 成功（供定位链路），/task/list 返回给定任务，
/// /task/create 由 onCreate 自定义（默认不允许创建）。
StubAdapter homeAdapter({
  bool amapReady = true,
  List<Map<String, dynamic>> tasks = const [],
  Future<ResponseBody> Function(RequestOptions options)? onCreate,
}) {
  return StubAdapter((options) async {
    final path = options.uri.path;
    if (path == '/task/init') {
      if (!amapReady) {
        return jsonResponse(200, {'success': false, 'message': 'stub'});
      }
      return jsonResponse(200, {
        'success': true,
        'code': 200,
        'data': {'key': 'test-key', 'securityKey': 'test-security'},
      });
    }
    if (path == '/task/list') {
      return jsonResponse(200, {
        'success': true,
        'code': 200,
        'data': {
          'tasks': tasks,
          'currentPage': 0,
          'totalPages': 1,
          'totalElements': tasks.length,
        },
      });
    }
    if (path == '/task/create') {
      if (onCreate != null) return await onCreate(options);
      return jsonResponse(200, {'success': false, 'message': 'unexpected create'});
    }
    return jsonResponse(200, {'success': false, 'message': 'stub'});
  });
}

/// 以真实路由泵入首页（/home、/map/pick、订单详情占位）。
Future<void> pumpHome(WidgetTester tester, StubAdapter adapter) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({
    'jwt_token': makeJwt(userId: 7),
    'server_url': 'http://stub.local:8081',
  });
  final prefs = await SharedPreferences.getInstance();
  final client = HttpClient(TokenStorage(prefs), adapter: adapter);

  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (_, _) => const HomePage()),
      GoRoute(path: '/map/pick', builder: (_, _) => const MapPickerPage()),
      GoRoute(
        path: '/order/:taskNum',
        builder: (_, _) => const Scaffold(body: Text('order-detail')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        httpClientProvider.overrideWithValue(client),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

/// 点击首页地图非中心位置（避开起点标记与提示角标）设置卸货点。
Future<void> tapHomeMap(WidgetTester tester) async {
  final center = tester.getCenter(find.byType(FlutterMap));
  await tester.tapAt(center + const Offset(60, -30));
  await tester.pump(const Duration(milliseconds: 100));
}

/// SnackBar 自带 4s 展示定时器，断言后需清干净，避免用例收尾报 pending timer。
Future<void> drainSnackBars(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_locationChannel, (call) async {
      if (call.method == 'getLocation') {
        return <String, Object>{'city': '长沙市', 'latitude': 27.9, 'longitude': 112.9};
      }
      return null; // setApiKey 等无返回值方法
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_locationChannel, null);
  });

  testWidgets('发布校验：未选货物类别', (tester) async {
    final adapter = homeAdapter();
    await pumpHome(tester, adapter);

    await tester.tap(find.widgetWithText(ElevatedButton, '发布吊运需求'));
    await tester.pumpAndSettle();

    expect(find.text('请选择货物类别'), findsOneWidget);
    expect(adapter.requests.where((r) => r.uri.path == '/task/create'), isEmpty);

    await drainSnackBars(tester);
  });

  testWidgets('发布校验：重量必填且为正数', (tester) async {
    final adapter = homeAdapter();
    await pumpHome(tester, adapter);

    await tester.tap(find.widgetWithText(ChoiceChip, '建材'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, '发布吊运需求'));
    await tester.pumpAndSettle();
    expect(find.text('请输入货物重量'), findsOneWidget);
    await drainSnackBars(tester);

    await tester.enterText(
        find.byKey(const ValueKey('home-cargo-weight-field')), '0');
    await tester.tap(find.widgetWithText(ElevatedButton, '发布吊运需求'));
    await tester.pumpAndSettle();
    expect(find.text('货物重量必须为正数'), findsOneWidget);
    await drainSnackBars(tester);

    // 多个小数点无法解析 → 格式错误提示
    await tester.enterText(
        find.byKey(const ValueKey('home-cargo-weight-field')), '1.2.3');
    await tester.tap(find.widgetWithText(ElevatedButton, '发布吊运需求'));
    await tester.pumpAndSettle();
    expect(find.text('请输入正确的货物重量'), findsOneWidget);
    expect(adapter.requests.where((r) => r.uri.path == '/task/create'), isEmpty);

    await drainSnackBars(tester);
  });

  testWidgets('发布校验：终点必选', (tester) async {
    final adapter = homeAdapter();
    await pumpHome(tester, adapter);

    await tester.tap(find.widgetWithText(ChoiceChip, '建材'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('home-cargo-weight-field')), '12.5');

    await tester.tap(find.widgetWithText(ElevatedButton, '发布吊运需求'));
    await tester.pumpAndSettle();

    expect(find.text('请选择卸货点'), findsOneWidget);
    expect(adapter.requests.where((r) => r.uri.path == '/task/create'), isEmpty);

    await drainSnackBars(tester);
  });

  testWidgets('发布成功：仅 TRANSPORT、携带货物字段与起终点、不触发支付', (tester) async {
    Map<String, dynamic>? createBody;
    final adapter = homeAdapter(
      onCreate: (options) async {
        createBody = Map<String, dynamic>.from(options.data as Map);
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': {
            'id': 1,
            'taskNum': 'T-NEW',
            'taskName': '建材吊运',
            'userId': 7,
            'taskType': 'TRANSPORT',
            'taskStatus': 'IDLE',
          },
        });
      },
    );
    await pumpHome(tester, adapter);

    // 起吊点 = 当前定位（定位链路在 pumpHome 内已完成）
    expect(find.text('27.90000, 112.90000'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, '建材'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('home-cargo-weight-field')), '12.5');
    await tester.enterText(
        find.byKey(const ValueKey('home-cargo-volume-field')), '2.5');
    await tester.pump();

    // 吊运说明为可折叠面板：展开后填写
    await tester.tap(find.text('吊运说明'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('home-cargo-description-field')),
        '吊点在山顶基站');
    await tester.pump();

    // 地图点选卸货点
    await tapHomeMap(tester);
    expect(find.text('已选卸货点，点击地图可更改'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, '发布吊运需求'));
    await tester.pumpAndSettle();

    expect(find.text('发布成功，等待飞手应征'), findsOneWidget);
    expect(createBody, isNotNull);
    final body = createBody!;
    expect(body['type'], 'TRANSPORT');
    expect(body['taskName'], '建材吊运');
    expect(body['cargoCategory'], 'CONSTRUCTION');
    expect(body['cargoWeightKg'], 12.5);
    expect(body.containsKey('reward'), isFalse, reason: 'ADR-0003：客户端不得提交价格');
    expect(body['description'], '体积：2.5 m³\n吊点在山顶基站');

    // 发单请求体走契约生成模型 ApiTaskDto：适配器拿到的 waypoint 还是
    // 契约对象（dio 在 JSON 编码时才调用 toJson），断言前先归一成 Map。
    final waypoints = (body['waypoints'] as List)
        .map((w) => w is Map ? w : (w as ApiWaypointDto).toJson())
        .toList();
    expect(waypoints, hasLength(2));
    expect(waypoints[0]['orderIndex'], 0);
    expect(waypoints[0]['latitude'], 27.9);
    expect(waypoints[0]['longitude'], 112.9);
    expect(waypoints[1]['orderIndex'], 1);

    // 发单不支付：全程不触碰支付/订单接口
    final paths = adapter.requests.map((r) => r.uri.path).toList();
    expect(
      paths.where((p) => p.startsWith('/pay') || p.startsWith('/order')),
      isEmpty,
      reason: 'ADR-0003：发单阶段不得调用支付/下单接口',
    );

    // 发布成功后表单重置
    final weightField = tester.widget<TextField>(
        find.byKey(const ValueKey('home-cargo-weight-field')));
    expect(weightField.controller!.text, isEmpty);

    await drainSnackBars(tester);
  });

  testWidgets('已发任务：进行中卡片渲染，完成态隐藏', (tester) async {
    final adapter = homeAdapter(tasks: [
      {
        'id': 1,
        'taskNum': 'T-1',
        'taskName': '建材吊运',
        'userId': 7,
        'taskType': 'TRANSPORT',
        'taskStatus': 'IDLE',
        'description': '山顶基站建材',
        'createTime': '2026-09-26 10:00:00',
        'actionHint': '等待飞手应征',
      },
      {
        'id': 2,
        'taskNum': 'T-2',
        'taskName': '已完成吊运',
        'userId': 7,
        'taskType': 'TRANSPORT',
        'taskStatus': 'COMPLETED',
        'createTime': '2026-09-20 10:00:00',
      },
      {
        'id': 3,
        'taskNum': 'T-3',
        'taskName': '待验收吊运',
        'userId': 7,
        'taskType': 'TRANSPORT',
        'taskStatus': 'COMPLETED',
        'matchStatus': 'PENDING_ACCEPTANCE',
        'orderStatus': 'WAITING_CONFIRM',
        'createTime': '2026-09-25 10:00:00',
      },
    ]);
    await pumpHome(tester, adapter);

    expect(find.text('建材吊运'), findsOneWidget);
    expect(find.text('招募飞手中'), findsOneWidget, reason: '阶段文案与订单列表/详情一致');
    expect(find.text('等待飞手应征'), findsOneWidget);
    expect(find.text('山顶基站建材'), findsOneWidget);
    expect(find.text('已完成吊运'), findsNothing, reason: '完成态不在首页摘要展示');
    // 待验收需要用户「确认完成」，必须留在首页（REQ-APP-002 首页展示「待确认」等任务）。
    expect(find.text('待验收吊运'), findsOneWidget);
    expect(find.text('待验收'), findsOneWidget);
  });

  testWidgets('首页收敛：无服务四宫格/推荐飞手/任务广场', (tester) async {
    await pumpHome(tester, homeAdapter());

    expect(find.text('服务分类'), findsNothing);
    expect(find.text('热门飞手推荐'), findsNothing);
    expect(find.text('最新任务广场'), findsNothing);
    expect(find.text('物流吊运'), findsNothing);
    expect(find.text('发布吊运需求'), findsOneWidget);
    expect(find.textContaining('货物类别'), findsOneWidget);
    for (final label in ['建材', '设备', '农产品', '生活物资', '家具家居']) {
      expect(find.widgetWithText(ChoiceChip, label), findsOneWidget, reason: label);
    }
    expect(find.text('我发布的任务'), findsOneWidget);
  });

  testWidgets('卸货点精挑页：全屏地图选点后回填首页', (tester) async {
    await pumpHome(tester, homeAdapter());

    await tester.tap(find.widgetWithText(ListTile, '卸货点'));
    await tester.pumpAndSettle();
    expect(find.byType(MapPickerPage), findsOneWidget);

    final pickerMap = find.descendant(
      of: find.byType(MapPickerPage),
      matching: find.byType(FlutterMap),
    );
    final center = tester.getCenter(pickerMap);
    await tester.tapAt(center + const Offset(60, -40));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.widgetWithText(ElevatedButton, '确认'));
    await tester.pumpAndSettle();

    expect(find.byType(MapPickerPage), findsNothing, reason: '确认后返回首页');
    expect(find.text('已选卸货点，点击地图可更改'), findsOneWidget);
    expect(find.text('点击上方地图，或打开地图精挑'), findsNothing);
  });
}
