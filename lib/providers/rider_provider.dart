import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/rider_api.dart';
import '../models/task_vo.dart';
import '../models/rider_stats_vo.dart';
import '../models/rider_vo.dart';
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
      // REQ-APP-002: a successful delivery does not depend on this list cache.
      // Detail entry may complete a task absent from the paginated active list.
      state = state.copyWith(
        activeTasks: state.activeTasks
            .where((t) => t.taskNum != taskNum)
            .toList(),
        error: null,
      );
      // Reload authoritative states instead of moving a stale IN_PROGRESS object.
      // loadTasks reports refresh errors separately; they do not undo delivery.
      await loadTasks();
      return true;
    } catch (_) {
      state = state.copyWith(error: '操作失败');
      return false;
    }
  }

  /// 确认订单（POST /rider/confirm-order，ADR-0003 决定 4）：
  /// 确认约定作业时间后用服务端返回的最新 VO 替换本地任务，撮合状态随刷新推进。
  Future<bool> confirmOrder(String taskNum) async {
    try {
      final result = await _api.confirmOrder(taskNum);
      if (!result.success || result.data == null) {
        state = state.copyWith(error: result.message ?? '确认失败');
        return false;
      }
      final updated = result.data!;
      state = state.copyWith(
        activeTasks:
            state.activeTasks.map((t) => t.taskNum == taskNum ? updated : t).toList(),
      );
      return true;
    } catch (_) {
      state = state.copyWith(error: '确认失败');
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

  /// 拉取飞手任务详情（GET /rider/task/detail）：撮合状态、货物字段、
  /// 系统报价与约定时间的权威来源；应征/确认后由调用方重载对齐服务端。
  Future<void> load(String taskNum) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final result = await _api.getTaskDetail(taskNum);
      if (!mounted) return;
      if (!result.success || result.data == null) {
        state = state.copyWith(
          loading: false,
          error: result.message ?? '获取任务详情失败',
        );
        return;
      }
      state = state.copyWith(loading: false, task: result.data);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(loading: false, error: '网络请求失败');
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

// ============================================================
// 飞手统计（当前骑手）
// ============================================================

class RiderStatsState {
  final RiderStatsVo? stats;
  final bool loading;
  final String? error;

  const RiderStatsState({this.stats, this.loading = true, this.error});

  RiderStatsState copyWith({RiderStatsVo? stats, bool? loading, String? error}) {
    return RiderStatsState(
      stats: stats ?? this.stats,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class RiderStatsNotifier extends StateNotifier<RiderStatsState> {
  final RiderApi _api;

  RiderStatsNotifier(this._api) : super(const RiderStatsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final result = await _api.getRiderStats();
      if (result.success && result.data != null) {
        state = state.copyWith(loading: false, stats: result.data);
      } else {
        state = state.copyWith(loading: false, error: result.message ?? '加载失败');
      }
    } catch (_) {
      state = state.copyWith(loading: false, error: '加载失败');
    }
  }
}

final riderStatsProvider =
    StateNotifierProvider<RiderStatsNotifier, RiderStatsState>(
  (ref) => RiderStatsNotifier(ref.watch(riderApiProvider)),
);

// ==== 远端并行功能线：推荐飞手列表（RiderList） ====
class RiderListState {
  final List<RiderVo> riders;
  final bool loading;
  final String? error;

  const RiderListState({this.riders = const [], this.loading = true, this.error});

  RiderListState copyWith({List<RiderVo>? riders, bool? loading, String? error}) {
    return RiderListState(
      riders: riders ?? this.riders,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class RiderListNotifier extends StateNotifier<RiderListState> {
  final RiderApi _api;

  RiderListNotifier(this._api) : super(const RiderListState()) {
    loadRiders();
  }

  Future<void> loadRiders() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final result = await _api.getRecommended();
      if (!result.success || result.data == null) {
        final msg = result.message ?? '加载飞手列表失败';
        state = state.copyWith(loading: false, error: msg);
        return;
      }
      state = state.copyWith(loading: false, riders: result.data!);
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        state = state.copyWith(loading: false, error: '请求未授权(401)，接口可能暂未上线或登录已过期');
      } else {
        state = state.copyWith(loading: false, error: '网络请求失败: $e');
      }
    }
  }
}

final riderListProvider = StateNotifierProvider<RiderListNotifier, RiderListState>(
  (ref) => RiderListNotifier(ref.watch(riderApiProvider)),
);
