import 'package:flutter_test/flutter_test.dart';
import 'package:uav_pilot_app/services/dispatch_navigation.dart';

void main() {
  test(
    'ground navigation uses the selected GCJ point in longitude latitude order without contacts',
    () async {
      final opened = <Uri>[];
      final navigation = DispatchNavigation(
        launch: (uri) async {
          opened.add(uri);
          return true;
        },
      );
      final fields = {
        'start.lat': '28.2',
        'start.lng': '113.0',
        'end.lat': '28.3',
        'end.lng': '113.1',
        'start.phone': '13800000000',
        'start.contact': '联系人',
      };
      expect(await navigation.open(fields, 'start'), isTrue);
      expect(await navigation.open(fields, 'end'), isTrue);
      expect(opened.first.host, 'uri.amap.com');
      expect(opened.first.queryParameters['to'], '113.0,28.2,运单起点');
      expect(opened.last.queryParameters['to'], '113.1,28.3,运单终点');
      expect(opened.first.queryParameters['from'], '');
      expect(opened.first.queryParameters['mode'], 'car');
      expect(opened.first.toString(), isNot(contains('13800000000')));
    },
  );
  test(
    'missing nonfinite out of range coordinates never launch and platform failures return false',
    () async {
      var calls = 0;
      final navigation = DispatchNavigation(
        launch: (_) async {
          calls++;
          throw StateError('unavailable');
        },
      );
      for (final value in ['', 'NaN', 'Infinity', '91', '-91']) {
        expect(
          await navigation.open({
            'start.lat': value,
            'start.lng': '113',
          }, 'start'),
          isFalse,
        );
      }
      expect(
        await navigation.open({'start.lat': '28', 'start.lng': '181'}, 'start'),
        isFalse,
      );
      expect(
        await navigation.open({'start.lat': '28', 'start.lng': '113'}, 'other'),
        isFalse,
      );
      expect(calls, 0);
      expect(
        await navigation.open({'start.lat': '28', 'start.lng': '113'}, 'start'),
        isFalse,
      );
      expect(calls, 1);
    },
  );
}
