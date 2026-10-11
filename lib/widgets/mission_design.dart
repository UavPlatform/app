import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MissionPanel extends StatelessWidget {
  const MissionPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary, Color(0xFF102C46), Color(0xFF176C78)],
      ),
    ),
    child: CustomPaint(
      painter: _AirspacePainter(),
      child: Padding(padding: padding, child: child),
    ),
  );
}

class _AirspacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final center = Offset(size.width * 0.95, size.height * 0.15);
    for (final radius in [42.0, 82.0, 122.0, 162.0]) {
      canvas.drawCircle(center, radius, paint);
    }
    for (double x = 0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum MissionSectionStyle { card, ruled, inset }

class MissionSection extends StatelessWidget {
  const MissionSection({
    super.key,
    required this.number,
    required this.title,
    required this.child,
    this.framed = true,
    this.style = MissionSectionStyle.card,
  });
  final bool framed;
  final MissionSectionStyle style;
  final String number;
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: style == MissionSectionStyle.ruled
        ? EdgeInsets.symmetric(vertical: 16)
        : framed
        ? EdgeInsets.all(16)
        : EdgeInsets.zero,
    decoration: style == MissionSectionStyle.ruled
        ? BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          )
        : style == MissionSectionStyle.inset
        ? BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            border: Border(
              left: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 3,
              ),
            ),
          )
        : framed
        ? BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          )
        : null,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              number,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        SizedBox(height: 16),
        child,
      ],
    ),
  );
}

/// Flat inputs for the task form, independent of the global rounded input theme.
class MissionFormStyles {
  static InputDecoration input(
    BuildContext context, {
    required String hint,
    String? unit,
  }) => InputDecoration(
    hintText: hint,
    suffixText: unit,
    filled: false,
    isDense: true,
    contentPadding: EdgeInsets.symmetric(vertical: 12),
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
    ),
    hintStyle: TextStyle(
      fontSize: 14,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}
