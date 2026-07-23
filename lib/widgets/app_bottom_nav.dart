import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  final Widget child;

  const AppBottomNav({super.key, required this.child});

  static const _tabColors = [
    Color(0xFF2B6FF2), // 首页 - 蓝
    Color(0xFF1BAC4B), // 订单 - 绿
    Color(0xFFFF8F00), // 消息 - 橙
    Color(0xFF6C5CE7), // 我的 - 紫
  ];

  static const _activeScale = 1.18;
  static const _inactiveScale = 0.82;

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/orders')) return 1;
    if (location.startsWith('/messages')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) {
          switch (i) {
            case 0: context.go('/home');
            case 1: context.go('/orders');
            case 2: context.go('/messages');
            case 3: context.go('/profile');
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.navBg,
        unselectedItemColor: AppColors.navInactive,
        selectedItemColor: _tabColors[index],
        selectedFontSize: 13,
        unselectedFontSize: 10,
        items: [
          BottomNavigationBarItem(
            icon: Transform.scale(scale: _inactiveScale, child: const Icon(Icons.home_outlined)),
            activeIcon: Transform.scale(scale: _activeScale, child: const Icon(Icons.home)),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Transform.scale(scale: _inactiveScale, child: const Icon(Icons.receipt_long_outlined)),
            activeIcon: Transform.scale(scale: _activeScale, child: const Icon(Icons.receipt_long)),
            label: '订单',
          ),
          BottomNavigationBarItem(
            icon: Transform.scale(scale: _inactiveScale, child: const Icon(Icons.chat_bubble_outline)),
            activeIcon: Transform.scale(scale: _activeScale, child: const Icon(Icons.chat_bubble)),
            label: '消息',
          ),
          BottomNavigationBarItem(
            icon: Transform.scale(scale: _inactiveScale, child: const Icon(Icons.person_outline)),
            activeIcon: Transform.scale(scale: _activeScale, child: const Icon(Icons.person)),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
