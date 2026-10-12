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
      return jsonResponse(200, {
        'success': false,
        'message': 'unexpected create',
      });
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
      GoRoute(
        path: '/map/pick',
        builder: (_, state) => state.uri.queryParameters['point'] == 'start'
            ? const MapPickerPage.start()
            : const MapPickerPage(),
      ),
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

/// 表单展开时通过卸货点入口进入全屏地图，避免与背景地图争抢操作。
Future<void> tapHomeMap(WidgetTester tester) async {
  final destination = find.byKey(const ValueKey('home-destination-row'));
  await tester.ensureVisible(destination);
  await tester.tap(destination);
  await tester.pumpAndSettle();
  final center = tester.getCenter(
    find.descendant(
      of: find.byType(MapPickerPage),
      matching: find.byType(FlutterMap),
    ),
  );
  await tester.tapAt(center + const Offset(60, -30));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(find.widgetWithText(ElevatedButton, '确认'));
  await tester.pumpAndSettle();
}

/// SnackBar 自带 4s 展示定时器，断言后需清干净，避免用例收尾报 pending timer。
Future<void> drainSnackBars(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

/// 滚动底部抽屉直到「发布吊运需求」按钮可见后点击。
/// 发布按钮位于抽屉 ListView 底部，抽屉收起时不可点。
Future<void> tapPublish(WidgetTester tester) async {
  final finder = find.widgetWithText(ElevatedButton, '发布吊运需求');
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_locationChannel, (call) async {
          if (call.method == 'getLocation') {
            return <String, Object>{
              'city': '长沙市',
              'address': '长沙市雨湖区建设路 1 号',
              'latitude': 27.9,
              'longitude': 112.9,
            };
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

    await tapPublish(tester);
    await tester.pumpAndSettle();

    expect(find.text('请选择货物类别'), findsOneWidget);
    expect(
      adapter.requests.where((r) => r.uri.path == '/task/create'),
      isEmpty,
    );

    await drainSnackBars(tester);
  });

  testWidgets('发布校验：重量必填且为正数', (tester) async {
    final adapter = homeAdapter();
    await pumpHome(tester, adapter);

    await tester.tap(find.widgetWithText(ChoiceChip, '建材'));
    await tester.pumpAndSettle();

    await tapPublish(tester);
    await tester.pumpAndSettle();
    expect(find.text('请输入货物重量'), findsOneWidget);
    await drainSnackBars(tester);

    await tester.enterText(
      find.byKey(const ValueKey('home-cargo-weight-field')),
      '0',
    );
    await tapPublish(tester);
    await tester.pumpAndSettle();
    expect(find.text('货物重量必须为正数'), findsOneWidget);
    await drainSnackBars(tester);

    // 多个小数点无法解析 → 格式错误提示
    await tester.enterText(
      find.byKey(const ValueKey('home-cargo-weight-field')),
      '1.2.3',
    );
    await tapPublish(tester);
    await tester.pumpAndSettle();
    expect(find.text('请输入正确的货物重量'), findsOneWidget);
    expect(
      adapter.requests.where((r) => r.uri.path == '/task/create'),
      isEmpty,
    );

    await drainSnackBars(tester);
  });

  testWidgets('发布校验：终点必选', (tester) async {
    final adapter = homeAdapter();
    await pumpHome(tester, adapter);

    await tester.tap(find.widgetWithText(ChoiceChip, '建材'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('home-cargo-weight-field')),
      '12.5',
    );

    await tapPublish(tester);
    await tester.pumpAndSettle();

    expect(find.text('请选择卸货点'), findsOneWidget);
    expect(
      adapter.requests.where((r) => r.uri.path == '/task/create'),
      isEmpty,
    );

    await drainSnackBars(tester);
  });

  for (final entry in const {
    'DAILY_SUPPLIES': '生活物资',
    'FURNITURE': '家具家居',
  }.entries) {
    final label = entry.value;
    testWidgets('$label 选项提交独立货物类别', (tester) async {
      Map<String, dynamic>? body;
      await pumpHome(
        tester,
        homeAdapter(
          onCreate: (options) async {
            body = Map<String, dynamic>.from(options.data as Map);
            return jsonResponse(200, {'success': false, 'message': 'stub'});
          },
        ),
      );
      final option = find.widgetWithText(ChoiceChip, label);
      await tester.ensureVisible(option);
      await tester.tap(option);
      await tester.enterText(
        find.byKey(const ValueKey('home-cargo-weight-field')),
        '20',
      );
      await tester.pumpAndSettle();
      await tapHomeMap(tester);
      await tapPublish(tester);
      expect(body?['cargoCategory'], entry.key);
      expect(body?['taskName'], '$label吊运');
      expect(body?['description'], '');
      await drainSnackBars(tester);
    });
  }

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

    // 起吊点 = 当前定位（展示逆地理编码地址，不再暴露经纬度）
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-start-point-tile')),
        matching: find.text('长沙市雨湖区建设路 1 号'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(ChoiceChip, '建材'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('home-cargo-weight-field')),
      '12.5',
    );
    await tester.enterText(
      find.byKey(const ValueKey('home-cargo-volume-field')),
      '2.5',
    );
    await tester.pump();

    // 吊运说明为直接可见的文本域（不再折叠）
    await tester.enterText(
      find.byKey(const ValueKey('home-cargo-description-field')),
      '吊点在山顶基站',
    );
    await tester.pump();

    // 地图点选卸货点（地图位于抽屉上方，可直接点选）
    await tapHomeMap(tester);
    expect(find.text('已选择卸货点'), findsOneWidget);
    expect(find.text('已选卸货点，点击地图可更改'), findsNothing);

    await tapPublish(tester);
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
      find.byKey(const ValueKey('home-cargo-weight-field')),
    );
    expect(weightField.controller!.text, isEmpty);

    await drainSnackBars(tester);
  });

  testWidgets('首页不再展示本人任务列表（收敛到订单 Tab）', (tester) async {
    final adapter = homeAdapter(
      tasks: [
        {
          'id': 1,
          'taskNum': 'T-1',
          'taskName': '建材吊运',
          'userId': 7,
          'taskType': 'TRANSPORT',
          'taskStatus': 'IDLE',
          'createTime': '2026-09-26 10:00:00',
        },
      ],
    );
    await pumpHome(tester, adapter);

    expect(find.text('我发布的任务'), findsNothing);
    expect(find.text('建材吊运'), findsNothing);
  });

  testWidgets('首页收敛：无服务四宫格/推荐飞手/任务广场', (tester) async {
    await pumpHome(tester, homeAdapter());

    expect(find.text('服务分类'), findsNothing);
    expect(find.text('热门飞手推荐'), findsNothing);
    expect(find.text('最新任务广场'), findsNothing);
    expect(find.text('物流吊运'), findsNothing);
    expect(find.text('发布吊运需求'), findsOneWidget);
    expect(find.textContaining('货物类别'), findsOneWidget);
    expect(find.text('我发布的任务'), findsNothing);
  });

  testWidgets('卸货点精挑页：全屏地图选点后回填首页', (tester) async {
    await pumpHome(tester, homeAdapter());

    await tester.tap(find.byKey(const ValueKey('home-destination-row')));
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
    expect(find.text('已选择卸货点'), findsOneWidget);
    expect(find.text('已选卸货点，点击地图可更改'), findsNothing);
    expect(find.text('点击上方地图，或打开地图精挑'), findsNothing);
  });

  testWidgets('定位不可用：标题提示可重试，起吊点可在地图上手动选择并用于发单',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_locationChannel, (call) async => null);
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
            'taskName': '设备吊运',
            'userId': 7,
            'taskType': 'TRANSPORT',
            'taskStatus': 'IDLE',
          },
        });
      },
    );
    await pumpHome(tester, adapter);

    expect(find.text('未知城市'), findsNothing);
    expect(find.text('定位不可用，点击在地图上选择起吊点'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, '设备'));
    await tester.enterText(
      find.byKey(const ValueKey('home-cargo-weight-field')),
      '8',
    );
    await tapHomeMap(tester);
    await tapPublish(tester);
    expect(
      find.text('无法获取当前位置，请点击「起吊点」在地图上手动选择'),
      findsOneWidget,
    );
    expect(createBody, isNull);
    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger).first)
        .clearSnackBars();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('home-start-point-tile')));
    await tester.pumpAndSettle();
    expect(find.text('选择起吊点'), findsOneWidget);
    final pickerMap = find.descendant(
      of: find.byType(MapPickerPage),
      matching: find.byType(FlutterMap),
    );
    await tester.tapAt(tester.getCenter(pickerMap) + const Offset(-50, 30));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.widgetWithText(ElevatedButton, '确认'));
    await tester.pumpAndSettle();
    expect(find.text('起吊点（手动选择）'), findsOneWidget);

    await tapPublish(tester);
    expect(createBody, isNotNull);
    final waypoints = (createBody!['waypoints'] as List)
        .map((w) => w is Map ? w : (w as ApiWaypointDto).toJson())
        .toList();
    expect(waypoints, hasLength(2));
    expect(waypoints.first['orderIndex'], 0);
    expect(waypoints.first['latitude'], isA<num>());
    expect(waypoints.first['latitude'], isNot(waypoints.last['latitude']));
    await drainSnackBars(tester);
  });
}
