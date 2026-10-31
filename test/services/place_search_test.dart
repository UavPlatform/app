import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:uav_pilot_app/services/place_search.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(
    () => messenger.setMockMethodCallHandler(PlaceSearch.channel, null),
  );

  test('SDK results keep name, address, district and coordinates', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(PlaceSearch.channel, (call) async {
      calls.add(call);
      return [
        {
          'id': 'B0FF',
          'name': '湘潭北站',
          'address': '九华经济开发区',
          'district': '雨湖区',
          'latitude': 27.961,
          'longitude': 112.905,
          'distance': 1200,
        },
      ];
    });

    final results = await PlaceSearch().search(
      key: 'test-key',
      keyword: '  湘潭北站 ',
      city: '湘潭市',
    );

    expect(results, hasLength(1));
    expect(results.single.name, '湘潭北站');
    expect(results.single.point.latitude, 27.961);
    expect(results.single.point.longitude, 112.905);
    expect(results.single.description, '雨湖区 九华经济开发区');
    expect(calls.single.method, 'search');
    final args = calls.single.arguments as Map;
    expect(args['key'], 'test-key');
    expect(args['keyword'], '湘潭北站');
    expect(args['city'], '湘潭市');
    expect(args.containsKey('center'), isFalse);
  });

  test('search passes map center for bounded lookup', () async {
    Map<dynamic, dynamic>? payload;
    messenger.setMockMethodCallHandler(PlaceSearch.channel, (call) async {
      payload = call.arguments as Map;
      return const [];
    });

    await PlaceSearch().search(
      key: 'k',
      keyword: '仓库',
      center: const LatLng(27.9, 112.9),
    );

    expect(payload!['center'], {'latitude': 27.9, 'longitude': 112.9});
  });

  test('invalid SDK rows are dropped instead of yielding bad coordinates', () async {
    messenger.setMockMethodCallHandler(
      PlaceSearch.channel,
      (_) async => [
        {'name': '', 'latitude': 27.9, 'longitude': 112.9},
        {'name': '越界', 'latitude': 91, 'longitude': 112.9},
        {'name': '无坐标'},
        {'name': '有效点', 'latitude': 27.9, 'longitude': 112.9},
      ],
    );

    final results = await PlaceSearch().search(key: 'k', keyword: '点');

    expect(results.map((result) => result.name), ['有效点']);
  });

  test('empty keyword never reaches the platform channel', () async {
    var invoked = false;
    messenger.setMockMethodCallHandler(PlaceSearch.channel, (_) async {
      invoked = true;
      return const [];
    });

    expect(await PlaceSearch().search(key: 'k', keyword: '   '), isEmpty);
    expect(invoked, isFalse);
  });

  test('missing key fails before calling the SDK', () async {
    var invoked = false;
    messenger.setMockMethodCallHandler(PlaceSearch.channel, (_) async {
      invoked = true;
      return const [];
    });

    await expectLater(
      PlaceSearch().search(key: ' ', keyword: '仓库'),
      throwsA(
        isA<PlaceSearchException>().having(
          (error) => error.message,
          'message',
          contains('地图服务暂不可用'),
        ),
      ),
    );
    expect(invoked, isFalse);
  });

  test('platform failures surface the SDK message', () async {
    messenger.setMockMethodCallHandler(
      PlaceSearch.channel,
      (_) async => throw PlatformException(
        code: 'SEARCH_FAILED',
        message: '搜索失败，请稍后重试',
      ),
    );

    await expectLater(
      PlaceSearch().search(key: 'k', keyword: '仓库'),
      throwsA(
        isA<PlaceSearchException>().having(
          (error) => error.message,
          'message',
          '搜索失败，请稍后重试',
        ),
      ),
    );
  });
}
