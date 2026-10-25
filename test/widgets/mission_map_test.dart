import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:uav_pilot_app/models/amap_config.dart';
import 'package:uav_pilot_app/providers/map_provider.dart';
import 'package:uav_pilot_app/widgets/mission_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Native map keeps independent view state, forwards taps, updates points and supports satellite/night modes',
    (tester) async {
      final controller = MissionMapController();
      final creates = <Map>[];
      final commands = <MethodCall>[];
      final channels = <MethodChannel>[];
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform_views, (
        call,
      ) async {
        if (call.method == 'create') {
          final args = call.arguments as Map;
          creates.add(args);
          final channel = MethodChannel('com.fuwaki.app/amap/${args['id']}');
          channels.add(channel);
          messenger.setMockMethodCallHandler(channel, (call) async {
            commands.add(call);
            return null;
          });
        }
        return null;
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(SystemChannels.platform_views, null);
        for (final channel in channels) {
          messenger.setMockMethodCallHandler(channel, null);
        }
        controller.dispose();
      });
      final overrides = [
        amapMapConfigProvider.overrideWith(
          (ref) async => AmapConfig(key: 'test-key'),
        ),
      ];
      LatLng? tapped;
      double? remaining;
      String? selectedOrder;
      Future<void> pumpMap({
        LatLng? destination,
        Brightness brightness = Brightness.light,
        bool flight = false,
      }) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: MaterialApp(
              theme: ThemeData(brightness: brightness),
              home: Scaffold(
                body: MissionMap(
                  controller: controller,
                  center: const LatLng(27, 112),
                  start: const LatLng(27, 112),
                  destination: destination,
                  aircraft: flight ? const LatLng(28.2, 113.0) : null,
                  aircraftCoordinatesAreGps: flight,
                  tracks: flight
                      ? const [
                          [LatLng(28.1, 113.0), LatLng(28.2, 113.0)],
                        ]
                      : const [],
                  orderMarkers: const [
                    MissionOrderMarker(
                      id: 'order-start',
                      point: LatLng(27, 112),
                      label: '等待接单',
                      color: Colors.orange,
                      selected: true,
                    ),
                  ],
                  onOrderMarkerTap: (id) => selectedOrder = id,
                  onRemainingDistance: (meters) => remaining = meters,
                  onTap: (point) => tapped = point,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await pumpMap();
      expect(creates.single['viewType'], 'com.fuwaki.app/amap');
      expect(creates.single['hybrid'], true);
      expect(find.byType(PlatformViewLink), findsOneWidget);
      await messenger.handlePlatformMessage(
        channels.single.name,
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('tap', {'latitude': 28.0, 'longitude': 113.0}),
        ),
        (_) {},
      );
      expect(tapped, const LatLng(28, 113));
      await messenger.handlePlatformMessage(
        channels.single.name,
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('orderMarkerTap', 'order-start'),
        ),
        (_) {},
      );
      expect(selectedOrder, 'order-start');
      expect((commands.last.arguments as Map)['orderMarkers'], hasLength(1));
      await controller.fit(const [
        LatLng(27, 112),
        LatLng(28, 113),
      ], bottomInset: 240);
      expect(commands.last.method, 'fit');
      expect((commands.last.arguments as Map)['points'], hasLength(2));
      expect((commands.last.arguments as Map)['bottomInset'], 240);
      await tester.tap(find.byKey(const ValueKey('map-type-toggle')));
      await tester.pumpAndSettle();
      expect((commands.last.arguments as Map)['satellite'], true);
      await pumpMap(
        destination: const LatLng(28, 113),
        brightness: Brightness.dark,
        flight: true,
      );
      expect(
        creates.length,
        1,
        reason: 'Updating points/theme must not recreate the renderer',
      );
      expect((commands.last.arguments as Map)['destination'], {
        'latitude': 28.0,
        'longitude': 113.0,
      });
      expect((commands.last.arguments as Map)['dark'], true);
      expect(
        (commands.last.arguments as Map)['aircraftCoordinatesAreGps'],
        true,
      );
      expect((commands.last.arguments as Map)['tracks'], hasLength(1));
      await messenger.handlePlatformMessage(
        channels.single.name,
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('remainingDistance', 123.5),
        ),
        (_) {},
      );
      expect(remaining, 123.5);
      await controller.move(const LatLng(28, 113), 17, gps: true);
      expect(commands.last.method, 'move');
      expect((commands.last.arguments as Map)['zoom'], 17);
      expect((commands.last.arguments as Map)['centerIsGps'], true);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Native configuration failures show retry without creating a map',
    (tester) async {
      final controller = MissionMapController();
      addTearDown(controller.dispose);
      var attempts = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            amapMapConfigProvider.overrideWith((ref) async {
              attempts++;
              throw StateError('config failed');
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MissionMap(
                controller: controller,
                center: const LatLng(27, 112),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('地图服务暂不可用'), findsOneWidget);
      expect(find.byType(PlatformViewLink), findsNothing);
      await tester.tap(find.text('重试'));
      await tester.pumpAndSettle();
      expect(attempts, 2);
    },
  );
}
