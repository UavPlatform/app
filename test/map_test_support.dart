import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Emulates native channels without adding a second renderer to production.
void mockNativeMaps(WidgetTester tester) {
  final messenger = tester.binding.defaultBinaryMessenger;
  final channels = <MethodChannel>[];
  messenger.setMockMethodCallHandler(SystemChannels.platform_views, (
    call,
  ) async {
    if (call.method == 'create') {
      final args = call.arguments as Map;
      final channel = MethodChannel('com.fuwaki.app/amap/${args['id']}');
      channels.add(channel);
      messenger.setMockMethodCallHandler(channel, (_) async => null);
    }
    return null;
  });
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, null);
    for (final channel in channels) {
      messenger.setMockMethodCallHandler(channel, null);
    }
  });
}
