import '../../widgets/profile_account_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class PilotProfilePage extends ConsumerWidget {
  const PilotProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final name = user?.userName ?? '飞手';
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF1B2735) : Colors.white;
    final text = dark ? const Color(0xFFF0F4FA) : const Color(0xFF111111);
    return Scaffold(
      backgroundColor: dark ? const Color(0xFF101820) : const Color(0xFFF3F4F6),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(top: 18),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '我的',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: text,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: ProfileAccountCard(
                key: const ValueKey('pilot-profile-account-card'),
                name: name,
                identityLabel: '飞手',
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                '快捷功能',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF888888),
                ),
              ),
            ),
            _buildQuickGrid(context),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(
                '通用',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF888888),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                key: const ValueKey('pilot-profile-menu-card'),
                color: surface,
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.badge_outlined,
                      title: '飞手资料与驾驶资质',
                      onTap: () => context.push('/pilot/info'),
                    ),
                    const Divider(
                      height: 1,
                      thickness: .5,
                      indent: 56,
                      endIndent: 16,
                      color: Color(0xFFF0F0F0),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.info_outline,
                      title: '关于飞翼通',
                      onTap: () => showAboutDialog(
                        context: context,
                        applicationName: '飞翼通',
                        applicationVersion: '1.0.0',
                        applicationIcon: const Icon(
                          Icons.flight,
                          size: 40,
                          color: Color(0xFF2E7D32),
                        ),
                        children: const [
                          // ADR-0002：飞行执行在 djifly，App 不执行飞行；ADR-0003：平台统一计价、不议价。
                          Text(
                            '无人机吊运撮合平台：在任务大厅按平台统一报价应征，与用户沟通作业细节；'
                            '确认订单后在 djifly 中执行飞行，完成后提交交付凭证。',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: TextButton(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
                style: TextButton.styleFrom(
                  backgroundColor: surface,
                  foregroundColor: const Color(0xFFEF4444),
                  padding: EdgeInsets.zero,
                  side: BorderSide.none,
                  minimumSize: const Size(double.infinity, 50),
                  maximumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      size: 18,
                      color: Color(0xFFEF4444),
                    ),
                    SizedBox(width: 6),
                    Text('退出登录'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickGrid(BuildContext context) {
    final items = [
      (_Icons.shield, '飞手资料', () => context.push('/pilot/info')),
      (_Icons.drone, '无人机租借', () => context.go('/pilot/equipment')),
      (_Icons.jobs, '我的订单', () => context.push('/pilot/jobs')),
    ];
    const tints = [Color(0xFFE8F3FF), Color(0xFFE6F8F0), Color(0xFFFFF0E6)];
    const accents = [Color(0xFF1D6FE9), Color(0xFF00B578), Color(0xFFFF6B00)];
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        key: const ValueKey('pilot-profile-quick-card'),
        color: dark ? const Color(0xFF1B2735) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: items[i].$3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: tints[i],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              items[i].$1,
                              color: accents[i],
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            items[i].$2,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: dark
                                  ? const Color(0xFFF0F4FA)
                                  : const Color(0xFF1F2329),
                            ),
                          ),
                        ],
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

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F3FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF1D6FE9)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFF0F4FA)
                    : const Color(0xFF1F2329),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: Color(0xFFCCCCCC),
          ),
        ],
      ),
    ),
  );
}

class _Icons {
  _Icons._();
  static const shield = Icons.verified_outlined;
  static const drone = Icons.flight;
  static const jobs = Icons.assignment_outlined;
}
