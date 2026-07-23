import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBottomNav extends StatelessWidget {
  final Widget child;

  const AppBottomNav({super.key, required this.child});

  static const _activeScale = 1.15;
  static const _inactiveScale = 0.85;

  static const _selectedColors = [
    Color(0xFF5B8FD4), // 首页 - 柔和蓝
    Color(0xFF55B882), // 订单 - 柔和绿
    Color(0xFFE8A850), // 消息 - 柔和橙
    Color(0xFF8B7EC8), // 我的 - 柔和紫
  ];

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
    final idx = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: idx,
        onTap: (i) {
          switch (i) {
            case 0: context.go('/home');
            case 1: context.go('/orders');
            case 2: context.go('/messages');
            case 3: context.go('/profile');
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        unselectedItemColor: const Color(0xFFAAAAAA),
        selectedItemColor: _selectedColors[idx],
        selectedFontSize: 12,
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
