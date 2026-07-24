import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../models/rider_vo.dart';
import '../../providers/rider_provider.dart';
import '../../providers/auth_provider.dart';

bool _isAuthError(String? error) {
  return error != null && (error.contains('401') || error.contains('登录'));
}

class RiderListPage extends ConsumerWidget {
  const RiderListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(riderListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('飞手排行榜', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(riderListProvider.notifier).loadRiders(),
          ),
        ],
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : state.error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(state.error!, style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.read(riderListProvider.notifier).loadRiders(),
                      child: const Text('重试'),
                    ),
                    if (_isAuthError(state.error)) ...[
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () => ref.read(authProvider.notifier).logout(),
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                        child: const Text('重新登录'),
                      ),
                    ],
                  ]),
                )
              : state.riders.isEmpty
                  ? const Center(child: Text('暂无飞手数据', style: TextStyle(color: AppColors.textSecondary)))
                  : _buildList(context, state.riders, ref),
    );
  }

  Widget _buildList(BuildContext context, List<RiderVo> riders, WidgetRef ref) {
    final top3 = riders.take(3).toList();
    final rest = riders.length > 3 ? riders.sublist(3) : <RiderVo>[];

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(riderListProvider.notifier).loadRiders();
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (top3.isNotEmpty) _buildPodium(context, top3),
          if (rest.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 20, 14, 8),
              child: Text('更多飞手', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
            ...rest.map((r) => GestureDetector(
              onTap: () => context.push('/rider/${r.riderId}'),
              child: _RiderRow(rider: r),
            )),
          ],
        ],
      ),
    );
  }

  // ==================== 领奖台 ====================
  Widget _buildPodium(BuildContext context, List<RiderVo> top3) {
    // 1st: center, 2nd: left, 3rd: right
    final first = top3[0];
    final second = top3.length > 1 ? top3[1] : null;
    final third = top3.length > 2 ? top3[2] : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 14, offset: Offset(0, 3))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (second != null) Expanded(child: GestureDetector(onTap: () => context.push('/rider/${second.riderId}'), child: _PodiumCard(rider: second, medal: 'silver', height: 145))),
          Expanded(child: GestureDetector(onTap: () => context.push('/rider/${first.riderId}'), child: _PodiumCard(rider: first, medal: 'gold', height: 175))),
          if (third != null) Expanded(child: GestureDetector(onTap: () => context.push('/rider/${third.riderId}'), child: _PodiumCard(rider: third, medal: 'bronze', height: 140))),
        ],
      ),
    );
  }
}

// ==================== 领奖台卡片 ====================
class _PodiumCard extends StatelessWidget {
  final RiderVo rider;
  final String medal; // gold / silver / bronze
  final double height;

  const _PodiumCard({required this.rider, required this.medal, required this.height});

  Color get _color {
    switch (medal) {
      case 'gold':
        return const Color(0xFFFFB800);
      case 'silver':
        return const Color(0xFFA0A8B8);
      case 'bronze':
        return const Color(0xFFCD7F32);
      default:
        return AppColors.primary;
    }
  }

  String get _medalEmoji {
    switch (medal) {
      case 'gold':
        return '🥇';
      case 'silver':
        return '🥈';
      case 'bronze':
        return '🥉';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 头像
          Container(
            width: medal == 'gold' ? 64 : 52,
            height: medal == 'gold' ? 64 : 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [_color.withAlpha(80), _color.withAlpha(40)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: _color, width: 2),
            ),
            child: Center(
              child: Text(
                rider.riderName.isNotEmpty ? rider.riderName[0] : '?',
                style: TextStyle(
                  fontSize: medal == 'gold' ? 26 : 22,
                  fontWeight: FontWeight.w800,
                  color: _color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 奖牌
          Text(_medalEmoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          // 姓名
          Text(
            rider.riderName,
            style: TextStyle(
              fontSize: medal == 'gold' ? 15 : 13,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${rider.totalCompleted}单',
            style: TextStyle(
              fontSize: 12,
              color: _color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== 普通飞手行 ====================
class _RiderRow extends StatelessWidget {
  final RiderVo rider;

  const _RiderRow({required this.rider});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(children: [
        // 头像
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.primaryLight, AppColors.primaryLight.withAlpha(80)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              rider.riderName.isNotEmpty ? rider.riderName[0] : '?',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // 姓名 + 今日接单
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(rider.riderName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('今日接单 ${rider.todayOrders}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ),
        // 总完成单量
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${rider.totalCompleted}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const Text('总完成单量', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
        ]),
      ]),
    );
  }
}
