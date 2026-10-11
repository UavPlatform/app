import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBottomNav extends StatelessWidget {
  final Widget child;

  const AppBottomNav({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/orders')) return 1;
    if (location.startsWith('/profile')) return 2;
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
            case 0:
              context.go('/home');
            case 1:
              context.go('/orders');
            case 2:
              context.go('/profile');
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        selectedItemColor: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.primary
            : const Color(0xFF4A8BFF),
        selectedFontSize: 12,
        iconSize: 24,
        elevation: 0,
        unselectedFontSize: 12,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: _activeIcon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: _activeIcon(Icons.receipt_long),
            label: '订单',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: _activeIcon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }

  Widget _activeIcon(IconData icon) => Icon(icon, size: 24);
}
