import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/trade_provider.dart';
import 'trade_summary.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(authProvider).user?.userName;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? const Color(0xFFF0F4FA) : const Color(0xFF111827);
    final muted = dark ? const Color(0xFFAEBED1) : const Color(0xFF626B7B);
    return Scaffold(
      backgroundColor: dark ? const Color(0xFF101820) : const Color(0xFFF3F7FC),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(tradeStatsProvider);
            try {
              await ref.read(tradeStatsProvider.future);
            } catch (_) {}
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '我的',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: text,
                    ),
                  ),
                  IconButton(
                    tooltip: ref.watch(themeModeProvider) == ThemeMode.dark
                        ? '切换白天模式'
                        : '切换夜晚模式',
                    onPressed: () =>
                        ref.read(themeModeProvider.notifier).toggle(),
                    style: IconButton.styleFrom(
                      backgroundColor: dark
                          ? const Color(0xFF223044)
                          : Colors.white.withValues(alpha: .8),
                      foregroundColor: muted,
                      minimumSize: const Size(44, 44),
                      shape: const CircleBorder(),
                    ),
                    icon: Icon(
                      dark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      size: 25,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                key: const ValueKey('profile-account-card'),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF6293CE,
                      ).withValues(alpha: dark ? .06 : .13),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: CustomPaint(
                    painter: _AccountLandscape(dark: dark),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 112),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: dark ? .08 : .8,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 66,
                            height: 66,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFADD2FF), Color(0xFF5A95FF)],
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .9),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              size: 47,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name == null || name.trim().isEmpty
                                      ? '用户'
                                      : name,
                                  style: TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w700,
                                    color: text,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '吊运服务账户',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: dark
                                        ? muted
                                        : const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const TradeSummary(),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 12),
                child: Text(
                  '业务服务',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: text,
                  ),
                ),
              ),
              _ServiceCard(
                icon: Icons.assignment_rounded,
                color: const Color(0xFF4A8BFF),
                title: '订单与任务',
                subtitle: '查询撮合、支付与验收进度',
                onTap: () => context.go('/orders'),
              ),
              const SizedBox(height: 12),
              _ServiceCard(
                icon: Icons.location_on_rounded,
                color: const Color(0xFF20B692),
                title: '地址管理',
                subtitle: '管理常用作业地址',
                onTap: () => context.push('/addresses'),
              ),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded, size: 22),
                label: const Text('退出登录'),
                style: OutlinedButton.styleFrom(
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                  foregroundColor: dark
                      ? const Color(0xFFFF8A8C)
                      : const Color(0xFFD91519),
                  backgroundColor: dark
                      ? const Color(0xFF241D25)
                      : const Color(0xFFFFF8F8),
                  minimumSize: const Size(double.infinity, 52),
                  side: BorderSide(
                    color: dark
                        ? const Color(0xFF87444D)
                        : const Color(0xFFFF9298),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6E90BD).withValues(alpha: dark ? .03 : .06),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: dark ? const Color(0xFF1B2735) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: dark ? .23 : .08),
                        color.withValues(alpha: dark ? .13 : .14),
                      ],
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        bottom: 10,
                        child: Container(
                          width: 23,
                          height: 5,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: .22),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      Icon(
                        icon,
                        size: 33,
                        color: dark
                            ? Color.lerp(color, Colors.white, .2)
                            : color,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 25,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
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
