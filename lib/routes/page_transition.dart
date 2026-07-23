import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Global lock to block repeated navigation during a transition (350ms).
final transitionLockProvider = StateProvider<bool>((ref) => false);

/// Acquire the lock for [duration] then auto-release.
void lockTransition(WidgetRef ref, {Duration duration = const Duration(milliseconds: 350)}) {
  ref.read(transitionLockProvider.notifier).state = true;
  Future.delayed(duration, () {
    // Best-effort unlock; may fire after dispose which is harmless.
    try {
      ref.read(transitionLockProvider.notifier).state = false;
    } catch (_) {}
  });
}

/// Duration for page push/pop transitions.
const Duration pageTransitionDuration = Duration(milliseconds: 300);

/// Duration for modal bottom-sheet transitions.
const Duration modalTransitionDuration = Duration(milliseconds: 250);

/// Ease-out curve shared by all transitions.
const Curve transitionCurve = Curves.easeOut;

// ---------------------------------------------------------------------------
// Unified page transition
// ---------------------------------------------------------------------------
/// Forward (push):
///   old page → x 0 → -20%vw, opacity 1 → 0.6
///   new page → x 100%vw → 0, opacity 0 → 1
/// Back (pop):
///   top page    → x 0 → 100%vw, opacity 1 → 0
///   below page  → x -20%vw → 0, opacity 0.6 → 1
class AppTransitionPage extends CustomTransitionPage {
  const AppTransitionPage({
    required super.key,
    required super.child,
  }) : super(
          transitionDuration: pageTransitionDuration,
          reverseTransitionDuration: pageTransitionDuration,
          transitionsBuilder: _transitionsBuilder,
        );

  static Widget _transitionsBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: Listenable.merge([animation, secondaryAnimation]),
      builder: (_, _) {
        final t = animation.value;
        final s = secondaryAnimation.value;

        double dx = 0;
        double opacity = 1.0;

        if (s > 0) {
          // Underlying: covered (push) or revealed (pop).
          dx = -0.2 * screenWidth * s;
          opacity = 1.0 - 0.4 * s;
        } else if (t < 1.0) {
          // Top: entering (push t:0→1) or exiting (pop t:1→0).
          dx = screenWidth * (1 - t);
          opacity = t;
        }

        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(dx, 0),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Modal / bottom-sheet transition
// ---------------------------------------------------------------------------
/// Enter: Y 100%→0, opacity 0→1, scale 0.95→1
/// Exit:  reverse
Widget modalTransitionBuilder(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final screenHeight = MediaQuery.of(context).size.height;

  return AnimatedBuilder(
    animation: animation,
    builder: (_, _) {
      final t = animation.value;
      return Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, screenHeight * (1 - t)),
          child: Transform.scale(
            scale: 0.95 + 0.05 * t,
            child: child,
          ),
        ),
      );
    },
    child: child,
  );
}

/// Show a modal bottom sheet with unified transition specs.
Future<T?> showAppModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black54,
    transitionDuration: modalTransitionDuration,
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: transitionCurve);
      return modalTransitionBuilder(context, curved, secondaryAnimation, child);
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Material(color: Colors.transparent, child: builder(context)),
      );
    },
  );
}
