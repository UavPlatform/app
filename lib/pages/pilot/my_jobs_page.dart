import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../models/task_vo.dart';
import '../../providers/rider_provider.dart';
import '../../providers/chat_provider.dart';

class MyJobsPage extends ConsumerStatefulWidget {
  const MyJobsPage({super.key});

  @override
  ConsumerState<MyJobsPage> createState() => _MyJobsPageState();
}

class _MyJobsPageState extends ConsumerState<MyJobsPage>
    with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myRiderTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的接单'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: '进行中 (${state.activeTasks.length})'),
            const Tab(text: '已完成'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => ref.read(myRiderTasksProvider.notifier).loadTasks(),
        child: const Icon(Icons.refresh),
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, MyRiderTasksState state) {
    if (state.loading && state.activeTasks.isEmpty && state.historyTasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.activeTasks.isEmpty && state.historyTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: AppColors.outlineVariant),
            const SizedBox(height: 16),
            Text(state.error!, style: const TextStyle(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref.read(myRiderTasksProvider.notifier).loadTasks(),
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildTabContent(
          state.activeTasks,
          '暂无进行中的任务',
          '去任务大厅接单吧',
        ),
        _buildTabContent(
          state.historyTasks.where((t) => t.isCompleted).toList(),
          '暂无已完成的任务',
          null,
        ),
      ],
    );
  }

  Widget _buildTabContent(List<TaskVo> tasks, String emptyTitle, String? emptySubtitle) {
    if (tasks.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Center(
            child: Column(
              children: [
                Icon(Icons.assignment_outlined, size: 64,
                    color: AppColors.outlineVariant.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(emptyTitle,
                    style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 16)),
                if (emptySubtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(emptySubtitle,
                      style: const TextStyle(color: AppColors.outline, fontSize: 13)),
                ],
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) => _buildCard(context, tasks[index]),
    );
  }

  Widget _buildCard(BuildContext context, TaskVo task) {
    final isActive = task.isInProgress;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.statusInProgress : AppColors.statusCompleted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isActive ? '执行中' : '已完成',
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive ? AppColors.statusInProgressText : AppColors.statusCompletedText,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.taskTypeName,
                    style: const TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                ),
                const Spacer(),
                Text(
                  task.priceText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              task.taskName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                task.description!,
                style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            _infoRow(Icons.tag_outlined, '编号: ${task.taskNum}'),
            if (task.totalDistance != null && task.totalDistance! > 0) ...[
              const SizedBox(height: 6),
              _infoRow(Icons.route_outlined, '距离: ${task.totalDistance!.toStringAsFixed(0)} m'),
            ],
            const SizedBox(height: 6),
            _infoRow(Icons.access_time, task.formattedCreateTime),
            if (isActive) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _onChat(context, task),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('联系用户'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _onCancel(context, task),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('取消接单'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _onComplete(context, task),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('完成任务'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _onCancel(BuildContext context, TaskVo task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认取消'),
        content: Text('确定要取消「${task.taskName}」的接单吗？\n取消后任务将回到任务广场。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('再想想')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确定取消', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final notifier = ref.read(myRiderTasksProvider.notifier);
    final ok = await notifier.cancelTask(task.taskNum);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '已取消接单' : ref.read(myRiderTasksProvider).error ?? '取消失败')),
    );
  }

  Future<void> _onChat(BuildContext context, TaskVo task) async {
    try {
      final result = await ref.read(chatApiProvider).createSession(
        name: '${task.taskTypeName} - ${task.taskName}',
        type: 0,
        userIds: [task.userId],
      );
      if (result.success && result.data != null && context.mounted) {
        ref.read(sessionListProvider.notifier).load();
        final chatName = result.data!.otherUserName ?? '${task.taskTypeName} - ${task.taskName}';
        context.push('/chat/${result.data!.id}?name=${Uri.encodeComponent(chatName)}');
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? '创建会话失败')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('创建会话失败')),
        );
      }
    }
  }

  Future<void> _onComplete(BuildContext context, TaskVo task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认完成'),
        content: Text('确定「${task.taskName}」已经完成了吗？\n完成后将通知用户确认收货。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('再等等')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('确认完成'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final notifier = ref.read(myRiderTasksProvider.notifier);
    final ok = await notifier.completeTask(task.taskNum);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '任务已完成，等待用户确认' : ref.read(myRiderTasksProvider).error ?? '操作失败')),
    );
  }
}
