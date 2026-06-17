import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../services/mock_data_service.dart';
import '../../models/order_model.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['全部', '待接单', '进行中', '已完成'];
  final List<OrderStatus?> _statusFilters = [null, OrderStatus.pending, OrderStatus.inProgress, OrderStatus.completed];

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
    final allOrders = MockDataService.orders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的订单'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _statusFilters.map((status) {
          final filteredOrders = status == null
              ? allOrders
              : allOrders.where((o) => o.status == status).toList();

          if (filteredOrders.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredOrders.length,
            itemBuilder: (context, index) {
              return _buildOrderCard(context, filteredOrders[index]);
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: AppColors.outline.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无相关订单',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '快去发布您的第一个任务吧',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.outline,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/publish'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 48),
            ),
            child: const Text('去发布任务'),
          ),
        ],
      ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildStatusTag(order.status),
                  const Spacer(),
                  Text(
                    order.serviceTypeName,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                order.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
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
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Text(
                    order.priceText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.push('/order/${order.id}'),
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

  Widget _buildStatusTag(OrderStatus status) {
    Color bgColor;
    Color textColor;
    String text;
    switch (status) {
      case OrderStatus.pending:
        bgColor = AppColors.statusPending;
        textColor = AppColors.statusPendingText;
        text = '待接单';
        break;
      case OrderStatus.inProgress:
        bgColor = AppColors.statusInProgress;
        textColor = AppColors.statusInProgressText;
        text = '进行中';
        break;
      case OrderStatus.reviewing:
        bgColor = AppColors.statusInProgress;
        textColor = AppColors.statusInProgressText;
        text = '待验收';
        break;
      case OrderStatus.completed:
        bgColor = AppColors.statusCompleted;
        textColor = AppColors.statusCompletedText;
        text = '已完成';
        break;
      case OrderStatus.cancelled:
        bgColor = AppColors.statusCancelled;
        textColor = AppColors.statusCancelledText;
        text = '已取消';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: textColor),
      ),
    );
  }
}
