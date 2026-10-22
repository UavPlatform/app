// REQ-APP-002: a committed delivery must not fail because a list cache is empty.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/api/rider_api.dart';
import 'package:uav_pilot_app/providers/rider_provider.dart';
import 'package:uav_pilot_app/services/token_storage.dart';

import '../test_support.dart';

Future<void> waitLoaded(MyRiderTasksNotifier notifier) async {
  final loaded = Completer<void>();
  final remove = notifier.addListener((state) {
    if (!state.loading && !loaded.isCompleted) loaded.complete();
  });
  try {
    await loaded.future.timeout(const Duration(seconds: 5));
  } finally {
    remove();
  }
}

void main() {
  Future<({RiderApi api, MyRiderTasksNotifier notifier})> setup({
    bool cached = false,
    bool refreshFails = false,
    bool completionFails = false,
  }) async {
    SharedPreferences.setMockInitialValues({
      'server_url': 'http://stub.local:8081',
    });
    final prefs = await SharedPreferences.getInstance();
    var delivered = false;
    Map<String, dynamic> task(bool completed) => {
      'id': 1,
      'taskNum': 'T1',
      'taskName': '吊运任务',
      'userId': 7,
      'taskType': 'TRANSPORT',
      'taskStatus': completed ? 'COMPLETED' : 'IN_PROGRESS',
      'matchStatus': completed ? 'PENDING_ACCEPTANCE' : 'CONFIRMED',
    };
    final client = HttpClient(
      TokenStorage(prefs),
      adapter: StubAdapter((options) async {
        if (options.uri.path == '/rider/complete') {
          expect(options.queryParameters['taskNum'], 'T1');
          if (completionFails) {
            return jsonResponse(400, {
              'success': false,
              'code': 400,
              'errorCode': 'DELIVERY_EVIDENCE_REQUIRED',
              'message': '请先上传履约证据',
            });
          }
          delivered = true;
          return jsonResponse(200, {
            'success': true,
            'code': 200,
            'message': '任务已完成',
            'data': null,
          });
        }
        if (options.uri.path == '/rider/my-tasks' ||
            options.uri.path == '/rider/my-tasks/history') {
          if (delivered && refreshFails) {
            return jsonResponse(503, {'success': false, 'message': '列表暂不可用'});
          }
          final history = options.uri.path.endsWith('/history');
          final tasks = history
              ? (delivered ? [task(true)] : <Map<String, dynamic>>[])
              : (!delivered && cached
                    ? [task(false)]
                    : <Map<String, dynamic>>[]);
          return jsonResponse(200, {
            'success': true,
            'code': 200,
            'data': {
              'tasks': tasks,
              'currentPage': 1,
              'totalPages': 1,
              'totalElements': tasks.length,
            },
          });
        }
        throw StateError('Unexpected request: ${options.uri.path}');
      }),
    );
    addTearDown(() => client.dio.close(force: true));
    final api = RiderApi(client);
    final notifier = MyRiderTasksNotifier(api);
    addTearDown(notifier.dispose);
    await waitLoaded(notifier);
    return (api: api, notifier: notifier);
  }

  test('API accepts success=true with data=null', () async {
    final fixture = await setup();
    final result = await fixture.api.completeTask('T1');
    expect(result.success, isTrue);
  });

  test(
    'detail entry succeeds even when task is absent from list cache',
    () async {
      final fixture = await setup();
      expect(fixture.notifier.state.activeTasks, isEmpty);
      expect(await fixture.notifier.completeTask('T1'), isTrue);
      expect(fixture.notifier.state.error, isNull);
      expect(
        fixture.notifier.state.historyTasks.single.matchStatus,
        'PENDING_ACCEPTANCE',
      );
    },
  );

  test('cached task refreshes to server pending acceptance status', () async {
    final fixture = await setup(cached: true);
    expect(await fixture.notifier.completeTask('T1'), isTrue);
    expect(fixture.notifier.state.activeTasks, isEmpty);
    expect(fixture.notifier.state.historyTasks, hasLength(1));
    expect(fixture.notifier.state.historyTasks.single.taskStatus, 'COMPLETED');
    expect(
      fixture.notifier.state.historyTasks.single.matchStatus,
      'PENDING_ACCEPTANCE',
    );
  });

  test(
    'refresh failure does not turn successful completion into failure',
    () async {
      final fixture = await setup(refreshFails: true);
      expect(await fixture.notifier.completeTask('T1'), isTrue);
      expect(fixture.notifier.state.error, isNot('操作失败'));
    },
  );

  test(
    'missing evidence remains a failure and preserves the cached task',
    () async {
      final fixture = await setup(cached: true, completionFails: true);
      expect(await fixture.notifier.completeTask('T1'), isFalse);
      expect(fixture.notifier.state.activeTasks, hasLength(1));
      expect(fixture.notifier.state.historyTasks, isEmpty);
      expect(fixture.notifier.state.error, contains('上传'));
    },
  );
}
