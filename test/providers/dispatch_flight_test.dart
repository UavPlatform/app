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
  Completer<ApiFlightProjectionVO>? waiting;
  bool fail = false;
  @override
  Future<ApiFlightProjectionVO> current(String id) async {
    if (waiting != null) return waiting!.future;
    if (fail) throw StateError('offline');
    return const ApiFlightProjectionVO(
      stale: false,
      aircraft: [
        ApiAircraft(
          latest: {
            'BATTERY': {
              'payload': {'chargePermille': 0},
            },
            'VELOCITY': {
              'payload': {'speedMmps': 0},
            },
          },
        ),
      ],
    );
  }

  @override
  Future<ApiFlightEventPageVO> track(String id, int after) async =>
      const ApiFlightEventPageVO(items: [], nextAfter: 0, hasNext: false);
}

void main() {
  test(
    'ETA requires fresh flight state and speed from the positioned aircraft',
    () {
      const point = ApiFlightEventVO(
        serialNumber: 'a',
        serialSource: 'FC',
        capturedAt: 10000,
        payload: {'latitudeDegE7': 282000000, 'longitudeDegE7': 1130000000},
      );
      const aircraft = ApiAircraft(
        serialNumber: 'a',
        serialSource: 'FC',
        stale: false,
        latest: {
          'ACTUAL_FLYING_STATE': {
            'payload': {'flying': true},
          },
          'VELOCITY': {
            'capturedAt': 10000,
            'payload': {'speedMmps': 20000},
          },
        },
      );
      const valid = ApiFlightProjectionVO(
        stale: false,
        aircraft: [aircraft],
        lastPosition: point,
      );
      expect(flightEtaSeconds(valid, 1200), 60);
      expect(flightEtaSeconds(valid, 1200, requestFailed: true), isNull);
      expect(flightEtaSeconds(valid, null), isNull);
      expect(
        flightEtaSeconds(
          const ApiFlightProjectionVO(
            stale: true,
            aircraft: [aircraft],
            lastPosition: point,
          ),
          1200,
        ),
        isNull,
      );
      expect(
        flightEtaSeconds(
          const ApiFlightProjectionVO(
            stale: false,
            aircraft: [ApiAircraft(serialNumber: 'b')],
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
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('flight-battery'))).data,
      '0',
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('flight-altitude'))).data,
      '未知',
    );
    expect(find.byTooltip('飞行状态：未知'), findsOneWidget);
    expect(find.byTooltip('轨迹状态：暂无实际位置'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  test('track sorts late points by capture time and splits aircraft swaps', () {
    ApiFlightEventVO point(String serial, int time, int latitude) =>
        ApiFlightEventVO(
          type: 'POSITION',
          serialNumber: serial,
          serialSource: 'FC',
          capturedAt: time,
          payload: {'latitudeDegE7': latitude, 'longitudeDegE7': 1130000000},
        );
    final segments = flightSegments([
      point('a', 2, 282000000),
      point('b', 3, 290000000),
      point('a', 1, 281000000),
    ]);
    expect(segments, hasLength(2));
    expect(segments.first.map((p) => p.latitude), [28.1, 28.2]);
    expect(segments.last.single.latitude, 29);
  });
  test(
    'real zero survives and failed refresh marks retained values stale',
    () async {
      final api = FlightApi();
      final n = DispatchFlightNotifier(api, 'order');
      await n.refresh();
      expect(
        n
            .state
            .current!
            .aircraft!
            .single
            .latest!['BATTERY']['payload']['chargePermille'],
        0,
      );
      expect(
        n
            .state
            .current!
            .aircraft!
            .single
            .latest!['VELOCITY']['payload']['speedMmps'],
        0,
      );
      api.fail = true;
      await n.refresh();
      expect(n.state.error, isNotNull);
      expect(
        n
            .state
            .current!
            .aircraft!
            .single
            .latest!['BATTERY']['payload']['chargePermille'],
        0,
      );
      n.dispose();
    },
  );
  test(
    'late request after account provider disposal cannot update state',
    () async {
      final api = FlightApi()..waiting = Completer<ApiFlightProjectionVO>();
      final n = DispatchFlightNotifier(api, 'order');
      final request = n.refresh();
      n.dispose();
      api.waiting!.complete(const ApiFlightProjectionVO(stale: false));
      await request;
    },
  );
}
