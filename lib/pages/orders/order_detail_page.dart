import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../services/mock_data_service.dart';
import '../../models/order_model.dart';

class OrderDetailPage extends StatelessWidget {
  final String orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final order = MockDataService.orders.firstWhere((o) => o.id == orderId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('订单详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        children: [
          // 状态头部
          _buildStatusHeader(order),

          // 任务信息
          _buildSection(
            title: '任务信息',
            children: [
              _buildInfoRow('订单号', order.id.toUpperCase()),
              _buildInfoRow('服务类型', order.serviceTypeName),
              _buildInfoRow('任务时间', '${order.taskDate.month}-${order.taskDate.day} ${order.taskDate.hour}:${order.taskDate.minute.toString().padLeft(2, '0')}'),
              _buildInfoRow('任务地点', order.location),
              _buildInfoRow('任务描述', order.description),
            ],
          ),

          // 飞手信息（接单后显示）
          if (order.pilotId != null) ...[
            const SizedBox(height: 8),
            _buildPilotSection(context, order),
          ],

          // 费用明细
          const SizedBox(height: 8),
          _buildSection(
            title: '费用明细',
            children: [
              if (order.finalPrice != null) ...[
                _buildInfoRow('服务费用', '¥${order.finalPrice!.toStringAsFixed(0)}'),
                _buildInfoRow('平台服务费', '¥${(order.finalPrice! * 0.1).toStringAsFixed(0)}'),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('合计', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '¥${(order.finalPrice! * 1.1).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                _buildInfoRow('预算范围', order.priceText),
                const SizedBox(height: 8),
                const Text(
                  '* 实际价格以飞手报价为准',
                  style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ],
          ),

          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(context, order),
    );
  }

  Widget _buildStatusHeader(Order order) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xFF42A5F5)],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStepDot('已发布', true),
              _buildStepLine(true),
              _buildStepDot('已接单', order.pilotId != null),
              _buildStepLine(order.status == OrderStatus.inProgress || order.status == OrderStatus.completed),
              _buildStepDot('进行中', order.status == OrderStatus.inProgress || order.status == OrderStatus.completed),
              _buildStepLine(order.status == OrderStatus.completed),
              _buildStepDot('已完成', order.status == OrderStatus.completed),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '当前状态: ${order.statusText}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (order.status == OrderStatus.inProgress)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '预计2小时后完成',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepDot(String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.white : Colors.white38,
          ),
          child: isActive
              ? const Icon(Icons.check, size: 14, color: AppColors.primary)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.white : Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Container(
      width: 40,
      height: 2,
      color: isActive ? Colors.white : Colors.white38,
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPilotSection(BuildContext context, Order order) {
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
          const Text(
            '飞手信息',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  order.pilotName![0],
                  style: const TextStyle(
                    fontSize: 20,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.pilotName!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '⭐ ${order.pilotRating} · ${MockDataService.pilots.first.completedOrders}单',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.phone, size: 18),
                  label: const Text('电话'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat, size: 18),
                  label: const Text('聊天'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget? _buildBottomActions(BuildContext context, Order order) {
    Widget? leftButton;
    Widget? rightButton;

    switch (order.status) {
      case OrderStatus.pending:
        leftButton = OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
          ),
          child: const Text('取消订单'),
        );
        break;
      case OrderStatus.inProgress:
        leftButton = OutlinedButton(
          onPressed: () {},
          child: const Text('联系飞手'),
        );
        rightButton = ElevatedButton(
          onPressed: () {},
          child: const Text('确认完成'),
        );
        break;
      case OrderStatus.completed:
        leftButton = OutlinedButton(
          onPressed: () {},
          child: const Text('评价飞手'),
        );
        rightButton = ElevatedButton(
          onPressed: () {},
          child: const Text('再次下单'),
        );
        break;
      default:
        return null;
    }

    if (leftButton == null && rightButton == null) return null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (leftButton != null) Expanded(child: leftButton),
          if (leftButton != null && rightButton != null) const SizedBox(width: 12),
          if (rightButton != null) Expanded(child: rightButton),
        ],
      ),
    );
  }
}
