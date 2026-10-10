import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../models/task_vo.dart';
import '../../providers/rider_provider.dart';

class TaskHallPage extends ConsumerStatefulWidget {
  const TaskHallPage({super.key});

  @override
  ConsumerState<TaskHallPage> createState() => _TaskHallPageState();
}

class _TaskHallPageState extends ConsumerState<TaskHallPage> {
  // ADR-0003 / REQ-APP-002：本端收敛为吊运单一品类，大厅默认只看「吊运」，
  // 保留「全部」供切换查看历史品类任务。
  String? _selectedType = 'TRANSPORT';

  static const _typeOptions = ['全部', '航拍', '吊运', '测绘', '监测'];
  static const _typeKeys = [null, 'AERIAL_PHOTO', 'TRANSPORT', 'SURVEY', 'MONITORING'];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskSquareProvider);

    final tasks = state.tasks.where((t) {
      if (_selectedType == null) return true;
      return t.taskType == _selectedType;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('任务大厅')),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => ref.read(taskSquareProvider.notifier).loadTasks(),
        child: const Icon(Icons.refresh),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: List.generate(_typeOptions.length, (i) {
                final isSelected = _typeKeys[i] == _selectedType;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_typeOptions[i]),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedType = _typeKeys[i]),
                    selectedColor: AppColors.primaryLight,
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.outlineVariant,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }),
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildBody(context, state, tasks)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, TaskSquareState state, List<TaskVo> tasks) {
    if (state.loading && state.tasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: AppColors.outlineVariant),
            const SizedBox(height: 16),
            Text(state.error!, style: const TextStyle(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref.read(taskSquareProvider.notifier).loadTasks(),
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: AppColors.outlineVariant.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('暂无可用任务',
                style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 16)),
            const SizedBox(height: 8),
            // t22 接单支付规则：仅已支付任务进入大厅（Q1=A 托管式支付）
            const Text('支付后的任务才会进入大厅，当前没有可接任务',
                style: TextStyle(color: AppColors.outline, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) => _buildTaskCard(context, tasks[index]),
    );
  }

  Widget _buildTaskCard(BuildContext context, TaskVo task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      // 卡片 → 任务详情（详情内提供应征按钮与货物/约定信息）。
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/order/${task.taskNum}'),
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
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
              // 吊运货物信息（ADR-0003 计价输入：重量 + 类别）
              if (task.cargoLabel.isNotEmpty) ...[
                const SizedBox(height: 6),
                _infoRow(Icons.inventory_2_outlined, task.cargoLabel),
              ],
              if (task.totalDistance != null && task.totalDistance! > 0) ...[
                const SizedBox(height: 6),
                _infoRow(Icons.route_outlined, '距离: ${task.totalDistance!.toStringAsFixed(0)} m'),
              ],
              const SizedBox(height: 6),
              _infoRow(Icons.access_time, task.formattedCreateTime),
            ],
          ),
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
}
