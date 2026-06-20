import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../services/mock_data_service.dart';
import '../../models/task_vo.dart';
import '../../providers/location_provider.dart';
import '../../providers/task_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationProvider);
    final serviceTypes = MockDataService.serviceTypes;
    final pilots = MockDataService.pilots;
    final taskState = ref.watch(taskListProvider);
    final tasks = taskState.tasks;

    final inProgressTasks = tasks.where((t) => t.isInProgress).toList();
    final idleTasks = tasks.where((t) => t.isIdle).toList();

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => ref.read(locationProvider.notifier).refresh(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, color: AppColors.primary, size: 20),
              const SizedBox(width: 4),
              Text(
                location.loading ? '定位中...' : location.city,
                style: const TextStyle(fontSize: 16),
              ),
              const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: true,
              label: const Text('3', style: TextStyle(fontSize: 10)),
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('服务分类', null),
          const SizedBox(height: 12),
          _buildServiceGrid(context, serviceTypes),
          const SizedBox(height: 24),

          _buildSectionTitle('进行中的任务', '查看全部'),
          const SizedBox(height: 12),
          if (inProgressTasks.isEmpty)
            _buildEmptyCard('暂无进行中的任务')
          else
            ...inProgressTasks.take(2).map((t) => _buildOrderCard(context, t)),
          const SizedBox(height: 24),

          _buildSectionTitle('热门飞手推荐', '更多'),
          const SizedBox(height: 12),
          _buildPilotList(pilots),
          const SizedBox(height: 24),

          _buildSectionTitle('最新任务广场', null),
          const SizedBox(height: 12),
          ...idleTasks.map((t) => _buildTaskCard(context, t)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/publish'),
        icon: const Icon(Icons.add),
        label: const Text('发布任务'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSectionTitle(String title, String? action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        if (action != null)
          TextButton(onPressed: () {}, child: Text(action)),
      ],
    );
  }

  Widget _buildServiceGrid(BuildContext context, List serviceTypes) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: serviceTypes.length,
      itemBuilder: (context, index) {
        final type = serviceTypes[index];
        return GestureDetector(
          onTap: () => context.push('/publish'),
          child: Column(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(type.icon, color: AppColors.primary, size: 28),
              ),
              const SizedBox(height: 8),
              Text(type.name, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyCard(String text) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(text, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14)),
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, TaskVo task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/order/${task.taskNum}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.flight, color: AppColors.primary, size: 40),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildStatusTag(task.taskStatus),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(task.taskTypeName,
                              style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(task.taskName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    if (task.riderName != null)
                      Row(
                        children: [
                          const Icon(Icons.person, size: 16, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(task.riderName!,
                              style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(task.formattedCreateTime,
                            style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTag(String status) {
    Color bgColor;
    Color textColor;
    String label;
    switch (status) {
      case 'IDLE':
        bgColor = AppColors.statusPending;
        textColor = AppColors.statusPendingText;
        label = '空闲中';
        break;
      case 'IN_PROGRESS':
        bgColor = AppColors.statusInProgress;
        textColor = AppColors.statusInProgressText;
        label = '执行中';
        break;
      case 'COMPLETED':
        bgColor = AppColors.statusCompleted;
        textColor = AppColors.statusCompletedText;
        label = '已完成';
        break;
      default:
        bgColor = AppColors.statusCancelled;
        textColor = AppColors.statusCancelledText;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 12, color: textColor)),
    );
  }

  Widget _buildPilotList(List pilots) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: pilots.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final pilot = pilots[index];
          return Container(
            width: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(pilot.nickname[0],
                      style: const TextStyle(fontSize: 24, color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Text(pilot.nickname, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text('${pilot.rating}', style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text('${pilot.completedOrders}单',
                        style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: pilot.serviceTypes.take(2).map<Widget>((type) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(4)),
                    child: Text(type, style: const TextStyle(fontSize: 10, color: AppColors.primary)),
                  )).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, TaskVo task) {
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(task.taskTypeName,
                        style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                  ),
                  const Spacer(),
                  Text(task.priceText,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 12),
              Text(task.description ?? '',
                  style: const TextStyle(fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(task.formattedCreateTime,
                      style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
