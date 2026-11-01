import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/dispatch_nearby_api.dart';
import 'package:uav_pilot_app/api/generated/openapi_models.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/providers/dispatch_nearby_provider.dart';
import 'package:uav_pilot_app/services/token_storage.dart';

ApiDispatchNearbyOfferVO _offer(String id) => ApiDispatchNearbyOfferVO(
  distanceMeters: 10,
  offer: ApiDispatchOfferVO(
    orderId: id,
    offerRevision: 1,
    fields: const {'category': 'x', 'start.site': 'a', 'end.site': 'b'},
    pilotServiceFee: 1,
  ),
);

class _FakeNearbyApi extends DispatchNearbyApi {
  _FakeNearbyApi(super.client);
  final requested = <int>[];
  Completer<void>? gate;
  Map<int, ApiDispatchNearbyHallVO> pages = {};

  @override
  Future<ApiDispatchNearbyHallVO> hall(int page) async {
    requested.add(page);
    final hold = gate;
    if (hold != null) await hold.future;
    return pages[page]!;
  }
}

void main() {
  test('nearby refresh during load-more is queued and replaces list', () async {
    SharedPreferences.setMockInitialValues({});
    final client = HttpClient(
      TokenStorage(await SharedPreferences.getInstance()),
    );
    addTearDown(() => client.dio.close());
    final api = _FakeNearbyApi(client);
    api.pages = {
      0: ApiDispatchNearbyHallVO(
        items: [_offer('old-0')],
        page: 0,
        hasNext: true,
        radiusKm: 10,
        locationState: 'READY',
        locationExpiresAt: DateTime.now().millisecondsSinceEpoch + 60000,
      ),
      1: ApiDispatchNearbyHallVO(
        items: [_offer('old-1')],
        page: 1,
        hasNext: false,
        radiusKm: 10,
        locationState: 'READY',
        locationExpiresAt: DateTime.now().millisecondsSinceEpoch + 60000,
      ),
    };
    final notifier = DispatchNearbyHallNotifier(api);
    addTearDown(notifier.dispose);

    await notifier.load();
    expect(
      notifier.state.items.map((e) => e.offer!.orderId),
      ['old-0'],
    );

    final hold = Completer<void>();
    api.gate = hold;
    final append = notifier.load();
    await Future<void>.delayed(Duration.zero);
    expect(notifier.state.loading, isTrue);

    api.pages[0] = ApiDispatchNearbyHallVO(
      items: [_offer('fresh-0')],
      page: 0,
      hasNext: false,
      radiusKm: 10,
      locationState: 'READY',
      locationExpiresAt: DateTime.now().millisecondsSinceEpoch + 60000,
    );
    unawaited(notifier.load(refresh: true));
    expect(api.requested, [0, 1]);

    hold.complete();
    await append;
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    while (notifier.state.loading) {
      await Future<void>.delayed(Duration.zero);
    }

    expect(api.requested, [0, 1, 0]);
    expect(
      notifier.state.items.map((e) => e.offer!.orderId),
      ['fresh-0'],
    );
    expect(notifier.state.hasNext, isFalse);
  });
}
