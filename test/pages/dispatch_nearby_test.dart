import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/dispatch_nearby_api.dart';
import 'package:uav_pilot_app/api/generated/openapi_models.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/models/amap_config.dart';
import 'package:uav_pilot_app/pages/pilot/dispatch_nearby_page.dart';
import 'package:uav_pilot_app/providers/dispatch_nearby_provider.dart';
import 'package:uav_pilot_app/providers/map_provider.dart';
import 'package:uav_pilot_app/providers/waybill_draft_provider.dart';
import 'package:uav_pilot_app/services/dispatch_location.dart';
import 'package:uav_pilot_app/services/token_storage.dart';
import '../services/dispatch_location_test.dart' show validFix;

class FakeNearbyApi extends DispatchNearbyApi {
  FakeNearbyApi(super.client);
  int updates = 0, clears = 0, halls = 0;
  @override
  Future<String> begin() async => 'session';
  @override
  Future<ApiDispatchPositionVO> update(
    DispatchLocationFix fix,
    String sessionKey,
  ) async {
    updates++;
    return ApiDispatchPositionVO(
      receivedAt: DateTime.now().millisecondsSinceEpoch,
      expiresAt: DateTime.now().millisecondsSinceEpoch + 300000,
      accuracyMeters: 12,
      coordinateSystem: 'GCJ02',
    );
  }

  @override
  Future<void> clear([String? key]) async {
    clears++;
  }

  @override
  Future<ApiDispatchNearbyHallVO> hall(int page) async {
    halls++;
    return ApiDispatchNearbyHallVO(
      items: [],
      page: page,
      hasNext: false,
      radiusKm: 10,
      locationState: 'READY',
    );
  }
}

class DelayedLocation extends DispatchLocation {
  final pending = <Completer<DispatchLocationFix>>[];
  @override
  Future<DispatchLocationFix> locate(String key) {
    final value = Completer<DispatchLocationFix>();
    pending.add(value);
    return value.future;
  }
}

void main() {
  for (final changeAccount in [false, true]) {
    testWidgets(
      changeAccount
          ? 'old account fix cannot upload after account switch'
          : 'late fix after stop cannot upload or show nearby cards',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final client = HttpClient(
          TokenStorage(await SharedPreferences.getInstance()),
        );
        final api = FakeNearbyApi(client), location = DelayedLocation();
        final scope = StateProvider((ref) => 'a');
        final container = ProviderContainer(
          overrides: [
            dispatchNearbyApiProvider.overrideWithValue(api),
            dispatchLocationProvider.overrideWithValue(location),
            amapMapConfigProvider.overrideWith(
              (ref) async => AmapConfig(key: 'test-config', securityKey: ''),
            ),
            waybillDraftScopeProvider.overrideWith((ref) => ref.watch(scope)),
          ],
        );
        addTearDown(() {
          container.dispose();
          client.dio.close();
        });
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: DispatchNearbyPage()),
          ),
        );
        expect(location.pending, isEmpty);
        await tester.tap(find.text('开启附近接单'));
        await tester.pumpAndSettle();
        expect(location.pending.length, 1);
        if (changeAccount) {
          container.read(scope.notifier).state = 'b';
          await tester.pump();
        } else {
          await tester.tap(find.text('停止并清除位置'));
          await tester.pump();
        }
        location.pending.single.complete(
          DispatchLocationFix.fromMap(validFix()),
        );
        await tester.pumpAndSettle();
        expect(api.updates, 0);
        expect(api.halls, 0);
        if (!changeAccount) expect(api.clears, 1);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  testWidgets(
    'background fix is discarded and foreground return requests a new fix',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final client = HttpClient(
        TokenStorage(await SharedPreferences.getInstance()),
      );
      final api = FakeNearbyApi(client), location = DelayedLocation();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dispatchNearbyApiProvider.overrideWithValue(api),
            dispatchLocationProvider.overrideWithValue(location),
            amapMapConfigProvider.overrideWith(
              (ref) async => AmapConfig(key: 'test-config', securityKey: ''),
            ),
            waybillDraftScopeProvider.overrideWithValue('a'),
          ],
          child: const MaterialApp(home: DispatchNearbyPage()),
        ),
      );
      await tester.tap(find.text('开启附近接单'));
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      location.pending.first.complete(DispatchLocationFix.fromMap(validFix()));
      await tester.pumpAndSettle();
      expect(api.updates, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(location.pending.length, 2);
      location.pending.last.complete(DispatchLocationFix.fromMap(validFix()));
      await tester.pumpAndSettle();
      expect(api.updates, 1);
      expect(find.text('本页暂无附近待接订单'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      client.dio.close();
    },
  );
}
