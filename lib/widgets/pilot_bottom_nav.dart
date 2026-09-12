import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PilotBottomNav extends StatelessWidget {
  final Widget child;
  const PilotBottomNav({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/pilot/tasks')) return 0;
    if (location.startsWith('/pilot/jobs')) return 1;
    if (location.startsWith('/pilot/messages')) return 2;
    if (location.startsWith('/pilot/profile')) return 3;
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
            case 0: context.go('/pilot/tasks'); break;
            case 1: context.go('/pilot/jobs'); break;
            case 2: context.go('/pilot/messages'); break;
            case 3: context.go('/pilot/profile'); break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.work_outline), label: '任务大厅'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: '我的接单'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: '消息'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '我的'),
        ],
      ),
    );
  }
}
