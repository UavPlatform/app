import 'package:flutter/material.dart';

/// Shared identity card for shipper and pilot profiles.
class ProfileAccountCard extends StatelessWidget {
  const ProfileAccountCard({
    super.key,
    required this.name,
    required this.identityLabel,
  });
  final String name;
  final String identityLabel;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? const Color(0xFFF0F4FA) : const Color(0xFF111111);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CustomPaint(
        painter: _AccountLandscape(dark: dark),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3B82F6),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1D6FE9).withValues(alpha: .12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 36,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .75),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified_user_outlined,
                            size: 13,
                            color: Color(0xFF1D6FE9),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              identityLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1D6FE9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Scalable decorative lifting scene behind the account identity.
class _AccountLandscape extends CustomPainter {
  const _AccountLandscape({required this.dark});
  final bool dark;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: dark
              ? [const Color(0xFF253B55), const Color(0xFF244973)]
              : [
                  const Color(0xFFF0F8FF),
                  const Color(0xFFDDECFF),
                  const Color(0xFFA5CBFF),
                ],
        ).createShader(rect),
    );
    canvas.save();
    canvas.scale(size.width / 380, size.height / 114);
    final paint = Paint();
    void mountain(List<Offset> points, Color color) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      path.close();
      canvas.drawPath(path, paint..color = color);
    }

    final blue = dark ? const Color(0xFF7BA8DC) : const Color(0xFF74ABEF);
    mountain([
      const Offset(145, 114),
      const Offset(217, 84),
      const Offset(255, 70),
      const Offset(303, 99),
      const Offset(380, 67),
      const Offset(380, 114),
    ], blue.withValues(alpha: .16));
    mountain([
      const Offset(202, 114),
      const Offset(271, 101),
      const Offset(319, 85),
      const Offset(349, 106),
      const Offset(380, 76),
      const Offset(380, 114),
    ], blue.withValues(alpha: .19));
    mountain([
      const Offset(243, 80),
      const Offset(255, 70),
      const Offset(268, 80),
      const Offset(257, 77),
      const Offset(253, 85),
    ], Colors.white.withValues(alpha: .3));
    canvas.save();
    canvas.translate(315, 34);
    paint
      ..color = blue.withValues(alpha: .36)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(-28, -8), const Offset(28, -13), paint);
    canvas.drawLine(const Offset(-23, 5), const Offset(23, 1), paint);
    for (final rotor in [
      const Offset(-28, -8),
      const Offset(28, -13),
      const Offset(-23, 5),
      const Offset(23, 1),
    ]) {
      canvas.drawLine(rotor.translate(0, -3), rotor.translate(0, 4), paint);
      canvas.drawOval(
        Rect.fromCenter(center: rotor.translate(0, -4), width: 23, height: 3),
        Paint()..color = blue.withValues(alpha: .28),
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-12, -8, 24, 14),
        const Radius.circular(5),
      ),
      Paint()..color = blue.withValues(alpha: .4),
    );
    paint
      ..strokeWidth = .8
      ..color = blue.withValues(alpha: .4);
    canvas.drawLine(const Offset(0, 6), const Offset(-13, 34), paint);
    canvas.drawLine(const Offset(0, 6), const Offset(15, 34), paint);
    canvas.drawRect(
      const Rect.fromLTWH(-13, 34, 28, 18),
      Paint()..color = blue.withValues(alpha: .3),
    );
    for (double x = -9; x < 15; x += 5) {
      canvas.drawLine(Offset(x, 36), Offset(x, 50), paint);
    }
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AccountLandscape oldDelegate) => oldDelegate.dark != dark;
}
