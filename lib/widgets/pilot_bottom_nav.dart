import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// DS-APP-003：底部四栏——首页 / 无人机 / 消息 / 我的。
class PilotBottomNav extends StatelessWidget {
  final Widget child;
  const PilotBottomNav({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/pilot/equipment')) return 1;
    if (location.startsWith('/pilot/messages')) return 2;
    if (location.startsWith('/pilot/profile')) return 3;
    // 首页及任务大厅、我的订单都归在「首页」栏。
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: index,
        onTap: (i) {
          switch (i) {
            case 0:
              context.go('/pilot/home');
              break;
            case 1:
              context.go('/pilot/equipment');
              break;
            case 2:
              context.go('/pilot/messages');
              break;
            case 3:
              context.go('/pilot/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.flight), label: '无人机'),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: '消息',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
