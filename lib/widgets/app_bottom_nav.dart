import 'hud_surface.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBottomNav extends StatelessWidget {
  final Widget child;

  const AppBottomNav({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/orders')) return 0;
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
              context.push('/waybill/new');
            case 2:
              context.go('/profile');
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? hudSand
            : Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        selectedItemColor: hudTeal,
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
            icon: _createOrderIcon(),
            activeIcon: _createOrderIcon(),
            label: '创建订单',
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

  Widget _createOrderIcon() => Container(
    width: 48,
    height: 32,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [hudAmber, Color(0xFFE55C14)]),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: hudAmber.withValues(alpha: 0.22),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: const Icon(Icons.add_rounded, color: Colors.white, size: 27),
  );

  Widget _activeIcon(IconData icon) => Icon(icon, size: 24);
}
