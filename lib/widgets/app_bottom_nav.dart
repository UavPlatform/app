import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBottomNav extends StatelessWidget {
  final Widget child;
  const AppBottomNav({super.key, required this.child});

  static const _activeScale = 1.15;
  static const _inactiveScale = 0.85;
  static const _c = Color(0xFF07C160);

  static const _colors = [Color(0xFF5B8FD4), Color(0xFF55B882), Color(0xFF07C160), Color(0xFFE8A850), Color(0xFF8B7EC8)];

  int _idx(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith('/home')) return 0;
    if (path.startsWith('/orders')) return 1;
    if (path.startsWith('/messages')) return 3;
    if (path.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final i = _idx(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: i,
        onTap: (n) {
          switch (n) { case 0: context.go('/home'); case 1: context.go('/orders'); case 2: context.push('/feed/publish'); case 3: context.go('/messages'); case 4: context.go('/profile'); }
        },
        type: BottomNavigationBarType.fixed, backgroundColor: Colors.white,
        unselectedItemColor: const Color(0xFFAAAAAA), selectedItemColor: _colors[i], selectedFontSize: 12, unselectedFontSize: 10,
        items: [
          BottomNavigationBarItem(icon: Transform.scale(scale: _inactiveScale, child: const Icon(Icons.home_outlined)), activeIcon: Transform.scale(scale: _activeScale, child: const Icon(Icons.home)), label: '首页'),
          BottomNavigationBarItem(icon: Transform.scale(scale: _inactiveScale, child: const Icon(Icons.receipt_long_outlined)), activeIcon: Transform.scale(scale: _activeScale, child: const Icon(Icons.receipt_long)), label: '订单'),
          BottomNavigationBarItem(
            icon: Container(width: 44, height: 44, decoration: const BoxDecoration(gradient: LinearGradient(colors: [_c, Color(0xFF05B050)], begin: Alignment.topLeft, end: Alignment.bottomRight), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x4007C160), blurRadius: 8, offset: Offset(0, 2))]), child: const Icon(Icons.add, color: Colors.white, size: 26)),
            activeIcon: Container(width: 44, height: 44, decoration: const BoxDecoration(gradient: LinearGradient(colors: [_c, Color(0xFF05B050)], begin: Alignment.topLeft, end: Alignment.bottomRight), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x4007C160), blurRadius: 8, offset: Offset(0, 2))]), child: const Icon(Icons.add, color: Colors.white, size: 26)),
            label: '发布',
          ),
          BottomNavigationBarItem(icon: Transform.scale(scale: _inactiveScale, child: const Icon(Icons.chat_bubble_outline)), activeIcon: Transform.scale(scale: _activeScale, child: const Icon(Icons.chat_bubble)), label: '消息'),
          BottomNavigationBarItem(icon: Transform.scale(scale: _inactiveScale, child: const Icon(Icons.person_outline)), activeIcon: Transform.scale(scale: _activeScale, child: const Icon(Icons.person)), label: '我的'),
        ],
      ),
    );
  }
}
