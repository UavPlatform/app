import 'dart:async';
import 'package:uav_pilot_app/api/dispatch_live_api.dart';
import 'package:uav_pilot_app/pages/waybill/dispatch_live_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uav_pilot_app/providers/waybill_draft_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uav_pilot_app/api/dispatch_flight_api.dart';
import 'package:uav_pilot_app/api/generated/openapi_models.dart';
import 'package:uav_pilot_app/providers/dispatch_flight_provider.dart';
import 'package:uav_pilot_app/pages/waybill/dispatch_flight_panel.dart';

class NoLive extends Fake implements DispatchLiveApi {
  @override
  Future<ApiDispatchLiveStatusVO> status(String id) async =>
      const ApiDispatchLiveStatusVO(configured: false, state: 'UNAVAILABLE');
}

class FlightApi extends Fake implements DispatchFlightApi {
  Completer<ApiFlightViewVO>? waiting;
  bool fail = false;
  @override
  Future<ApiFlightViewVO> current(String id) async {
    if (waiting != null) return waiting!.future;
    if (fail) throw StateError('offline');
    return const ApiFlightViewVO(
      stale: false,
      latest: ApiFlightSampleVO(battery: 0, speed: 0),
    );
  }

  @override
  Future<ApiFlightTrackVO> track(String id, int after) async =>
      const ApiFlightTrackVO(items: [], nextAfter: 0, hasNext: false);
}

void main() {
  test(
    'ETA uses fresh actual position/speed and never estimates a stopped or disconnected aircraft',
    () {
      const point = ApiFlightSampleVO(
        sampleId: 1,
        connectionId: 'c',
        latitude: 28.2,
        longitude: 113,
        speed: 20,
        flying: true,
      );
      const valid = ApiFlightViewVO(
        stale: false,
        connection: ApiFlightConnectionVO(connectionId: 'c'),
        latest: point,
        lastPosition: point,
      );
      expect(flightEtaSeconds(valid, 1200), 60);
      expect(flightEtaSeconds(valid, 1200, requestFailed: true), isNull);
      expect(
        flightEtaSeconds(const ApiFlightViewVO(stale: true), 1200),
        isNull,
      );
      expect(flightEtaSeconds(valid, null), isNull);
      expect(
        flightEtaSeconds(
          const ApiFlightViewVO(
            stale: false,
            latest: ApiFlightSampleVO(speed: 0, flying: false),
          ),
          1200,
        ),
        isNull,
      );
      expect(
        flightEtaSeconds(
          const ApiFlightViewVO(
            stale: false,
            connection: ApiFlightConnectionVO(connectionId: 'new'),
            latest: point,
            lastPosition: point,
          ),
          1200,
        ),
        isNull,
      );
    },
  );
  testWidgets('telemetry renders actual zero and missing data differently', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          waybillDraftScopeProvider.overrideWithValue('flight-test'),
          dispatchFlightApiProvider.overrideWithValue(FlightApi()),
          dispatchLiveApiProvider.overrideWithValue(NoLive()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: DispatchFlightPanel(orderId: 'order')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('电量：0 %'), findsOneWidget);
    expect(find.text('相对起飞点高度：未知'), findsOneWidget);
    expect(find.text('飞行状态：未知'), findsOneWidget);
    expect(find.text('尚无本单实际位置，不绘制轨迹'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  test('swap segments never join devices and late points sort by sequence', () {
    final segments = flightSegments(const [
      ApiFlightSampleVO(
        connectionId: 'a',
        sequence: 2,
        latitude: 28.2,
        longitude: 113,
      ),
      ApiFlightSampleVO(
        connectionId: 'b',
        sequence: 0,
        latitude: 29,
        longitude: 114,
      ),
      ApiFlightSampleVO(
        connectionId: 'a',
        sequence: 1,
        latitude: 28.1,
        longitude: 113,
      ),
      ApiFlightSampleVO(connectionId: 'a', sequence: 3),
    ]);
    expect(segments, hasLength(2));
    expect(segments.first.map((p) => p.latitude), [28.1, 28.2]);
    expect(segments.last, hasLength(1));
  });
  test(
    'real zero survives and failed refresh marks retained values stale',
    () async {
      final api = FlightApi();
      final n = DispatchFlightNotifier(api, 'order');
      await n.refresh();
      expect(n.state.current!.latest!.battery, 0);
      expect(n.state.current!.latest!.speed, 0);
      api.fail = true;
      await n.refresh();
      expect(n.state.error, isNotNull);
      expect(n.state.current!.latest!.battery, 0);
      n.dispose();
    },
  );
  test(
    'late request after account provider disposal cannot update state',
    () async {
      final api = FlightApi()..waiting = Completer<ApiFlightViewVO>();
      final n = DispatchFlightNotifier(api, 'order');
      final request = n.refresh();
      n.dispose();
      api.waiting!.complete(const ApiFlightViewVO(stale: false));
      await request;
    },
  );
}
