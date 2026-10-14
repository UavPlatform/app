import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/generated/openapi_models.dart';
import '../api/task_api.dart';
import '../models/task_application_vo.dart';
import '../models/task_vo.dart';
import 'auth_provider.dart';

final taskApiProvider = Provider<TaskApi>(
  (ref) => TaskApi(ref.watch(httpClientProvider)),
);

// ============================================================
// 创建任务
// ============================================================

class CreateTaskState {
  final bool loading;
  final TaskVo? task;
  final String? error;

  const CreateTaskState({this.loading = false, this.task, this.error});

  CreateTaskState copyWith({bool? loading, TaskVo? task, String? error}) {
    return CreateTaskState(
      loading: loading ?? this.loading,
      task: task ?? this.task,
      error: error,
    );
  }
}

class TaskNotifier extends StateNotifier<CreateTaskState> {
  final TaskApi _api;

  TaskNotifier(this._api) : super(const CreateTaskState());

  Future<bool> createTask(ApiTaskDto request) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final result = await _api.createTask(request);
      if (!result.success || result.data == null) {
        state = state.copyWith(loading: false, error: result.message ?? '创建任务失败');
        return false;
      }
      state = state.copyWith(loading: false, task: result.data!);
      return true;
    } catch (_) {
      state = state.copyWith(loading: false, error: '网络请求失败');
      return false;
    }
  }

  void reset() {
    state = const CreateTaskState();
  }
}

final taskProvider = StateNotifierProvider<TaskNotifier, CreateTaskState>(
  (ref) => TaskNotifier(ref.watch(taskApiProvider)),
);

// ============================================================
// 任务列表
// ============================================================

class TaskListState {
  final List<TaskVo> tasks;
  final bool loading;
  final String? error;

  const TaskListState({this.tasks = const [], this.loading = true, this.error});

  TaskListState copyWith({List<TaskVo>? tasks, bool? loading, String? error}) {
    return TaskListState(
      tasks: tasks ?? this.tasks,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class TaskListNotifier extends StateNotifier<TaskListState> {
  final TaskApi _api;

  TaskListNotifier(this._api) : super(const TaskListState()) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final result = await _api.listTasks();
      if (!result.success || result.data == null) {
        state = state.copyWith(loading: false, error: result.message ?? '获取任务列表失败');
        return;
      }
      state = state.copyWith(loading: false, tasks: result.data!.tasks);
    } catch (_) {
      state = state.copyWith(loading: false, error: '加载失败');
    }
  }

  Future<bool> deleteTask(int taskId) async {
    try {
      final result = await _api.deleteTask(taskId);
      if (!result.success) {
        state = state.copyWith(error: result.message ?? '删除失败');
        return false;
      }
      state = state.copyWith(tasks: state.tasks.where((t) => t.id != taskId).toList());
      return true;
    } catch (_) {
      state = state.copyWith(error: '删除失败');
      return false;
    }
  }

  Future<bool> confirmTask(String taskNum) async {
    try {
      final result = await _api.confirmTask(taskNum);
      if (!result.success) {
        state = state.copyWith(error: result.message ?? '确认失败');
        return false;
      }
      await loadTasks();
      return true;
    } catch (_) {
      state = state.copyWith(error: '确认失败');
      return false;
    }
  }
}

final taskListProvider = StateNotifierProvider<TaskListNotifier, TaskListState>(
  (ref) => TaskListNotifier(ref.watch(taskApiProvider)),
);

// ============================================================
// 任务详情
// ============================================================

class TaskDetailState {
  final TaskVo? task;
  final bool loading;
  final String? error;

  const TaskDetailState({this.task, this.loading = true, this.error});

