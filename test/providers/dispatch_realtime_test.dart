import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uav_pilot_app/providers/dispatch_realtime_provider.dart';
import 'package:uav_pilot_app/providers/waybill_draft_provider.dart';
import 'package:uav_pilot_app/services/dispatch_realtime.dart';
import 'package:uav_pilot_app/providers/dispatch_order_provider.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/models/dispatch_order.dart';
import 'package:uav_pilot_app/services/token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../dispatch_order_test_support.dart';

class _Source implements DispatchEventSource {
  final streams = <StreamController<String>>[];
  final tokens = <CancelToken>[];
  @override
  Stream<String> connect(CancelToken token) {
    tokens.add(token);
    final stream = StreamController<String>();
    streams.add(stream);
    return stream.stream;
  }

  void close() {
    for (final stream in streams) {
      unawaited(stream.close());
    }
  }
}

class _CancelErrorSource implements DispatchEventSource {
  @override
  Stream<String> connect(CancelToken token) => StreamController<String>(
    onCancel: () async {
      throw DioException(
        requestOptions: RequestOptions(path: '/dispatch/events'),
        type: DioExceptionType.cancel,
        error: 'Inactive',
      );
    },
  ).stream;
}

class _Orders extends FakeDispatchOrderApi {
  _Orders(super.client);
  int calls = 0;
  @override
  Future<List<DispatchOrder>> list() async {
    calls++;
    return [];
  }
}

void main() {
  testWidgets(
    'shared connection batches changes, ignores heartbeat and reconnects after loss',
    (tester) async {
      final source = _Source();
      final notifier = DispatchRealtimeNotifier(source);
      addTearDown(() async {
        if (notifier.mounted) notifier.dispose();
        source.close();
      });
      source.streams.single.add('ready');
      source.streams.single.add('change');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      expect(notifier.state, 1);
      source.streams.single.add('heartbeat');
      await tester.pump(const Duration(seconds: 1));
      expect(notifier.state, 1);
      source.streams.single.addError(StateError('offline'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(source.tokens.first.isCancelled, isTrue);
      expect(source.streams.length, 2);
      source.streams.last.add('ready');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(notifier.state, 2);
      notifier.dispose();
    },
  );

  testWidgets(
    'background cancels connection and pending updates; resume synchronizes',
    (tester) async {
      final source = _Source();
      final notifier = DispatchRealtimeNotifier(source);
      addTearDown(() async {
        if (notifier.mounted) notifier.dispose();
        source.close();
      });
      source.streams.single.add('change');
      await tester.pump();
      notifier.didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 35));
      expect(notifier.state, 0);
      expect(source.tokens.first.isCancelled, isTrue);
      notifier.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(notifier.state, 1);
      expect(source.streams.length, 2);
      notifier.dispose();
    },
  );

  testWidgets(
    'account switch closes old stream and all consumers share one new stream',
    (tester) async {
      final source = _Source();
      final account = StateProvider((ref) => 'a');
      final container = ProviderContainer(
        overrides: [
          dispatchWaybillEnabledProvider.overrideWithValue(true),
          waybillDraftScopeProvider.overrideWith((ref) => ref.watch(account)),
          dispatchEventSourceProvider.overrideWithValue(source),
        ],
      );
      final first = container.listen(dispatchRealtimeProvider, (_, _) {});
      final second = container.listen(dispatchRealtimeProvider, (_, _) {});
      expect(source.streams.length, 1);
      container.read(account.notifier).state = 'b';
      container.read(dispatchRealtimeProvider);
      await tester.pump();
      expect(source.streams.length, 2);
      expect(source.tokens.first.isCancelled, isTrue);
      source.streams.first.add('change');
      await tester.pump(const Duration(milliseconds: 500));
      expect(container.read(dispatchRealtimeProvider), 0);
      first.close();
      second.close();
      await tester.pump(const Duration(milliseconds: 1));
      container.dispose();
      source.close();
      await tester.pump();
      expect(source.tokens.last.isCancelled, isTrue);
    },
  );

  testWidgets('disconnected stream retains slow refresh fallback', (
    tester,
  ) async {
    final source = _Source();
    final notifier = DispatchRealtimeNotifier(source);
    addTearDown(() async {
      if (notifier.mounted) notifier.dispose();
      source.close();
    });
    await tester.pump(const Duration(seconds: 30));
    await tester.pump(const Duration(milliseconds: 200));
    expect(notifier.state, 1);
    source.streams.single.add('ready');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    final current = notifier.state;
    await tester.pump(const Duration(seconds: 31));
    expect(notifier.state, current);
    notifier.dispose();
  });
  testWidgets(
    'order list rereads server on changes without clearing displayed snapshot',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final client = HttpClient(
        TokenStorage(await SharedPreferences.getInstance()),
      );
      final api = _Orders(client);
      final source = _Source();
      final container = ProviderContainer(
        overrides: [
          dispatchWaybillEnabledProvider.overrideWithValue(true),
          waybillDraftScopeProvider.overrideWithValue('a'),
          dispatchEventSourceProvider.overrideWithValue(source),
          dispatchOrderApiProvider.overrideWithValue(api),
        ],
      );
      final subscription = container.listen(dispatchOrdersProvider, (_, _) {});
      await tester.pump();
      expect(api.calls, 1);
      source.streams.single.add('change');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(container.read(dispatchOrdersProvider).hasValue, isTrue);
      await tester.pump();
      expect(api.calls, 2);
      source.streams.single.add('heartbeat');
      await tester.pump(const Duration(seconds: 1));
      expect(api.calls, 2);
      subscription.close();
      await tester.pump(const Duration(milliseconds: 1));
      container.dispose();
      source.close();
      client.dio.close();
      await tester.pump(const Duration(milliseconds: 1));
    },
  );
  testWidgets(
    'background and dispose handle cancellation errors from stream cleanup',
    (tester) async {
      final notifier = DispatchRealtimeNotifier(_CancelErrorSource());
      await tester.pump();
      notifier.didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pump();
      notifier.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();
      notifier.dispose();
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
