import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/task_api.dart';
import '../models/create_task_request.dart';
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

  Future<bool> createTask(CreateTaskRequest request) async {
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
    Future.microtask(() => loadTasks());
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
    state = state.copyWith(loading: true, error: null);
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
  (ref, taskNum) {
    final n = TaskDetailNotifier(ref.watch(taskApiProvider));
    Future.microtask(() => n.loadDetail(taskNum));
    return n;
  },
);
