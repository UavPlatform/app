import 'package:uav_pilot_app/api/dispatch_material_api.dart';
import 'package:uav_pilot_app/providers/dispatch_material_provider.dart';
import 'package:uav_pilot_app/pages/waybill/dispatch_material_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uav_pilot_app/api/generated/openapi_models.dart';
import 'package:uav_pilot_app/models/dispatch_order.dart';
import 'package:uav_pilot_app/pages/waybill/dispatch_order_information.dart';
import 'package:uav_pilot_app/pages/waybill/dispatch_price_card.dart';
import 'package:uav_pilot_app/providers/dispatch_order_provider.dart';
import 'package:uav_pilot_app/providers/waybill_draft_provider.dart';
import 'package:uav_pilot_app/theme/app_theme.dart';
import 'package:uav_pilot_app/widgets/flow_ui.dart';
import '../dispatch_order_test_support.dart';

void main() {
  testWidgets(
    'all-materials page selects evidence beyond the compact preview',
    (tester) async {
      List<String> selected = [];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            waybillDraftScopeProvider.overrideWithValue('account-a'),
            dispatchMaterialsProvider('order').overrideWith(
              (ref) async => [
                for (var i = 1; i <= 5; i++)
                  DispatchMaterial(
                    ApiDispatchMaterialVO.fromJson({
                      'materialId': 'proof$i',
                      'purpose': 'PILOT_DELIVERY',
                      'fileName': '材料$i.jpg',
                      'sizeBytes': 3,
                      'uploadStatus': 'UPLOADED',
                      'downloadUrl': 'https://store.local/proof$i',
                    }),
                  ),
              ],
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: FlowList(
                children: [
                  DispatchMaterialPanel(
                    orderId: 'order',
                    purpose: 'PILOT_DELIVERY',
                    onSelected: (ids) => selected = ids,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('材料5.jpg'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('查看全部材料'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('查看全部材料'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('材料5.jpg'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      final row = find.ancestor(
        of: find.text('材料5.jpg'),
        matching: find.byType(ListTile),
      );
      await tester.tap(
        find.descendant(of: row, matching: find.byType(Checkbox)),
      );
      await tester.pumpAndSettle();
      expect(selected, ['proof5']);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.textContaining('已选择 1 份'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'long order reference opens live details and revocation hides data',
    (tester) async {
      const id = 'order-1234567890-abcdef-9876543210';
      final permitted = StateProvider((ref) => true);
      final data = orderJson()..['orderId'] = id;
      final order = DispatchOrder(ApiDispatchOrderVO.fromJson(data));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            waybillDraftScopeProvider.overrideWithValue('account-a'),
            dispatchOrderProvider(id).overrideWith((ref) async {
              if (!ref.watch(permitted)) throw StateError('no longer allowed');
              return order;
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(body: DispatchOrderInformationLink(order: order)),
          ),
        ),
      );
      expect(find.textContaining(id), findsNothing);
      await tester.tap(find.text('运单资料与账单'));
      await tester.pumpAndSettle();
      expect(find.text(id), findsOneWidget);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(DispatchOrderInformationPage)),
      );
      container.read(permitted.notifier).state = false;
      await tester.pumpAndSettle();
      expect(find.text(id), findsNothing);
      expect(find.text('资料暂不可用，重新查询'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'fee summary opens full reference and account switch closes content',
    (tester) async {
      final account = StateProvider<String?>((ref) => 'account-a');
      final quote = ApiDispatchQuoteVO.fromJson({
        'distanceMeters': 1450,
        'pricePerMeter': .05,
        'distanceCharge': 72.5,
        'pilotServiceFee': 100,
        'totalAmount': 172.5,
        'depositAmount': 100,
      });
      final bill = ApiDispatchBillVO.fromJson({
        'finalAmount': 172.5,
        'balanceAmount': 72.5,
        'settlementReference': 'simulation-settlement-full-reference-123456789',
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            waybillDraftScopeProvider.overrideWith((ref) => ref.watch(account)),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: DispatchPriceCard(quote: quote, bill: bill),
            ),
          ),
        ),
      );
      expect(
        find.textContaining('simulation-settlement-full-reference'),
        findsNothing,
      );
      await tester.tap(find.text('查看费用明细'));
      await tester.pumpAndSettle();
      final reference = find.text(
        'simulation-settlement-full-reference-123456789',
      );
      await tester.scrollUntilVisible(
        reference,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(reference, findsOneWidget);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FlowDetailPage)),
      );
      container.read(account.notifier).state = 'account-b';
      await tester.pumpAndSettle();
      expect(reference, findsNothing);
      expect(find.text('账号或服务器已切换，请返回重新打开'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('small viewport keeps summary bounded with long endpoint names', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final data = orderJson()
      ..['fields'] = {
        'category': '普通',
        'start.site': List.filled(12, '山顶装卸作业场地').join(),
        'end.site': List.filled(12, '山下临时交付场地').join(),
      };
    final order = DispatchOrder(ApiDispatchOrderVO.fromJson(data));
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: FlowList(
            children: [
              FlowHeader(title: '我的吊运', subtitle: '查看订单进度与下一步操作'),
              DispatchOrderCard(order: order, onTap: () => opened = true),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('查看进度'));
    expect(opened, isTrue);
    expect(tester.takeException(), isNull);
  });
}
