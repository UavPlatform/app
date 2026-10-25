import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const hudSand = Color(0xFFFAF8F5);
const hudInk = Color(0xFF1E2229);
const hudTeal = Color(0xFF1B8A6B);
const hudAmber = Color(0xFFF26B1D);
const hudBorder = Color(0xFFEFECE6);

// Native Android maps use hybrid composition. Avoid continuous backdrop readback
// and decorative tickers above their SurfaceView; use the same static material.
bool get _nativeMapSurface =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

class HudGlass extends StatelessWidget {
  const HudGlass({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1622252A),
          blurRadius: 12,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: _nativeMapSurface
          ? _surface(context)
          : BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: _surface(context),
            ),
    ),
  );
  Widget _surface(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xDD22252A)
          : hudSand.withValues(alpha: .85),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withValues(alpha: .7)),
    ),
    child: child,
  );
}

/// Animation state is local to this decoration; it never changes order state.
class HudPulse extends StatefulWidget {
  const HudPulse({super.key, required this.color, this.size = 7});
  final Color color;
  final double size;
  @override
  State<HudPulse> createState() => _HudPulseState();
}

class _HudPulseState extends State<HudPulse>
    with SingleTickerProviderStateMixin {
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_nativeMapSurface || MediaQuery.disableAnimationsOf(context)) {
      _animation.stop();
    } else if (!_animation.isAnimating) {
      _animation.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _animation,
    builder: (_, _) {
      final phase = _nativeMapSurface || MediaQuery.disableAnimationsOf(context)
          ? .5
          : _animation.value;
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: .65 + .35 * phase),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: .10 + phase * .14),
              blurRadius: 2 + phase * 4,
              spreadRadius: phase * 2,
            ),
          ],
        ),
      );
    },
  );
}

class HudStatusCapsule extends StatelessWidget {
  const HudStatusCapsule({super.key, required this.activeCount});
  final int activeCount;
  @override
  Widget build(BuildContext context) => HudGlass(
    child: SizedBox(
      height: 36,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11),
        child: Row(
          children: [
            HudPulse(color: activeCount > 0 ? hudTeal : hudAmber),
            const SizedBox(width: 8),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '$activeCount 单进行中 · 点击标记查看',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : hudInk,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
