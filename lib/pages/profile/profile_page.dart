import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../services/mock_data_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = MockDataService.currentUser;
    final orders = MockDataService.orders;
    final pendingCount = orders.where((o) => o.status.name == 'pending').length;
    final inProgressCount = orders.where((o) => o.status.name == 'inProgress').length;
    final reviewingCount = orders.where((o) => o.status.name == 'reviewing').length;

    return Scaffold(
      body: ListView(
        children: [
          // 用户信息头部
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primary, Color(0xFF42A5F5)],
              ),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      child: Text(
                        user.nickname[0],
                        style: const TextStyle(
                          fontSize: 28,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  user.nickname,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.phone,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem('${orders.length}', '订单'),
                    _buildStatItem('2', '评价'),
                  ],
                ),
              ],
            ),
          ),

          // 订单快捷入口
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '我的订单',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildOrderQuickEntry(
                      context,
                      icon: Icons.payment,
                      label: '待付款',
                      count: 0,
                    ),
                    _buildOrderQuickEntry(
                      context,
                      icon: Icons.pending_actions,
                      label: '待接单',
                      count: pendingCount,
                    ),
                    _buildOrderQuickEntry(
                      context,
                      icon: Icons.directions_run,
                      label: '进行中',
                      count: inProgressCount,
                    ),
                    _buildOrderQuickEntry(
                      context,
                      icon: Icons.check_circle_outline,
                      label: '已完成',
                      count: reviewingCount,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 功能菜单
          _buildMenuItem(context, icon: Icons.location_on_outlined, title: '地址管理', onTap: () => context.push('/addresses')),
          _buildMenuItem(context, icon: Icons.star_outline, title: '我的评价'),
          _buildMenuItem(context, icon: Icons.headset_mic_outlined, title: '联系客服'),
          _buildMenuItem(context, icon: Icons.help_outline, title: '帮助与反馈'),
          _buildMenuItem(context, icon: Icons.settings_outlined, title: '设置'),
          _buildMenuItem(context, icon: Icons.info_outline, title: '关于我们'),

          const SizedBox(height: 24),

          // 退出登录
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton(
              onPressed: () => context.go('/login'),
              child: const Text(
                '退出登录',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderQuickEntry(BuildContext context, {required IconData icon, required String label, required int count}) {
    return GestureDetector(
      onTap: () => context.go('/orders'),
      child: Column(
        children: [
          Badge(
            isLabelVisible: count > 0,
            label: Text('$count', style: const TextStyle(fontSize: 10)),
            child: Icon(icon, size: 28, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title, VoidCallback? onTap}) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right, color: AppColors.outline),
          onTap: onTap,
        ),
        const Divider(height: 1, indent: 72),
      ],
    );
  }
}
