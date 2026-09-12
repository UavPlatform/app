import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../models/task_vo.dart';
import '../../providers/location_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/rider_provider.dart';
import '../../providers/chat_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationProvider);
    final taskState = ref.watch(taskListProvider);
    final tasks = taskState.tasks;
    final recommendedRiders = ref.watch(recommendedRidersProvider);
    final unreadCount = ref.watch(totalUnreadCountProvider);

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
              isLabelVisible: unreadCount > 0,
              label: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(fontSize: 10),
              ),
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
          _buildServiceGrid(context),
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
          if (recommendedRiders.loading)
            const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (recommendedRiders.error != null)
            _buildEmptyCard('加载推荐飞手失败')
          else if (recommendedRiders.riders.isEmpty)
            _buildEmptyCard('暂无推荐飞手')
          else
            _buildPilotList(recommendedRiders.riders),
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

  Widget _buildServiceGrid(BuildContext context) {
    // 服务类型为本地常量，对应后端 TaskType 枚举
    const serviceTypes = [
      _ServiceItem(Icons.videocam, '航拍摄影'),
      _ServiceItem(Icons.map, '测绘建模'),
      _ServiceItem(Icons.local_shipping, '物流吊运'),
      _ServiceItem(Icons.eco, '环境监测'),
    ];

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
              Text(type.label, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
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

  Widget _buildPilotList(List riders) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: riders.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final rider = riders[index];
          final name = rider.riderName ?? '飞手';
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
                  child: Text(name[0],
                      style: const TextStyle(fontSize: 24, color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, size: 14, color: AppColors.primary),
                    const SizedBox(width: 2),
                    Text('${rider.totalCompleted}单',
                        style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('今日接单 ${rider.todayOrders}',
                    style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
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

/// 服务分类本地常量
class _ServiceItem {
  final IconData icon;
  final String label;
  const _ServiceItem(this.icon, this.label);
}
