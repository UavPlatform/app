import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../services/mock_data_service.dart';
import '../../models/pilot_feed.dart';
import '../../providers/location_provider.dart';
import '../../routes/page_transition.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _pageCtrl = PageController();
  int _bannerIdx = 0;
  Timer? _timer;

  static final _banners = [
    _BannerData(
      title: '飞翼通 · 专业无人机物流',
      subtitle: '安全高效，一键吊运，全国覆盖',
      tag: '新上线',
      gradient: [Color(0xFF1A314E), Color(0xFF2B6FF2)],
      image: 'assets/images/drone_banner.png',
      fullImage: false,
    ),
    _BannerData(
      title: '',
      subtitle: '',
      tag: '',
      gradient: [Colors.transparent, Colors.transparent],
      image: 'assets/images/banner_2.png',
      fullImage: true,
    ),
    _BannerData(
      title: '任务进度实时追踪  消息即达',
      subtitle: '全程 GPS 可视化，延迟低于 200ms',
      tag: '推荐',
      gradient: [Color(0xFF2A1A4E), Color(0xFF6C5CE7)],
      image: 'assets/images/drone_banner.png',
      fullImage: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      _pageCtrl.animateToPage((_bannerIdx + 1) % _banners.length, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  // ---- card decoration helpers ----
  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 20, offset: Offset(0, 4))],
  );

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationProvider);
    final pilots = MockDataService.pilots;
    final feeds = MockDataService.pilotFeeds;

    return Scaffold(
      appBar: _buildAppBar(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          // Location row — above banner, aligned with search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: GestureDetector(
              onTap: () => ref.read(locationProvider.notifier).refresh(),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.primary, size: 17),
                  const SizedBox(width: 2),
                  Text(
                    location.loading ? '定位中...' : location.city,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          _buildBanner(),
          const SizedBox(height: 10),
          _buildServiceEntries(),
          const SizedBox(height: 18),
          _buildSectionHeader('热门飞手', '更多', () {}, icon: Icons.people_alt),
          const SizedBox(height: 8),
          _buildPilotRow(pilots),
          const SizedBox(height: 18),
          _buildSectionHeader('飞手动态', null, null, icon: Icons.dynamic_feed),
          const SizedBox(height: 8),
          _buildFeedWaterfall(context, feeds),
        ],
      ),
    );
  }

  // ============================================================
  //  AppBar with search box
  // ============================================================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Container(
        height: 34,
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFEBECEF),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFFFF8C3D), width: 1.5),
        ),
        child: const Row(
          children: [
            SizedBox(width: 8),
            Icon(Icons.search, size: 16, color: Color(0xFFFF8C3D)),
            SizedBox(width: 4),
            Text('搜索任务或飞手', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
          ],
        ),
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 21),
              onPressed: () => context.go('/messages'),
            ),
            Positioned(right: 10, top: 10,
              child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.badge, shape: BoxShape.circle))),
          ],
        ),
        const SizedBox(width: 2),
      ],
    );
  }

  // ============================================================
  //  Banner — gradient + grid + drone render
  // ============================================================
  Widget _buildBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          // Main banner — clip the background but let drone overflow
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 150,
              decoration: BoxDecoration(boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 3))]),
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _bannerIdx = i),
                itemCount: _banners.length,
                itemBuilder: (_, i) {
                  final d = _banners[i];
                  if (d.fullImage) {
                    // Full-image slide — no text overlay
                    return Image.asset(d.image, fit: BoxFit.cover);
                  }
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        decoration: BoxDecoration(gradient: LinearGradient(colors: d.gradient, begin: Alignment.topLeft, end: const Alignment(1, 1.2))),
                        child: CustomPaint(
                          painter: _GridPainter(),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const SizedBox(height: 22),
                            Padding(
                              padding: const EdgeInsets.only(left: 20),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: Colors.white.withAlpha(45), borderRadius: BorderRadius.circular(4)),
                                  child: Text(d.tag, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                                ),
                                const SizedBox(height: 8),
                                Text(d.title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text(d.subtitle, style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 12)),
                              ]),
                            ),
                          ]),
                        ),
                      ),
                      Positioned(
                        right: -8,
                        top: 0,
                        bottom: 0,
                        child: Image.asset(d.image, width: 180, fit: BoxFit.cover),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_banners.length, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _bannerIdx ? 18 : 6, height: 4,
              decoration: BoxDecoration(
                color: i == _bannerIdx ? AppColors.primary : const Color(0xFFE8E8E8),
                borderRadius: BorderRadius.circular(2),
              ),
            )),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  Service entries — 2.5D gradient-branded icons
  // ============================================================
  Widget _buildServiceEntries() {
    final items = [
      _EntryItem(Icons.videocam_rounded, '航拍摄影', const [Color(0xFF3B7CF5), Color(0xFF2563EB)]),
      _EntryItem(Icons.map_rounded, '测绘建模', const [Color(0xFF34B37C), Color(0xFF1F8C5C)]),
      _EntryItem(Icons.local_shipping_rounded, '物流吊运', const [Color(0xFFFF8C3D), Color(0xFFE07020)]),
      _EntryItem(Icons.eco_rounded, '环境监测', const [Color(0xFF7C5CF0), Color(0xFF5B3DE0)]),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: _cardDecoration(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((e) {
            final isActive = e.label == '物流吊运';
            return GestureDetector(
              onTap: () {
                if (isActive) {
                  if (ref.read(transitionLockProvider)) return;
                  lockTransition(ref);
                  context.push('/publish');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${e.label}服务即将开放'), duration: const Duration(seconds: 2)));
                }
              },
              child: SizedBox(
                width: 64,
                child: Column(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: e.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: e.gradient.first.withAlpha(50), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Icon(e.icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(height: 6),
                  Text(e.label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ]),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ============================================================
  //  Section header — bold, larger
  // ============================================================
  Widget _buildSectionHeader(String title, String? action, VoidCallback? onTap, {IconData icon = Icons.circle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ]),
          if (action != null)
            GestureDetector(
              onTap: onTap,
              child: Row(children: [
                Text(action, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(width: 2),
                Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(color: const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.chevron_right, size: 12, color: AppColors.textSecondary),
                ),
              ]),
            ),
        ],
      ),
    );
  }

  // ============================================================
  //  Pilot row — avatar photos, colored tags, rich data
  // ============================================================
  static const _pilotTags = {
    'pilot_001': ['航拍认证', 'M300专家'],
    'pilot_002': ['环境监测师', '持证上岗'],
    'pilot_003': ['测绘工程师'],
    'pilot_004': ['吊运专家', 'M300 RTK'],
    'pilot_005': ['新手飞手', '航拍学员'],
  };

  Widget _buildPilotRow(List pilots) {
    final sorted = List.from(pilots)..sort((a, b) => b.completedOrders.compareTo(a.completedOrders));
    return SizedBox(
      height: 162,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: sorted.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final p = sorted[i];
          final tags = _pilotTags[p.id] ?? <String>[];
          final medal = i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : null;
          return Container(
            width: 160,
            padding: const EdgeInsets.all(12),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  // Avatar
                  Stack(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: AppColors.primaryLight,
                        ),
                        child: const Icon(Icons.person, size: 24, color: AppColors.primary),
                      ),
                      if (medal != null)
                        Positioned(
                          right: -6, top: -6,
                          child: Text(medal, style: const TextStyle(fontSize: 18)),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.nickname, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Row(children: [
                          Icon(Icons.star, size: 11, color: const Color(0xFFFFA000)),
                          Text(' ${p.rating}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ]),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                // Tags
                if (tags.isNotEmpty)
                  Wrap(
                    spacing: 4, runSpacing: 2,
                    children: tags.map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.tagBlueBg, borderRadius: BorderRadius.circular(3)),
                      child: Text(t, style: const TextStyle(fontSize: 9, color: AppColors.tagBlue, fontWeight: FontWeight.w500)),
                    )).toList(),
                  ),
                const Spacer(),
                Text('服务单量: ${p.completedOrders}  (${(p.serviceTypes).join('/')})',
                  style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  //  Feed waterfall — 16:9, gradient overlay, richer cards
  // ============================================================
  static const _feedColors = [
    Color(0xFF5B7FA8), Color(0xFF6B8E6B), Color(0xFF8B7355), Color(0xFF7B6B8A),
    Color(0xFF4A8090), Color(0xFF8A7060), Color(0xFF607888), Color(0xFF788860),
  ];

  Widget _buildFeedWaterfall(BuildContext context, List<PilotFeed> feeds) {
    final left = <PilotFeed>[];
    final right = <PilotFeed>[];
    for (int i = 0; i < feeds.length; i++) {
      (i.isEven ? left : right).add(feeds[i]);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Column(children: left.map((f) => _buildFeedCard(context, f)).toList())),
          const SizedBox(width: 8),
          Expanded(child: Column(children: right.map((f) => _buildFeedCard(context, f)).toList())),
        ],
      ),
    );
  }

  Widget _buildFeedCard(BuildContext context, PilotFeed feed) {
    final hash = feed.id.hashCode.abs();
    final color = _feedColors[hash % _feedColors.length];
    // Varying image height from 0.6 to 1.8 ratio → true waterfall stagger
    final colW = MediaQuery.of(context).size.width / 2 - 16;
    final ratio = 0.6 + (hash % 13) * 0.1; // 0.6 ~ 1.8
    final imageH = feed.images.isNotEmpty ? colW * ratio : 100.0;

    return GestureDetector(
      onTap: () => context.push('/feed/${feed.id}', extra: feed),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: _cardDecoration(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + name row
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
              child: Row(children: [
                Container(
                  width: 22, height: 22,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryLight,
                  ),
                  child: const Icon(Icons.person, size: 14, color: AppColors.primary),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(feed.pilotName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                Text(feed.timeAgo, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
              ]),
            ),
            // 16:9 image with overlay
            Stack(
              children: [
                Container(
                  height: imageH,
                  width: double.infinity,
                  decoration: BoxDecoration(color: color),
                  child: Center(
                    child: Icon(Icons.image, size: imageH * 0.25, color: Colors.white.withAlpha(50)),
                  ),
                ),
                // Gradient overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withAlpha(90)],
                        stops: const [0.55, 1.0],
                      ),
                    ),
                  ),
                ),
                // Bottom overlay text
                Positioned(
                  left: 8, bottom: 6, right: 8,
                  child: Row(children: [
                    const Icon(Icons.location_on, size: 10, color: Colors.white70),
                    const SizedBox(width: 2),
                    Text('距您 ${(0.5 + hash % 30 / 10.0).toStringAsFixed(1)}km', style: const TextStyle(color: Colors.white70, fontSize: 9)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(color: Colors.white.withAlpha(45), borderRadius: BorderRadius.circular(3)),
                      child: const Text('进行中', style: TextStyle(color: Colors.white, fontSize: 8)),
                    ),
                  ]),
                ),
              ],
            ),
            // Caption
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
              child: Text(feed.content, style: const TextStyle(fontSize: 12, height: 1.45), maxLines: 3, overflow: TextOverflow.ellipsis),
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
              child: Row(children: [
                Icon(feed.isLiked ? Icons.favorite : Icons.favorite_border, size: 15, color: feed.isLiked ? AppColors.danger : AppColors.textHint),
                const SizedBox(width: 2),
                Text('${feed.likeCount}', style: TextStyle(fontSize: 11, color: feed.isLiked ? AppColors.danger : AppColors.textHint)),
                const SizedBox(width: 14),
                const Icon(Icons.chat_bubble_outline, size: 13, color: AppColors.textHint),
                const SizedBox(width: 2),
                Text('${feed.commentCount}', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                const Spacer(),
                const Icon(Icons.bookmark_border, size: 15, color: AppColors.textHint),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//  Banner grid pattern painter
// ============================================================
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(10)
      ..strokeWidth = 0.5;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Contour lines
    final cp = Paint()
      ..color = Colors.white.withAlpha(18)
      ..strokeWidth = 0.8;
    for (double y = 20; y < size.height; y += 56) {
      final path = Path()..moveTo(0, y);
      for (double x = 0; x < size.width; x += 4) {
        path.lineTo(x, y + sin(x / 40) * 6);
      }
      canvas.drawPath(path, cp);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
// ============================================================
//  Data classes
// ============================================================
class _BannerData {
  final String title;
  final String subtitle;
  final String tag;
  final List<Color> gradient;
  final String image;
  final bool fullImage;
  const _BannerData({required this.title, required this.subtitle, required this.tag, required this.gradient, required this.image, this.fullImage = false});
}

class _EntryItem {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  const _EntryItem(this.icon, this.label, this.gradient);
}
