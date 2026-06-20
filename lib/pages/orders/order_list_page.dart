import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../models/task_vo.dart';
import '../../providers/task_provider.dart';

class OrderListPage extends ConsumerStatefulWidget {
  const OrderListPage({super.key});

  @override
  ConsumerState<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends ConsumerState<OrderListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tabs = ['全部', '空闲中', '执行中', '已完成'];
  final _statusFilters = [null, 'IDLE', 'IN_PROGRESS', 'COMPLETED'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskListProvider);
    final tasks = state.tasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的任务'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.primary,
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => ref.read(taskListProvider.notifier).loadTasks(),
        child: const Icon(Icons.refresh),
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _statusFilters.map((status) {
                final filtered = status == null
                    ? tasks
                    : tasks.where((t) => t.taskStatus == status).toList();
                if (filtered.isEmpty) return _buildEmpty();
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _buildCard(context, filtered[i]),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80,
              color: AppColors.outline.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text('暂无任务', style: TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/publish'),
            child: const Text('去发布任务'),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, TaskVo task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/order/${task.taskNum}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _statusTag(task.taskStatus),
                  const Spacer(),
                  Text(task.taskType == 'AERIAL_PHOTO' ? '航拍' : task.taskType,
                      style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 12),
              Text(task.taskName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              if (task.riderName != null && task.riderName!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text('飞手: ${task.riderName!}',
                        style: const TextStyle(fontSize: 13, color: AppColors.primary)),
                  ],
                ),
              ],
              if (task.description != null) ...[
                const SizedBox(height: 8),
                Text(task.description!, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(task.createTime ?? '',
                      style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
                  const Spacer(),
                  if (task.totalAmount != null)
                    Text('¥${task.totalAmount!.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  if (task.taskStatus == 'IDLE')
                    TextButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('确认删除'),
                            content: const Text('删除后无法恢复'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('删除', style: TextStyle(color: AppColors.error)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          final ok = await ref.read(taskListProvider.notifier).deleteTask(task.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(ok ? '已删除' : '删除失败')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                      label: const Text('删除', style: TextStyle(color: AppColors.error)),
                    ),
                  if (task.isWaitingConfirm)
                    TextButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('确认完成'),
                            content: Text('确认「${task.taskName}」已经完成了吗？'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
                              FilledButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                                child: const Text('确认完成'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          final ok = await ref.read(taskListProvider.notifier).confirmTask(task.taskNum);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(ok ? '确认完成成功' : '确认失败')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 18, color: AppColors.success),
                      label: const Text('确认完成', style: TextStyle(color: AppColors.success)),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.push('/order/${task.taskNum}'),
                    child: const Text('查看详情'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusTag(String status) {
    Color bg, text;
    String label;
    switch (status) {
      case 'IDLE':
        bg = AppColors.statusPending; text = AppColors.statusPendingText; label = '空闲中';
        break;
      case 'IN_PROGRESS':
        bg = AppColors.statusInProgress; text = AppColors.statusInProgressText; label = '执行中';
        break;
      case 'COMPLETED':
        bg = AppColors.statusCompleted; text = AppColors.statusCompletedText; label = '已完成';
        break;
      default:
        bg = AppColors.statusCancelled; text = AppColors.statusCancelledText; label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 12, color: text)),
    );
  }
}
