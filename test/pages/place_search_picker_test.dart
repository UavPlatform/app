// 选点页 POI 搜索：输入即检索、结果回填、确认回传名称；发单表单消费回传名称。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:uav_pilot_app/models/amap_config.dart';
import 'package:uav_pilot_app/models/waybill_draft.dart';
import 'package:uav_pilot_app/pages/home/map_picker_page.dart';
import 'package:uav_pilot_app/pages/waybill/site_fields.dart';
import 'package:uav_pilot_app/providers/map_provider.dart';
import 'package:uav_pilot_app/services/place_search.dart';

import '../map_test_support.dart';

class _FakePlaceSearch extends PlaceSearch {
  _FakePlaceSearch({this.results = const [], this.error});

  final List<PlaceSearchResult> results;
  final PlaceSearchException? error;
  final calls = <String>[];

  @override
  Future<List<PlaceSearchResult>> search({
    required String key,
    required String keyword,
    String? city,
    LatLng? center,
    int limit = 20,
  }) async {
    calls.add(keyword);
    if (error != null) throw error!;
    return results;
  }
}

PlaceSearchResult _place(String name, double lat, double lng) =>
    PlaceSearchResult.fromMap({
      'id': name,
      'name': name,
      'address': '九华经济开发区',
      'district': '雨湖区',
      'latitude': lat,
      'longitude': lng,
    });

Future<void> _mockLocationChannel(WidgetTester tester) async {
  final messenger = tester.binding.defaultBinaryMessenger;
  const channel = MethodChannel('com.fuwaki.app/location');
  messenger.setMockMethodCallHandler(channel, (call) async {
    if (call.method == 'getLocation') {
      return {
        'latitude': 27.9,
        'longitude': 112.9,
        'city': '湘潭市',
        'address': '测试定位',
      };
    }
    return null;
  });
  addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
}

/// 打开选点页并等待 pop 返回值。
Future<String? Function()> _pumpPicker(
  WidgetTester tester, {
  required PlaceSearch search,
}) async {
  mockNativeMaps(tester);
  await _mockLocationChannel(tester);
  String? picked;
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () async {
              picked = await context.push<String>('/map/pick');
            },
            child: const Text('打开选点'),
          ),
        ),
      ),
      GoRoute(path: '/map/pick', builder: (_, _) => const MapPickerPage()),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        amapMapConfigProvider.overrideWith(
          (ref) async => AmapConfig(key: 'test-key'),
        ),
        placeSearchProvider.overrideWithValue(search),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('打开选点'));
  await tester.pumpAndSettle();
  return () => picked;
}

void main() {
  testWidgets('typing searches the SDK and selecting a result fills the panel', (
    tester,
  ) async {
    final search = _FakePlaceSearch(
      results: [_place('湘潭北站', 27.961, 112.905)],
    );
    final picked = await _pumpPicker(tester, search: search);

    await tester.enterText(
      find.byKey(const ValueKey('place-search-field')),
      '湘潭北站',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(search.calls, ['湘潭北站']);
    expect(find.byKey(const ValueKey('place-湘潭北站')), findsOneWidget);
    expect(find.text('雨湖区 九华经济开发区'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('place-湘潭北站')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('place-search-results')), findsNothing);
    expect(
      find.byKey(const ValueKey('place-selected-name')),
      findsOneWidget,
    );
    expect(find.textContaining('27.961000'), findsOneWidget);

    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();
    expect(picked(), '27.961000,112.905000;湘潭北站;雨湖区 九华经济开发区');
  });

  testWidgets('debounce collapses rapid typing into one search', (
    tester,
  ) async {
    final search = _FakePlaceSearch(results: [_place('仓库', 27.9, 112.9)]);
    await _pumpPicker(tester, search: search);

    final field = find.byKey(const ValueKey('place-search-field'));
    await tester.enterText(field, '仓');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(field, '仓库');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(search.calls, ['仓库']);
  });

  testWidgets('clearing during the debounce window cancels the search', (
    tester,
  ) async {
    final search = _FakePlaceSearch(results: [_place('湘潭北站', 27.961, 112.905)]);
    await _pumpPicker(tester, search: search);

    final field = find.byKey(const ValueKey('place-search-field'));
    await tester.enterText(field, '湘潭');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(field, '');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(search.calls, isEmpty);
    expect(find.byKey(const ValueKey('place-search-results')), findsNothing);
  });

  testWidgets('empty result and SDK failure both surface a message', (
    tester,
  ) async {
    final empty = _FakePlaceSearch(results: const []);
    await _pumpPicker(tester, search: empty);
    await tester.enterText(
      find.byKey(const ValueKey('place-search-field')),
      '不存在的点',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('没有找到相关地点，换个关键词试试'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    final failing = _FakePlaceSearch(
      error: const PlaceSearchException('地图 Key 无效'),
    );
    await _pumpPicker(tester, search: failing);
    await tester.enterText(
      find.byKey(const ValueKey('place-search-field')),
      '仓库',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('地图 Key 无效'), findsOneWidget);
  });

  testWidgets('clearing the field hides results and resets the query', (
    tester,
  ) async {
    final search = _FakePlaceSearch(results: [_place('湘潭北站', 27.961, 112.905)]);
    await _pumpPicker(tester, search: search);
    final field = find.byKey(const ValueKey('place-search-field'));
    await tester.enterText(field, '湘潭');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('place-search-results')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('place-search-clear')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('place-search-results')), findsNothing);
    expect(
      tester.widget<TextField>(field).controller!.text,
      isEmpty,
    );
  });

  testWidgets('site field stores picked place name and address locally', (
    tester,
  ) async {
    var draft = WaybillDraft(fields: {
      'end.lat': '28.1',
      'end.lng': '113.6',
      'end.place': '',
      'end.placeAddress': '',
    });
    late StateSetter rebuild;
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return SiteFields(
                  draft: draft,
                  prefix: 'end',
                  errors: const {},
                  onChanged: (key, value) =>
                      setState(() => draft = draft.change(key, value)),
                );
              },
            ),
          ),
        ),
        GoRoute(
          path: '/map/pick',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  context.pop('28.123456,113.654321;湘潭北站;雨湖区 九华经济开发区'),
              child: const Text('回传地点'),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('end.pick')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('回传地点'));
    await tester.pumpAndSettle();
    rebuild(() {});

    expect(draft.value('end.lat'), '28.123456');
    expect(draft.value('end.lng'), '113.654321');
    expect(draft.value('end.place'), '湘潭北站');
    expect(draft.value('end.placeAddress'), '雨湖区 九华经济开发区');
    expect(
      find.text('湘潭北站 · 28.123456, 113.654321'),
      findsOneWidget,
    );
    // 地点名称是本地展示字段，不能进入提交给后端的云端字段。
    expect(draft.cloudFields.containsKey('end.place'), isFalse);
  });
}
