import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../services/mock_data_service.dart';
import '../../models/order_model.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final serviceTypes = MockDataService.serviceTypes;
    final pilots = MockDataService.pilots;
    final orders = MockDataService.orders;
    final pendingOrders = orders.where((o) =>
      o.status == OrderStatus.pending || o.status == OrderStatus.inProgress
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.location_on, color: AppColors.primary, size: 20),
            const SizedBox(width: 4),
            const Text('北京市', style: TextStyle(fontSize: 16)),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
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
          // 服务分类
          _buildSectionTitle('服务分类', null),
          const SizedBox(height: 12),
          _buildServiceGrid(context, serviceTypes),
          const SizedBox(height: 24),

          // 进行中的任务
          if (pendingOrders.isNotEmpty) ...[
            _buildSectionTitle('进行中的任务', '查看全部'),
            const SizedBox(height: 12),
            ...pendingOrders.take(2).map((order) => _buildOrderCard(context, order)),
            const SizedBox(height: 24),
          ],

          // 热门飞手推荐
          _buildSectionTitle('热门飞手推荐', '更多'),
          const SizedBox(height: 12),
          _buildPilotList(pilots),
          const SizedBox(height: 24),

          // 最新任务广场
          _buildSectionTitle('最新任务广场', null),
          const SizedBox(height: 12),
          ...orders.where((o) => o.status == OrderStatus.pending).map(
            (order) => _buildTaskCard(context, order),
          ),
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
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: () {},
            child: Text(action),
          ),
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
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(type.icon, color: AppColors.primary, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                type.name,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/order/${order.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
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
                        _buildStatusTag(order),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.serviceTypeName,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      order.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    if (order.pilotName != null)
                      Row(
                        children: [
                          const Icon(Icons.person, size: 16, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            '${order.pilotName} ⭐${order.pilotRating}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            order.location,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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

  Widget _buildStatusTag(Order order) {
    Color bgColor;
    Color textColor;
    switch (order.status) {
      case OrderStatus.pending:
        bgColor = AppColors.statusPending;
        textColor = AppColors.statusPendingText;
        break;
      case OrderStatus.inProgress:
        bgColor = AppColors.statusInProgress;
        textColor = AppColors.statusInProgressText;
        break;
      case OrderStatus.completed:
        bgColor = AppColors.statusCompleted;
        textColor = AppColors.statusCompletedText;
        break;
      default:
        bgColor = AppColors.statusCancelled;
        textColor = AppColors.statusCancelledText;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        order.statusText,
        style: TextStyle(fontSize: 12, color: textColor),
      ),
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
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    pilot.nickname[0],
                    style: const TextStyle(
                      fontSize: 24,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  pilot.nickname,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(
                      '${pilot.rating}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${pilot.completedOrders}单',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: pilot.serviceTypes.take(2).map((type) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      type,
                      style: const TextStyle(fontSize: 10, color: AppColors.primary),
                    ),
                  )).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/order/${order.id}'),
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
                    child: Text(
                      order.serviceTypeName,
                      style: const TextStyle(fontSize: 12, color: AppColors.primary),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    order.priceText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                order.description,
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.location,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${order.taskDate.month}-${order.taskDate.day} ${order.taskDate.hour}:${order.taskDate.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '已有${(order.id.hashCode % 5 + 1)}位飞手报价',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
