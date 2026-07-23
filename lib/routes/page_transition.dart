import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Unified page transition for all navigations.
///
/// Old page: opacity 1→0, scale 1→0.95 (recedes backward)
/// New page: translate-x 100%→0, opacity 0→1, scale 0.95→1 (enters from right)
/// Duration: 500ms, curve: ease-in-out
class AppTransitionPage extends CustomTransitionPage {
  const AppTransitionPage({required super.key, required super.child})
    : super(
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: _buildTransition,
      );

  static Widget _buildTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: Listenable.merge([curved, secondaryAnimation]),
      builder: (_, _) {
        final t = curved.value;
        final s = secondaryAnimation.value;

        double dx = 0;
        double opacity = 1.0;
        double scale = 1.0;

        if (s > 0) {
          // Old page being covered (push) or revealed (pop)
          dx = -0.1 * screenWidth * s;
          opacity = 1.0 - s;
          scale = 1.0 - 0.05 * s;
        } else if (t < 1.0) {
          // New page entering (push) or exiting (pop)
          dx = screenWidth * (1 - t);
          opacity = t;
          scale = 0.95 + 0.05 * t;
        }

        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: scale.clamp(0.0, 1.0),
            child: Transform.translate(offset: Offset(dx, 0), child: child),
          ),
        );
      },
      child: child,
    );
  }
}
