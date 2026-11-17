import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/api/generated/openapi_models.dart';
import 'package:uav_pilot_app/models/dispatch_order.dart';
import 'package:uav_pilot_app/pages/pilot/equipment_borrow_page.dart';
import 'package:uav_pilot_app/providers/auth_provider.dart';
import 'package:uav_pilot_app/providers/dispatch_order_provider.dart';
import 'package:uav_pilot_app/providers/equipment_provider.dart';
import 'package:uav_pilot_app/providers/waybill_draft_provider.dart';
import 'package:uav_pilot_app/services/token_storage.dart';
import '../equipment_test_support.dart';

DispatchOrder _order({
  required String id,
  required String acceptedAt,
  required String start,
  required String phone,
}) => DispatchOrder(
  ApiDispatchOrderVO.fromJson({
    'orderId': id,
    'stage': 'IN_TRANSIT',
    'fundsStatus': 'PAID',
    'paymentMode': 'SIMULATED',
    'currency': 'CNY',
    'depositAmount': 125.5,
    'pilotServiceFee': 180.5,
    'assignedPilotId': 7,
    'assignmentVersion': 1,
    'acceptedAt': acceptedAt,
    'fields': {
      'start.site': start,
      'end.site': '测试终点',
      'start.phone': phone,
      'end.phone': phone,
    },
  }),
);

void main() {
  testWidgets('apply by model reuses attempt; return works on approved loan', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final client = HttpClient(TokenStorage(prefs));
    final api = FakeEquipmentApi(client);
    addTearDown(() => client.dio.close());
    final older = _order(
      id: 'order-old-0001',
      acceptedAt: '2026-11-07T09:00:00',
      start: '旧单起点',
      phone: '13800001111',
    );
    final newer = _order(
      id: 'order-new-0002',
      acceptedAt: '2026-11-08T09:00:00',
      start: '新单起点',
      phone: '13900005678',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          equipmentApiProvider.overrideWithValue(api),
          sharedPreferencesProvider.overrideWithValue(prefs),
          waybillDraftScopeProvider.overrideWithValue('equipment-test-scope'),
          dispatchPilotOrdersProvider.overrideWith(
            (ref) async => [older, newer],
          ),
        ],
        child: const MaterialApp(home: EquipmentBorrowPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('设备借用'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('暂未借用设备'), findsOneWidget);
    expect(find.text('暂无申请记录'), findsOneWidget);
    expect(find.text('① 提交申请'), findsOneWidget);

    await tester.tap(find.text('立即申请'));
    await tester.pumpAndSettle();
    expect(find.text('发起借机申请'), findsOneWidget);

    await tester.tap(find.textContaining('FC30（在库'));
    await tester.pumpAndSettle();

    expect(find.text('不关联订单'), findsNothing);
    expect(find.textContaining('联系人尾号 5678'), findsOneWidget);
    expect(find.textContaining('联系人尾号 1111'), findsOneWidget);
    expect(
      tester.getTopLeft(find.textContaining('新单起点')).dy,
      lessThan(tester.getTopLeft(find.textContaining('旧单起点')).dy),
    );

    await tester.ensureVisible(find.text('提交申请'));
    await tester.tap(find.text('提交申请'));
    await tester.pumpAndSettle();
    expect(find.text('请选择要关联的订单'), findsOneWidget);
    expect(api.keys, isEmpty);

    await tester.ensureVisible(find.textContaining('新单起点'));
    await tester.tap(find.textContaining('新单起点'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('提交申请'));
    await tester.tap(find.text('提交申请'));
    await tester.pumpAndSettle();
    expect(find.textContaining('申请响应丢失'), findsOneWidget);

    await tester.ensureVisible(find.text('提交申请'));
    await tester.tap(find.text('提交申请'));
    await tester.pumpAndSettle();
    expect(api.keys, hasLength(2));
    expect(api.keys[0], api.keys[1]);
    expect(api.lastModelId, 1);

    api.active = true;
    expect(find.byTooltip('刷新'), findsNothing);
    await tester.drag(find.byType(RefreshIndicator), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(find.textContaining('TEST-SERIAL'), findsNothing);
    await tester.tap(find.text('借用详情').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('TEST-SERIAL'), findsOneWidget);

    await tester.tap(find.text('归还设备').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '确认归还'));
    await tester.pumpAndSettle();
    expect(find.textContaining('归还 · '), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
