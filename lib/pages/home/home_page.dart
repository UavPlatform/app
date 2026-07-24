import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../providers/location_provider.dart';
import '../../providers/rider_provider.dart';
import '../../models/rider_vo.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _pageCtrl = PageController();
  int _bannerIdx = 0;
  Timer? _timer;

  static const _banners = [
    _BannerData(tag: '热门', title: '认证飞手  严格审核  持证上岗', subtitle: 'DJI Matrice 300 RTK 工业级标配'),
    _BannerData(tag: '推荐', title: '任务进度实时追踪  消息即达', subtitle: '全程 GPS 可视化，延迟低于 200ms'),
    _BannerData(tag: '新上线', title: '飞翼通 · 专业无人机调度平台', subtitle: '安全高效，一键发布，全国覆盖'),
  ];

  static final _feeds = [
    _Feed(name: '张师傅', time: '2小时前', text: '今天湘潭天气绝了，湘江上空视角太震撼了！', likes: 234, comments: 18, liked: true, colorIdx: 0),
    _Feed(name: '李师傅', time: '5小时前', text: '新到的M300 RTK首飞，测绘精度相当满意', likes: 187, comments: 12, colorIdx: 1),
    _Feed(name: '赵师傅', time: '8小时前', text: '建材吊运，一钩到位。今天风大但机器很稳', likes: 156, comments: 8, colorIdx: 2),
    _Feed(name: '王师傅', time: '12小时前', text: '湘潭大学操场测绘完成，3D建模效果预览', likes: 312, comments: 25, liked: true, colorIdx: 3),
    _Feed(name: '张师傅', time: '1天前', text: '客户婚礼航拍花絮，新人的笑容太治愈了', likes: 198, comments: 15, colorIdx: 4),
    _Feed(name: '刘师傅', time: '2天前', text: '新手报到！第一次接单湘江水质监测，请多指教', likes: 89, comments: 32, colorIdx: 5),
  ];
  static const _feedColors = [Color(0xFF5B7FA8), Color(0xFF6B8E6B), Color(0xFF8B7355), Color(0xFF7B6B8A), Color(0xFF4A8090), Color(0xFF8A7060)];

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

  BoxDecoration _cardShadow() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(10),
    boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 14, offset: Offset(0, 3))],
  );

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          // Search + notification row + location
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Row: search bar + notification
              Row(children: [
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F7),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFFF8C3D), width: 1.3),
                    ),
                    child: const Row(children: [
                      SizedBox(width: 12),
                      Icon(Icons.search, size: 17, color: Color(0xFFFF8C3D)),
                      SizedBox(width: 6),
                      Text('搜索任务或飞手', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
                    ]),
                  ),
                ),
                Stack(children: [
                  IconButton(icon: const Icon(Icons.notifications_outlined, size: 21), onPressed: () => context.go('/messages')),
                  Positioned(right: 10, top: 10, child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.badge, shape: BoxShape.circle))),
                ]),
              ]),
              const SizedBox(height: 6),
              // Location
              GestureDetector(
                onTap: () => ref.read(locationProvider.notifier).refresh(),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.location_on, color: AppColors.primary, size: 15),
                  const SizedBox(width: 2),
                  Text(location.loading ? '定位中...' : location.city, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textSecondary),
                ]),
              ),
            ]),
          ),
          _buildBanner(),
          const SizedBox(height: 12),
          _buildServiceGrid(),
          const SizedBox(height: 18),
          _buildSectionHeader('热门飞手', '更多', () => context.push('/riders')),
          const SizedBox(height: 8),
          _buildPilotRow(ref.watch(riderListProvider).riders),
          const SizedBox(height: 18),
          _buildSectionHeader('飞手动态', null, null),
          const SizedBox(height: 8),
          _buildFeedWaterfall(),
        ],
      ),
    );
  }

  // ==================== Banner ====================
  Widget _buildBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12).copyWith(top: 10),
      child: Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 150,
            decoration: BoxDecoration(boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 2))]),
            child: PageView.builder(
              controller: _pageCtrl,
              onPageChanged: (i) => setState(() => _bannerIdx = i),
              itemCount: _banners.length,
              itemBuilder: (_, i) {
                final d = _banners[i];
                return Container(
                  decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0D2818), Color(0xFF1A5C3A)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                  child: CustomPaint(
                    painter: _ContourPainter(),
                    child: Stack(children: [
                      Positioned(left: 18, top: 22, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(4)), child: Text(d.tag, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600))),
                        const SizedBox(height: 8),
                        Text(d.title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(d.subtitle, style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 12)),
                      ])),
                      Positioned(right: -10, bottom: -10, child: Icon(Icons.flight, size: 130, color: Colors.white.withAlpha(15))),
                    ]),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == _bannerIdx ? 16 : 6, height: 4,
            decoration: BoxDecoration(color: i == _bannerIdx ? AppColors.primary : const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(2)),
          ))),
      ]),
    );
  }

  // ==================== 金刚区 ====================
  Widget _buildServiceGrid() {
    final items = [
      _Svc(Icons.videocam_rounded, '航拍摄影', const Color(0xFF3B7CF5)),
      _Svc(Icons.map_rounded, '测绘建模', const Color(0xFF34B37C)),
      _Svc(Icons.local_shipping_rounded, '物流吊运', const Color(0xFFFF8C3D)),
      _Svc(Icons.eco_rounded, '环境监测', const Color(0xFF7C5CF0)),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: _cardShadow(),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((e) => GestureDetector(
            onTap: () => context.push('/publish', extra: e.label),
            child: SizedBox(width: 64, child: Column(children: [
              Container(width: 46, height: 46, decoration: BoxDecoration(color: e.color.withAlpha(50), borderRadius: BorderRadius.circular(14)), child: Icon(e.icon, color: e.color, size: 26)),
              const SizedBox(height: 6),
              Text(e.label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ])),
          )).toList(),
        ),
      ),
    );
  }

  // ==================== Section header ====================
  Widget _buildSectionHeader(String title, String? action, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        if (action != null)
          GestureDetector(onTap: onTap, child: Row(children: [
            Text(action, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(width: 2),
            Container(width: 16, height: 16, decoration: BoxDecoration(color: const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.chevron_right, size: 12, color: AppColors.textSecondary)),
          ])),
      ]),
    );
  }

  // ==================== 热门飞手 ====================
  Widget _buildPilotRow(List<RiderVo> riders) {
    if (riders.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text('暂无飞手数据', style: TextStyle(color: AppColors.textSecondary))),
      );
    }
    final display = riders.length > 5 ? riders.sublist(0, 5) : riders;
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: display.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final p = display[i];
          final medal = i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : null;
          return GestureDetector(
            onTap: () => context.push('/rider/${p.riderId}'),
            child: Container(
              width: 140, padding: const EdgeInsets.all(12),
              decoration: _cardShadow(),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Stack(children: [
                    Container(width: 40, height: 40, decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: AppColors.primaryLight), child: Center(child: Text(p.riderName[0], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.primary)))),
                    if (medal != null) Positioned(right: -6, top: -6, child: Text(medal, style: const TextStyle(fontSize: 18))),
                  ]),
                  const SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.riderName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('今日 ${p.todayOrders}单', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ])),
                ]),
                const Spacer(),
                Text('累计完成: ${p.totalCompleted}单', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF777777))),
              ]),
            ),
          );
        },
      ),
    );
  }

  // ==================== 飞手动态 waterfall ====================
  Widget _buildFeedWaterfall() {
    final left = <_Feed>[];
    final right = <_Feed>[];
    for (int i = 0; i < _feeds.length; i++) {
      (i.isEven ? left : right).add(_feeds[i]);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(children: left.map((f) => _buildFeedCard(f)).toList())),
        const SizedBox(width: 8),
        Expanded(child: Column(children: right.map((f) => _buildFeedCard(f)).toList())),
      ]),
    );
  }

  Widget _buildFeedCard(_Feed f) {
    final colW = (MediaQuery.of(context).size.width - 36) / 2;
    final ratio = 0.6 + (f.colorIdx % 7) * 0.15;
    final imgH = colW * ratio;
    final color = _feedColors[f.colorIdx % _feedColors.length];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _cardShadow(),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(10, 10, 10, 6), child: Row(children: [
          Container(width: 24, height: 24, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryLight), child: Center(child: Text(f.name[0], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)))),
          const SizedBox(width: 6),
          Expanded(child: Text(f.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
          Text(f.time, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
        ])),
        Stack(children: [
          Container(height: imgH, width: double.infinity, decoration: BoxDecoration(color: color), child: Center(child: Icon(Icons.image, size: imgH * 0.25, color: Colors.white.withAlpha(50)))),
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withAlpha(80)], stops: const [0.55, 1.0])))),
          Positioned(left: 8, bottom: 6, right: 8, child: Row(children: [
            const Icon(Icons.location_on, size: 10, color: Colors.white70),
            const SizedBox(width: 2),
            Text('距您 ${(0.5 + f.colorIdx % 5 * 0.6).toStringAsFixed(1)}km', style: const TextStyle(color: Colors.white70, fontSize: 9)),
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), decoration: BoxDecoration(color: Colors.white.withAlpha(45), borderRadius: BorderRadius.circular(3)), child: const Text('进行中', style: TextStyle(color: Colors.white, fontSize: 8))),
          ])),
        ]),
        Padding(padding: const EdgeInsets.fromLTRB(10, 8, 10, 2), child: Text(f.text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.45), maxLines: 3, overflow: TextOverflow.ellipsis)),
        Padding(padding: const EdgeInsets.fromLTRB(10, 2, 10, 10), child: Row(children: [
          Icon(f.liked ? Icons.favorite : Icons.favorite_border, size: 15, color: f.liked ? AppColors.danger : AppColors.textHint),
          const SizedBox(width: 2),
          Text('${f.likes}', style: TextStyle(fontSize: 11, color: f.liked ? AppColors.danger : AppColors.textHint)),
          const SizedBox(width: 14),
          const Icon(Icons.chat_bubble_outline, size: 13, color: AppColors.textHint),
          const SizedBox(width: 2),
          Text('${f.comments}', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
          const Spacer(),
          const Icon(Icons.bookmark_border, size: 15, color: AppColors.textHint),
        ])),
      ]),
    );
  }
}

class _BannerData { final String tag, title, subtitle; const _BannerData({required this.tag, required this.title, required this.subtitle}); }
class _Svc { final IconData icon; final String label; final Color color; const _Svc(this.icon, this.label, this.color); }
class _Feed { final String name, time, text; final int likes, comments, colorIdx; final bool liked; const _Feed({required this.name, required this.time, required this.text, required this.likes, required this.comments, required this.colorIdx, this.liked = false}); }

class _ContourPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withAlpha(8)..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 28) { canvas.drawLine(Offset(x, 0), Offset(x, size.height), p); }
    for (double y = 0; y < size.height; y += 28) { canvas.drawLine(Offset(0, y), Offset(size.width, y), p); }
    final cp = Paint()..color = Colors.white.withAlpha(14)..strokeWidth = 0.8;
    for (double y = 20; y < size.height; y += 56) {
      final path = Path()..moveTo(0, y);
      for (double x = 0; x < size.width; x += 4) { path.lineTo(x, y + sin(x / 40) * 6); }
      canvas.drawPath(path, cp);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
