import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uav_pilot_app/api/dispatch_material_api.dart';
import 'package:uav_pilot_app/api/generated/openapi_models.dart';
import 'package:uav_pilot_app/models/dispatch_order.dart';
import 'package:uav_pilot_app/pages/waybill/dispatch_fulfillment_pages.dart';
import 'package:uav_pilot_app/providers/dispatch_material_provider.dart';
import '../dispatch_order_test_support.dart';
import 'package:uav_pilot_app/api/dispatch_flight_api.dart';
import 'package:uav_pilot_app/providers/dispatch_flight_provider.dart';
import 'package:uav_pilot_app/providers/waybill_draft_provider.dart';

class NoFlightApi extends Fake implements DispatchFlightApi {}

void main() {
  for (final pilot in [false, true]) {
    testWidgets('delivery needs verified selected evidence for pilot=$pilot', (
      tester,
    ) async {
      final data =
          orderJson(
              stage: pilot ? 'IN_TRANSIT' : 'DELIVERY_CONFIRMATION',
              funds: 'PAID',
            )
            ..['assignedPilotId'] = 7
            ..['assignmentVersion'] = 2;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            waybillDraftScopeProvider.overrideWithValue(null),
            dispatchFlightApiProvider.overrideWithValue(NoFlightApi()),
            dispatchMaterialsProvider('demo-order').overrideWith(
              (ref) async => [
                DispatchMaterial(
                  ApiDispatchMaterialVO.fromJson({
                    'materialId': 'proof',
                    'purpose': pilot ? 'PILOT_DELIVERY' : 'SHIPPER_RECEIPT',
                    'fileName': 'proof.png',
                    'sizeBytes': 3,
                    'uploadStatus': 'UPLOADED',
                    'downloadUrl': 'https://store.local/proof',
                  }),
                ),
              ],
            ),
          ],
          child: MaterialApp(
            home: DispatchFulfillmentShell(
              order: DispatchOrder(ApiDispatchOrderVO.fromJson(data)),
              pilot: pilot,
              phase: '送达双确认',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.widgetWithText(
        FilledButton,
        pilot ? '确认送达' : '确认收货并结单',
      );
      await tester.scrollUntilVisible(
        button,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('unsettled completed order cannot submit review', (tester) async {
    final data = orderJson(stage: 'COMPLETED', funds: 'BALANCE_DUE')
      ..['assignedPilotId'] = 7
      ..['assignmentVersion'] = 2;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dispatchMaterialsProvider(
            'demo-order',
          ).overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          home: DispatchCompletedPage(
            order: DispatchOrder(ApiDispatchOrderVO.fromJson(data)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('模拟支付尾款'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('提交评价'), findsNothing);
    expect(find.text('模拟支付尾款'), findsOneWidget);
  });
}
