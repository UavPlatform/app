import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uav_pilot_app/widgets/hud_surface.dart';
import 'package:uav_pilot_app/providers/map_provider.dart';
import 'package:uav_pilot_app/pages/waybill/dispatch_map_home.dart';
import '../models/dispatch_tracking_test.dart' show trackingOrder;

void main() {
  testWidgets(
    'Android HUD with normal motion has no backdrop readback or continuous frame scheduling',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: false),
            child: Scaffold(
              body: SizedBox(
                width: 240,
                child: HudStatusCapsule(activeCount: 1),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.text('1 单进行中 · 点击标记查看'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'order drawer expands and collapses with production motion settings',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            amapMapConfigProvider.overrideWith(
              (ref) async => throw StateError('offline'),
            ),
          ],
          child: MaterialApp(
            home: const MediaQuery(
              data: MediaQueryData(disableAnimations: false),
              child: _OrderHome(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final sheet = tester.widget<DraggableScrollableSheet>(
        find.byType(DraggableScrollableSheet),
      );
      final before = sheet.controller!.size;
      final drawer = find.byKey(const ValueKey('dispatch-home-drawer'));
      await tester.dragFrom(
        tester.getTopLeft(drawer) + const Offset(150, 25),
        const Offset(0, -180),
      );
      await tester.pumpAndSettle();
      expect(sheet.controller!.size, greaterThan(before));
      await tester.dragFrom(
        tester.getTopLeft(drawer) + const Offset(150, 25),
        const Offset(0, 240),
      );
      await tester.pumpAndSettle();
      expect(sheet.controller!.size, lessThan(.76));
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    },
  );
}

class _OrderHome extends StatelessWidget {
  const _OrderHome();
  @override
  Widget build(BuildContext context) => Scaffold(
    body: DispatchMapHome(orders: [trackingOrder('a', stage: 'IN_TRANSIT')]),
  );
}
