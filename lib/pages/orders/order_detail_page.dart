import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../models/task_vo.dart';
import '../../providers/task_provider.dart';

class OrderDetailPage extends ConsumerWidget {
  final String taskNum;

  const OrderDetailPage({super.key, required this.taskNum});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(taskDetailProvider(taskNum));

    if (state.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final task = state.task;
    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('任务详情')),
        body: Center(
          child: Text(state.error ?? '未找到任务',
              style: const TextStyle(color: AppColors.onSurfaceVariant)),
        ),
      );
    }

    return _buildScaffold(context, ref, task);
  }

  Widget _buildScaffold(BuildContext context, WidgetRef ref, TaskVo task) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('任务详情'),
        actions: [
          if (task.isIdle)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _onDelete(context, ref, task),
            ),
        ],
      ),
      body: ListView(
        children: [
          _buildStatusHeader(task),
          _buildSection('任务信息', [
            _infoRow('任务编号', task.taskNum),
            _infoRow('任务名称', task.taskName),
            _infoRow('任务类型', task.taskTypeName),
            if (task.riderName != null && task.riderName!.isNotEmpty)
              _infoRow('接单飞手', task.riderName!),
            if (task.description != null && task.description!.isNotEmpty)
              _infoRow('任务描述', task.description!),
            if (task.formattedCreateTime.isNotEmpty)
              _infoRow('创建时间', task.formattedCreateTime),
            if (task.totalAmount != null && task.totalAmount! > 0)
              _infoRow('酬劳', '¥${task.totalAmount!.toStringAsFixed(0)}'),
            if (task.totalDistance != null && task.totalDistance! > 0)
              _infoRow('总距离', '${task.totalDistance!.toStringAsFixed(0)} m'),
            if (task.orderNum != null) _infoRow('订单号', task.orderNum!),
          ]),
          if (task.waypoints != null && task.waypoints!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildSection('航点', [
              ...task.waypoints!.asMap().entries.map((e) {
                final wp = e.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24, height: 24,
                        decoration: const BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('${e.key + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${wp.latitude.toStringAsFixed(6)}, ${wp.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                );
              }),
            ]),
          ],
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: _buildBottom(context, ref, task),
    );
  }

  Widget _buildStatusHeader(TaskVo task) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, Color(0xFF42A5F5)]),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _stepDot('空闲', true),
              _stepLine(task.taskStatus != 'IDLE'),
              _stepDot('执行中', task.isInProgress || task.isCompleted),
              _stepLine(task.isCompleted),
              _stepDot('完成', task.isCompleted),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '当前状态: ${task.taskStatusName}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _stepDot(String label, bool active) {
    return Column(
      children: [
        Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? Colors.white : Colors.white38,
          ),
          child: active ? const Icon(Icons.check, size: 14, color: AppColors.primary) : null,
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: active ? Colors.white : Colors.white54)),
      ],
    );
  }

  Widget _stepLine(bool active) {
    return Container(width: 40, height: 2, color: active ? Colors.white : Colors.white38);
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget? _buildBottom(BuildContext context, WidgetRef ref, TaskVo task) {
    if (task.isWaitingConfirm) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => _onConfirm(context, ref, task),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('确认完成', style: TextStyle(fontSize: 16)),
          ),
        ),
      );
    }

    if (task.isIdle) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _onDelete(context, ref, task),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                child: const Text('删除任务'),
              ),
            ),
          ],
        ),
      );
    }

    return null;
  }

  Future<void> _onConfirm(BuildContext context, WidgetRef ref, TaskVo task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认完成'),
        content: Text('确认「${task.taskName}」已经完成了吗？\n确认后订单将完结。'),
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

    if (confirm != true || !context.mounted) return;

    final ok = await ref.read(taskDetailProvider(task.taskNum).notifier).confirmTask(task.taskNum);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '确认完成成功' : ref.read(taskDetailProvider(task.taskNum)).error ?? '确认失败')),
    );
  }

  Future<void> _onDelete(BuildContext context, WidgetRef ref, TaskVo task) async {
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
      final ok = await ref.read(taskDetailProvider(task.taskNum).notifier).deleteTask(task.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? '已删除' : '删除失败')),
        );
        if (ok) WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/orders'));
      }
    }
  }
}
