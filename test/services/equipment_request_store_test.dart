import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/services/equipment_request_store.dart';

void main() {
  test(
    'attempt persists across restart and is scoped by server account and drone',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final a = EquipmentRequestStore(prefs);
      final key = await a.requestKey('server-a/user-a', 'drone1');
      expect(
        await EquipmentRequestStore(
          prefs,
        ).requestKey('server-a/user-a', 'drone1'),
        key,
      );
      expect(await a.requestKey('server-b/user-a', 'drone1'), isNot(key));
      expect(await a.requestKey('server-a/user-b', 'drone1'), isNot(key));
      expect(await a.requestKey('server-a/user-a', 'drone2'), isNot(key));
      await a.clear('server-a/user-a', 'drone1', key);
      final next = await a.requestKey('server-a/user-a', 'drone1');
      expect(next, isNot(key));
      await a.clear('server-a/user-a', 'drone1', key);
      expect(
        a.saved('server-a/user-a', 'drone1'),
        next,
        reason: 'late old return cannot erase new attempt',
      );
    },
  );
}
