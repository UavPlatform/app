import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/task_provider.dart';

/// REQ-APP-002: only the current user's transport demands, never a public hall.
class OwnTasksSummary extends ConsumerWidget {
  const OwnTasksSummary({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(taskListProvider);
    final tasks = state.tasks
        .where(
          (task) =>
              task.taskType == 'TRANSPORT' &&
              !const ['已完成', '已结案', '已取消', '已退款'].contains(task.userStageLabel),
        )
        .take(3)
        .toList();
    final scheme = Theme.of(context).colorScheme;
    return Material(
      key: const ValueKey('home-own-tasks'),
      color: scheme.surface,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '我的吊运需求',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/trade/published'),
                  child: const Text('查看全部'),
                ),
              ],
            ),
            if (state.loading && tasks.isEmpty)
              const LinearProgressIndicator(minHeight: 2)
            else if (state.error != null && tasks.isEmpty)
              TextButton(
                onPressed: () =>
                    ref.read(taskListProvider.notifier).loadTasks(),
                child: const Text('需求加载失败，点击重试'),
              )
            else if (tasks.isEmpty)
              Text(
                '暂无进行中的吊运需求',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              )
            else
              ...tasks.map(
                (task) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.inventory_2_outlined,
                    color: scheme.primary,
                  ),
                  title: Text(
                    task.taskName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    task.userStageLabel,
                    style: TextStyle(color: scheme.primary),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await context.push(
                      '/order/${Uri.encodeComponent(task.taskNum)}',
                    );
                    if (context.mounted) {
                      ref.read(taskListProvider.notifier).loadTasks();
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
