import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/providers/auth_provider.dart';
import 'package:uav_pilot_app/providers/theme_provider.dart';
import 'package:uav_pilot_app/pages/profile/profile_page.dart';
import 'package:uav_pilot_app/routes/app_router.dart';
import 'package:uav_pilot_app/widgets/app_bottom_nav.dart';
import '../routes/user_shell_route_test.dart' show pumpLoggedInApp;

void main() {
  test('Theme preference is restored and persisted', () async {
    SharedPreferences.setMockInitialValues({'dark_mode': true});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    expect(container.read(themeModeProvider), ThemeMode.dark);
    await container.read(themeModeProvider.notifier).toggle();
    expect(container.read(themeModeProvider), ThemeMode.light);
    expect(prefs.getBool('dark_mode'), isFalse);
    await container.read(themeModeProvider.notifier).toggle();
    expect(prefs.getBool('dark_mode'), isTrue);
  });

  testWidgets(
    'Profile toolbar toggles the app theme without resetting navigation',
    (tester) async {
      final container = await pumpLoggedInApp(tester);
      container.read(goRouterProvider).go('/profile');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('切换夜晚模式'));
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(ProfilePage))).brightness,
        Brightness.dark,
      );
      expect(
        container
            .read(goRouterProvider)
            .routerDelegate
            .currentConfiguration
            .uri
            .path,
        '/profile',
      );
      final nav = tester.widget<BottomNavigationBar>(
        find.descendant(
          of: find.byType(AppBottomNav),
          matching: find.byType(BottomNavigationBar),
        ),
      );
      expect(nav.backgroundColor, isNot(Colors.white));
      container.read(goRouterProvider).go('/home');
      await tester.pumpAndSettle();
      final footer = find.byKey(const ValueKey('home-publish-footer'));
      final button = find.widgetWithText(ElevatedButton, '发布吊运需求');
      final viewportWidth =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      expect(tester.getSize(footer).width, viewportWidth);
      expect(tester.getSize(button).width, viewportWidth - 32);
      expect(tester.getTopLeft(footer).dx, 0);
      final footerDecoration =
          tester.widget<Container>(footer).decoration as BoxDecoration;
      expect(footerDecoration.color, nav.backgroundColor);
      container.read(goRouterProvider).go('/profile');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('切换白天模式'));
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(ProfilePage))).brightness,
        Brightness.light,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
