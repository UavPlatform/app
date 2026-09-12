// 直播播放器生命周期测试（t38⑤：进房/绑画面/退出/结束信号，假引擎驱动）。

import 'package:flutter_test/flutter_test.dart';
import 'package:uav_pilot_app/services/live_player.dart';

import '../test_support.dart';

void main() {
  LiveStreamSession fixtureSession() => const LiveStreamSession(
        sdkAppId: 1400000000,
        strRoomId: 'drone_UAV-001',
        userId: '7',
        userSig: 'sig',
      );

  group('LivePlayerController 生命周期（t38⑤）', () {
    test('enter → playing，引擎收到进房参数', () async {
      final engine = FakeTrtcEngine();
      final controller = LivePlayerController(engine: engine);
      addTearDown(controller.dispose);

      await controller.enter(fixtureSession());

      expect(controller.phase, LivePlayerPhase.playing);
      expect(engine.entered, hasLength(1));
      expect(engine.entered.single.strRoomId, 'drone_UAV-001');
      expect(engine.entered.single.userId, '7');
      expect(engine.entered.single.sdkAppId, 1400000000);
    });

    test('playing 后绑定画面 → 引擎 attach；idle 时绑定被忽略', () async {
      final engine = FakeTrtcEngine();
      final controller = LivePlayerController(engine: engine);
      addTearDown(controller.dispose);

      // idle 阶段绑定被忽略
      await controller.attachView(1);
      expect(engine.attachedViewIds, isEmpty);

      await controller.enter(fixtureSession());
      await controller.attachView(1);
      expect(engine.attachedViewIds, hasLength(1));
      expect(engine.attachedViewIds.single, 1);
    });

    test('leave → 解绑并退房，相位 exited，重复 leave 幂等', () async {
      final engine = FakeTrtcEngine();
      final controller = LivePlayerController(engine: engine);
      addTearDown(controller.dispose);

      await controller.enter(fixtureSession());
      await controller.attachView(1);
      await controller.leave();

      expect(controller.phase, LivePlayerPhase.exited);
      expect(engine.detachCalls, 1);
      expect(engine.exitCalls, 1);

      await controller.leave();
      expect(engine.exitCalls, 1, reason: '重复退出幂等');
    });

    test('远端停流事件触发 onEnded（直播结束信号）', () async {
      final engine = FakeTrtcEngine();
      final controller = LivePlayerController(engine: engine);
      addTearDown(controller.dispose);
      var endedCount = 0;
      controller.onEnded.listen((_) => endedCount += 1);

      await controller.enter(fixtureSession());
      engine.emitRemoteVideoUnavailable();
      await Future<void>.delayed(Duration.zero);

      expect(endedCount, 1);
    });

    test('onExitRoom 事件同样触发 onEnded', () async {
      final engine = FakeTrtcEngine();
      final controller = LivePlayerController(engine: engine);
      addTearDown(controller.dispose);
      var endedCount = 0;
      controller.onEnded.listen((_) => endedCount += 1);

      await controller.enter(fixtureSession());
      engine.emitExited();
      await Future<void>.delayed(Duration.zero);

      expect(endedCount, 1);
    });

    test('enter 失败 → 相位回到 exited 并抛出', () async {
      final engine = FakeTrtcEngine()..failEnter = true;
      final controller = LivePlayerController(engine: engine);
      addTearDown(controller.dispose);

      await expectLater(
        controller.enter(fixtureSession()),
        throwsA(isA<StateError>()),
      );
      expect(controller.phase, LivePlayerPhase.exited);
    });

    test('leave 后可重新 enter（重进直播间）', () async {
      final engine = FakeTrtcEngine();
      final controller = LivePlayerController(engine: engine);
      addTearDown(controller.dispose);

      await controller.enter(fixtureSession());
      await controller.leave();
      await controller.enter(fixtureSession());

      expect(controller.phase, LivePlayerPhase.playing);
      expect(engine.entered, hasLength(2));
    });
  });
}
