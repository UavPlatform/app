import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uav_pilot_app/widgets/double_back_exit_dispatcher.dart';

void main() {
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  testWidgets('only the second root back within the window requests exit', (
    tester,
  ) async {
    var prompts = 0, exits = 0;
    final dispatcher = DoubleBackExitDispatcher(
      showPrompt: () => prompts++,
      onExit: () async {
        exits++;
      },
    );
    expect(await dispatcher.didPopRoute(), isTrue);
    expect(prompts, 1);
    expect(exits, 0);
    expect(await dispatcher.didPopRoute(), isTrue);
    expect(exits, 1);
    dispatcher.close();
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets(
    'timeout, route changes and backgrounding reset exit confirmation',
    (tester) async {
      var prompts = 0, exits = 0;
      final dispatcher = DoubleBackExitDispatcher(
        showPrompt: () => prompts++,
        onExit: () async {
          exits++;
        },
      );
      await dispatcher.didPopRoute();
      await tester.pump(const Duration(milliseconds: 2100));
      await dispatcher.didPopRoute();
      expect(prompts, 2);
      expect(exits, 0);
      dispatcher.reset();
      await dispatcher.didPopRoute();
      expect(prompts, 3);
      dispatcher.didChangeAppLifecycleState(AppLifecycleState.paused);
      await dispatcher.didPopRoute();
      expect(prompts, 4);
      expect(exits, 0);
      dispatcher.close();
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets('a handled child back never arms root exit', (tester) async {
    var handled = false;
    var prompts = 0, exits = 0;
    final dispatcher = DoubleBackExitDispatcher(
      showPrompt: () => prompts++,
      onExit: () async {
        exits++;
      },
    );
    Future<bool> popChild() async => handled;
    dispatcher.addCallback(popChild);
    await dispatcher.didPopRoute();
    handled = true;
    await dispatcher.didPopRoute();
    handled = false;
    await dispatcher.didPopRoute();
    expect(prompts, 2);
    expect(exits, 0);
    dispatcher.removeCallback(popChild);
    dispatcher.close();
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets(
    'non-Android platforms retain the default unhandled-back behavior',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      var prompts = 0;
      final dispatcher = DoubleBackExitDispatcher(showPrompt: () => prompts++);
      expect(await dispatcher.didPopRoute(), isFalse);
      expect(prompts, 0);
      dispatcher.close();
      debugDefaultTargetPlatformOverride = null;
    },
  );
}