  TaskDetailState copyWith({TaskVo? task, bool? loading, String? error}) {
    return TaskDetailState(
      task: task ?? this.task,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class TaskDetailNotifier extends StateNotifier<TaskDetailState> {
  final TaskApi _api;

  TaskDetailNotifier(this._api) : super(const TaskDetailState());

  Future<void> loadDetail(String taskNum) async {
    // 已有详情时静默刷新：不回到 loading 态。否则详情页会整页换成转圈，
    // 页内正在 await 的回调（如「选定飞手 → 进入收银台」）的 context 随之卸载，
    // 后续导航被 `context.mounted` 静默吞掉（演示走查实测：选定后不进收银台）。
    state = state.copyWith(loading: state.task == null, error: null);
    try {
      final result = await _api.getTaskDetail(taskNum);
      if (!result.success || result.data == null) {
        state = state.copyWith(loading: false, error: result.message ?? '获取任务详情失败');
        return;
      }
      state = state.copyWith(loading: false, task: result.data!);
    } catch (_) {
      state = state.copyWith(loading: false, error: '加载失败');
    }
  }

  Future<bool> deleteTask(int taskId) async {
    try {
      final result = await _api.deleteTask(taskId);
      if (!result.success) {
        state = state.copyWith(error: result.message ?? '删除失败');
        return false;
      }
      return true;
    } catch (_) {
      state = state.copyWith(error: '删除失败');
      return false;
    }
  }

  Future<bool> confirmTask(String taskNum) async {
    try {
      final result = await _api.confirmTask(taskNum);
      if (!result.success) {
        state = state.copyWith(error: result.message ?? '确认失败');
        return false;
      }
      await loadDetail(taskNum);
      return true;
    } catch (_) {
      state = state.copyWith(error: '确认失败');
      return false;
    }
  }
}

final taskDetailProvider =
    StateNotifierProvider.family<TaskDetailNotifier, TaskDetailState, String>(
  (ref, taskNum) => TaskDetailNotifier(ref.watch(taskApiProvider))
    ..loadDetail(taskNum),
);

// ============================================================
// 应征列表（订单详情 = 撮合中心，ADR-0003）
// ============================================================

class TaskApplicationsState {
  final List<TaskApplicationVo> applications;
  final bool loading;
  final String? error;

  const TaskApplicationsState({
    this.applications = const [],
    this.loading = true,
    this.error,
  });

  TaskApplicationsState copyWith({
    List<TaskApplicationVo>? applications,
    bool? loading,
    String? error,
  }) {
    return TaskApplicationsState(
      applications: applications ?? this.applications,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class TaskApplicationsNotifier extends StateNotifier<TaskApplicationsState> {
  final TaskApi _api;
  final String taskNum;

  TaskApplicationsNotifier(this._api, this.taskNum)
      : super(const TaskApplicationsState()) {
    load();
  }

  bool _loadedOnce = false;

  Future<void> load() async {
    // 首次加载才展示 loading；刷新时保留现有列表，避免应征卡片整体卸载重建。
    state = state.copyWith(loading: !_loadedOnce, error: null);
    try {
      final result = await _api.listApplications(taskNum);
      _loadedOnce = true;
      if (!mounted) return;
      if (result.success && result.data != null) {
        state = state.copyWith(loading: false, applications: result.data!);
      } else {
        state = state.copyWith(
          loading: false,
          error: result.message ?? '获取应征列表失败',
        );
      }
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(loading: false, error: '网络请求失败');
    }
  }
}

/// 撮合应征列表：autoDispose 保证每次进入详情页都重新拉取，
/// 飞手应征后用户重进页面即可看到新应征（配合页内下拉刷新）。
final taskApplicationsProvider = StateNotifierProvider.autoDispose.family<
    TaskApplicationsNotifier, TaskApplicationsState, String>(
  (ref, taskNum) =>
      TaskApplicationsNotifier(ref.watch(taskApiProvider), taskNum),
);

// ============================================================
// 履约证据计数（TASK-APP-004：证据列表驱动「确认完成」按钮显隐）
// ============================================================

/// 任务履约证据条数（GET /tasks/{taskNum}/attachments 成功后由
/// DeliverablesSection 写入）：0 = 明确无证据（禁用确认完成），
/// null = 尚未加载成功（交由服务端 DELIVERY_EVIDENCE_REQUIRED 兜底）。
final taskEvidenceCountProvider =
    StateProvider.autoDispose.family<int?, String>((ref, taskNum) => null);
