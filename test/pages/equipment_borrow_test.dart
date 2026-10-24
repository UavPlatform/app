import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/pages/pilot/equipment_borrow_page.dart';
import 'package:uav_pilot_app/providers/auth_provider.dart';
import 'package:uav_pilot_app/providers/equipment_provider.dart';
import 'package:uav_pilot_app/providers/waybill_draft_provider.dart';
import 'package:uav_pilot_app/services/token_storage.dart';
import '../equipment_test_support.dart';

void main() {
  testWidgets(
    'lost response reuses attempt; only server confirms borrowing and returning',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final client = HttpClient(TokenStorage(prefs));
      final api = FakeEquipmentApi(client);
      addTearDown(() => client.dio.close());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            equipmentApiProvider.overrideWithValue(api),
            sharedPreferencesProvider.overrideWithValue(prefs),
            waybillDraftScopeProvider.overrideWithValue('equipment-test-scope'),
          ],
          child: const MaterialApp(home: EquipmentBorrowPage()),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> tap(String label) async {
        final target = find.text(label).last;
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      await tap('登记借用');
      await tap('确认登记');
      expect(find.textContaining('登记响应丢失'), findsOneWidget);
      expect(find.text('状态：本人借用中'), findsNothing);
      await tap('登记借用');
      await tap('确认登记');
      expect(api.keys, hasLength(2));
      expect(api.keys[0], api.keys[1]);
      expect(find.text('状态：本人借用中'), findsOneWidget);
      await tap('登记归还');
      await tap('确认登记');
      expect(find.text('状态：可借用'), findsOneWidget);
      await tap('我的借还');
      expect(find.textContaining('归还时间：2026-10-23'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
