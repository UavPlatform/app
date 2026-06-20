import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class PilotProfilePage extends ConsumerWidget {
  const PilotProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final name = user?.userName ?? '飞手';

    return Scaffold(
      body: ListView(
        children: [
          // 头部
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white,
                  child: Text(name[0].toUpperCase(),
                      style: const TextStyle(
                          fontSize: 28, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                Text(name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('飞手', style: TextStyle(fontSize: 12, color: Colors.white)),
                ),
                const SizedBox(height: 20),
                // 数据统计
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStat('今日接单', '3'),
                    _buildStatDivider(),
                    _buildStat('评分', '4.9'),
                    _buildStatDivider(),
                    _buildStat('完成', '326'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 快捷入口
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('快捷功能',
                style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant.withOpacity(0.7))),
          ),
          const SizedBox(height: 8),
          _buildQuickGrid(context),

          const SizedBox(height: 16),

          // 菜单
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('通用',
                style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant.withOpacity(0.7))),
          ),
          const SizedBox(height: 8),
          _buildMenuItem(context, icon: Icons.flight, title: '我的无人机',
              onTap: () => context.push('/pilot/drones')),
          _buildMenuItem(context, icon: Icons.tune, title: '接单设置'),
          _buildMenuItem(context, icon: Icons.star_outline, title: '评价管理'),
          _buildMenuItem(context, icon: Icons.headset_mic_outlined, title: '联系客服'),
          _buildMenuItem(context, icon: Icons.info_outline, title: '关于飞翼通'),

          const SizedBox(height: 24),

          // 退出登录
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.outlineVariant),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('退出登录'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1, height: 36,
      color: Colors.white24,
    );
  }

  Widget _buildQuickGrid(BuildContext context) {
    final items = [
      (_Icons.wallet, '我的钱包', () {}),
      (_Icons.category, '服务类型', () {}),
      (_Icons.shield, '飞手认证', () {}),
      (_Icons.data, '数据中心', () {}),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: items.map((item) {
          return Expanded(
            child: GestureDetector(
              onTap: item.$3,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.statusInProgress.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.$1, color: const Color(0xFF2E7D32), size: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(item.$2,
                        style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context,
      {required IconData icon, required String title, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ListTile(
            onTap: onTap,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: Colors.white,
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.statusInProgress.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
            ),
            title: Text(title, style: const TextStyle(fontSize: 15)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.outline, size: 20),
          ),
        ],
      ),
    );
  }
}

// 自定义图标占位
class _Icons {
  _Icons._();
  static const wallet = Icons.account_balance_wallet_outlined;
  static const category = Icons.category_outlined;
  static const shield = Icons.verified_outlined;
  static const data = Icons.bar_chart_outlined;
}
