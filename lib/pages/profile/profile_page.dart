import '../../providers/waybill_draft_provider.dart';
import '../../widgets/profile_account_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drafts = ref.watch(
      waybillDraftProvider.select((state) => state.entries.length),
    );
    final name = ref.watch(authProvider).user?.userName;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? const Color(0xFFF0F4FA) : const Color(0xFF111111);
    final surface = dark ? const Color(0xFF1B2735) : Colors.white;
    const divider = Divider(
      height: 1,
      thickness: 0.5,
      indent: 64,
      endIndent: 16,
      color: Color(0xFFF0F0F0),
    );
    return Scaffold(
      backgroundColor: dark ? const Color(0xFF101820) : const Color(0xFFF3F4F6),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(top: 18, bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '我的',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
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
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF333333),
                      fixedSize: const Size(36, 36),
                      minimumSize: const Size(36, 36),
                      padding: EdgeInsets.zero,
                      shape: const CircleBorder(),
                    ),
                    icon: Icon(
                      dark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ProfileAccountCard(
                key: const ValueKey('profile-account-card'),
                name: name == null || name.trim().isEmpty ? '用户' : name,
                identityLabel: '吊运服务账户',
              ),
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                color: surface,
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
                      child: Text(
                        '业务与服务',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ),
                    _ServiceRow(
                      icon: Icons.history_rounded,
                      tint: const Color(0xFFE8F3FF),
                      color: const Color(0xFF1D6FE9),
                      title: '历史订单',
                      subtitle: '查看已结单与已取消订单',
                      onTap: () => context.push('/orders/history'),
                    ),
                    divider,
                    _ServiceRow(
                      icon: Icons.drafts_outlined,
                      tint: const Color(0xFFFFF0E6),
                      color: const Color(0xFFFF6B00),
                      title: '草稿箱',
                      subtitle: drafts == 0 ? '暂无草稿' : '$drafts 份草稿 · 继续填写',
                      onTap: () => context.push('/drafts'),
                    ),
                    divider,
                    _ServiceRow(
                      icon: Icons.info_outline_rounded,
                      tint: const Color(0xFFF2F4F7),
                      color: const Color(0xFF4B5563),
                      title: '关于飞翼通',
                      subtitle: '版本信息与服务介绍',
                      onTap: () => _showAbout(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: surface,
                  foregroundColor: const Color(0xFFEF4444),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(double.infinity, 50),
                  maximumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: BorderSide.none,
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, size: 18),
                    SizedBox(width: 8),
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

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: '飞翼通',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.flight,
        size: 40,
        color: AppColors.primary,
      ),
      children: const [
        Text(
          '面向山区、林场、屋顶等场景的无人机吊运撮合平台：发布吊运需求，平台按距离、'
          '重量与机型统一计价；选定飞手并沟通作业细节后在线支付，作业直播与交付验收一站完成。',
        ),
      ],
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.icon,
    required this.tint,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color tint, color;
  final String title, subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFF0F4FA)
                        : const Color(0xFF1F2329),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 18, color: Color(0xFFCCCCCC)),
        ],
      ),
    ),
  );
}
