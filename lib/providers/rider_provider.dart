import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/rider_api.dart';
import '../models/task_vo.dart';
import 'auth_provider.dart';

final riderApiProvider = Provider<RiderApi>(
  (ref) => RiderApi(ref.watch(httpClientProvider)),
);

// ============================================================
// 任务广场
// ============================================================

class TaskSquareState {
  final List<TaskVo> tasks;
  final bool loading;
  final String? error;

  const TaskSquareState({this.tasks = const [], this.loading = true, this.error});

  TaskSquareState copyWith({List<TaskVo>? tasks, bool? loading, String? error}) {
    return TaskSquareState(
      tasks: tasks ?? this.tasks,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class TaskSquareNotifier extends StateNotifier<TaskSquareState> {
  final RiderApi _api;

  TaskSquareNotifier(this._api) : super(const TaskSquareState()) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final result = await _api.listAvailableTasks();
      if (!result.success || result.data == null) {
        state = state.copyWith(loading: false, error: result.message ?? '加载失败');
        return;
      }
      state = state.copyWith(loading: false, tasks: result.data!.tasks);
    } catch (_) {
      state = state.copyWith(loading: false, error: '加载失败');
    }
  }

  Future<bool> acceptTask(String taskNum) async {
    try {
      final result = await _api.acceptTask(taskNum);
      if (!result.success) {
        state = state.copyWith(error: result.message ?? '接单失败');
        return false;
      }
      state = state.copyWith(
        tasks: state.tasks.where((t) => t.taskNum != taskNum).toList(),
      );
      return true;
    } catch (_) {
      state = state.copyWith(error: '接单失败');
      return false;
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final taskSquareProvider =
    StateNotifierProvider<TaskSquareNotifier, TaskSquareState>(
  (ref) => TaskSquareNotifier(ref.watch(riderApiProvider)),
);

// ============================================================
// 我的接单
// ============================================================

class MyRiderTasksState {
  final List<TaskVo> activeTasks;
  final List<TaskVo> historyTasks;
  final bool loading;
  final String? error;

  const MyRiderTasksState({
    this.activeTasks = const [],
    this.historyTasks = const [],
    this.loading = true,
    this.error,
  });

  MyRiderTasksState copyWith({
    List<TaskVo>? activeTasks,
    List<TaskVo>? historyTasks,
    bool? loading,
    String? error,
  }) {
    return MyRiderTasksState(
      activeTasks: activeTasks ?? this.activeTasks,
      historyTasks: historyTasks ?? this.historyTasks,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class MyRiderTasksNotifier extends StateNotifier<MyRiderTasksState> {
  final RiderApi _api;

  MyRiderTasksNotifier(this._api) : super(const MyRiderTasksState()) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final activeResult = await _api.getMyActiveTasks();
      final historyResult = await _api.getMyAllTasks();
      state = state.copyWith(
        loading: false,
        activeTasks: (activeResult.success && activeResult.data != null) ? activeResult.data!.tasks : [],
        historyTasks: (historyResult.success && historyResult.data != null) ? historyResult.data!.tasks : [],
      );
    } catch (_) {
      state = state.copyWith(loading: false, error: '加载失败');
    }
  }

  Future<bool> cancelTask(String taskNum) async {
    try {
      final result = await _api.cancelTask(taskNum);
      if (!result.success) {
        state = state.copyWith(error: result.message ?? '取消失败');
        return false;
      }
      state = state.copyWith(
        activeTasks: state.activeTasks.where((t) => t.taskNum != taskNum).toList(),
      );
      return true;
    } catch (_) {
      state = state.copyWith(error: '取消失败');
      return false;
    }
  }

  Future<bool> completeTask(String taskNum) async {
    try {
      final result = await _api.completeTask(taskNum);
      if (!result.success) {
        state = state.copyWith(error: result.message ?? '操作失败');
        return false;
      }
      final completed = state.activeTasks.firstWhere((t) => t.taskNum == taskNum);
      state = state.copyWith(
        activeTasks: state.activeTasks.where((t) => t.taskNum != taskNum).toList(),
        historyTasks: [completed, ...state.historyTasks],
      );
      return true;
    } catch (_) {
      state = state.copyWith(error: '操作失败');
      return false;
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final myRiderTasksProvider =
    StateNotifierProvider<MyRiderTasksNotifier, MyRiderTasksState>(
  (ref) => MyRiderTasksNotifier(ref.watch(riderApiProvider)),
);

// ============================================================
// 飞手任务详情
// ============================================================

class RiderTaskDetailState {
  final TaskVo? task;
  final bool loading;
  final String? error;

  const RiderTaskDetailState({this.task, this.loading = true, this.error});

  RiderTaskDetailState copyWith({TaskVo? task, bool? loading, String? error}) {
    return RiderTaskDetailState(
      task: task ?? this.task,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class RiderTaskDetailNotifier extends StateNotifier<RiderTaskDetailState> {
  final RiderApi _api;

  RiderTaskDetailNotifier(this._api) : super(const RiderTaskDetailState());

  Future<bool> acceptTask(String taskNum) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final result = await _api.acceptTask(taskNum);
      if (!result.success) {
        state = state.copyWith(loading: false, error: result.message ?? '接单失败');
        return false;
      }
      state = state.copyWith(loading: false);
      return true;
    } catch (_) {
      state = state.copyWith(loading: false, error: '接单失败');
      return false;
    }
  }

  Future<bool> cancelTask(String taskNum) async {
    try {
      final result = await _api.cancelTask(taskNum);
      if (!result.success) {
        state = state.copyWith(error: result.message ?? '取消失败');
        return false;
      }
      return true;
    } catch (_) {
      state = state.copyWith(error: '取消失败');
      return false;
    }
  }

  Future<bool> completeTask(String taskNum) async {
    try {
      final result = await _api.completeTask(taskNum);
      if (!result.success) {
        state = state.copyWith(error: result.message ?? '操作失败');
        return false;
      }
      return true;
    } catch (_) {
      state = state.copyWith(error: '操作失败');
      return false;
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final riderTaskDetailProvider =
    StateNotifierProvider<RiderTaskDetailNotifier, RiderTaskDetailState>(
  (ref) => RiderTaskDetailNotifier(ref.watch(riderApiProvider)),
);

// ============================================================
// 飞手任务查找（从已加载的列表中按 taskNum 查找）
// ============================================================

TaskVo? riderTaskLookup(WidgetRef ref, String taskNum) {
  final squareState = ref.watch(taskSquareProvider);
  final myState = ref.watch(myRiderTasksProvider);

  for (final t in squareState.tasks) {
    if (t.taskNum == taskNum) return t;
  }
  for (final t in myState.activeTasks) {
    if (t.taskNum == taskNum) return t;
  }
  for (final t in myState.historyTasks) {
    if (t.taskNum == taskNum) return t;
  }
  return null;
}
