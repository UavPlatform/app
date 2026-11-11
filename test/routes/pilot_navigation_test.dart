import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/pages/pilot/dispatch_pilot_pages.dart';
import 'package:uav_pilot_app/pages/pilot/pilot_profile_page.dart';
import 'package:uav_pilot_app/routes/app_router.dart';
import '../test_support.dart';
import 'user_shell_route_test.dart' show pumpLoggedInApp;

void main() {
  tearDown(() {
    HttpClient.onUnauthorized = null;
    HttpClient.onDroneRequired = null;
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets(
    'pilot home directly shows the hall and jobs open independently from profile',
    (tester) async {
      final container = await pumpLoggedInApp(
        tester,
        role: 1,
        handler: (options) async => jsonResponse(200, {
          'success': true,
          'data': options.uri.path == '/dispatch/pilot/hall'
              ? {'page': 0, 'hasNext': false, 'items': []}
              : [],
        }),
      );
      expect(find.byType(DispatchPilotHallPage), findsOneWidget);
      expect(find.text('选择下一步'), findsNothing);
      expect(find.text('接单记录'), findsNothing);
      final router = container.read(goRouterProvider);
      router.go('/pilot/tasks');
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/pilot/home');
      await tester.tap(
        find.descendant(
          of: find.byType(BottomNavigationBar),
          matching: find.text('我的'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PilotProfilePage), findsOneWidget);
      await tester.tap(find.text('接单记录'));
      await tester.pumpAndSettle();
      expect(find.byType(DispatchPilotJobsPage), findsOneWidget);
      expect(router.canPop(), isTrue);
      expect(find.byType(BottomNavigationBar), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(PilotProfilePage), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/pilot/profile');
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets(
    'dialogs and child routes pop normally; Android root requires two backs',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      var exits = 0;
      final handlesBack = <bool>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'SystemNavigator.pop') exits++;
            if (call.method == 'SystemNavigator.setFrameworkHandlesBack') {
              handlesBack.add(call.arguments as bool);
            }
            return null;
          });
      final container = await pumpLoggedInApp(tester, role: 1);
      final router = container.read(goRouterProvider);
      expect(handlesBack, contains(true));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('再按一次返回键退出'), findsOneWidget);
      expect(exits, 0);
      router.go('/pilot/profile');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('关于飞翼通'));
      await tester.tap(find.text('关于飞翼通'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(AboutDialog), findsNothing);
      expect(exits, 0);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(exits, 0);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(exits, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      debugDefaultTargetPlatformOverride = null;
    },
  );
}
