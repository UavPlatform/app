import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/pages/pilot/equipment_borrow_page.dart';
import 'package:uav_pilot_app/providers/auth_provider.dart';
import 'package:uav_pilot_app/providers/dispatch_order_provider.dart';
import 'package:uav_pilot_app/providers/equipment_provider.dart';
import 'package:uav_pilot_app/providers/waybill_draft_provider.dart';
import 'package:uav_pilot_app/services/token_storage.dart';
import '../equipment_test_support.dart';

void main() {
  testWidgets(
    'apply by model reuses attempt; return works on approved loan',
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
            dispatchPilotOrdersProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(home: EquipmentBorrowPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('当前没有已借出的飞机'), findsOneWidget);

      await tester.tap(find.text('发起申请'));
      await tester.pumpAndSettle();
      expect(find.text('发起借机申请'), findsOneWidget);

      await tester.tap(find.textContaining('FC30（在库'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('提交申请'));
      await tester.pumpAndSettle();
      expect(find.textContaining('申请响应丢失'), findsOneWidget);

      await tester.tap(find.text('提交申请'));
      await tester.pumpAndSettle();
      expect(api.keys, hasLength(2));
      expect(api.keys[0], api.keys[1]);
      expect(api.lastModelId, 1);

      api.active = true;
      await tester.tap(find.byTooltip('刷新'));
      await tester.pumpAndSettle();
      expect(find.textContaining('TEST-SERIAL'), findsWidgets);

      await tester.tap(find.text('归还').first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '确认归还'));
      await tester.pumpAndSettle();
      expect(find.textContaining('归还时间：2026-10-23'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
