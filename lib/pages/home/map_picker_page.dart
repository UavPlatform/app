// 地图选点页（单点模式）：全屏地图精挑一个坐标点，pop 返回 "lat,lng"。
// 由首页「卸货点」入口调起；使用共享高德原生地图选点能力（REQ-APP-002）。
// UI 重构：地图沉浸式铺满、顶部搜索框（POI 搜索待后端接口）、底部面板承载
// 引导态/已选态与确认 CTA，消除原「大面积无意义留白」。

import 'package:flutter/material.dart';
import '../../widgets/mission_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../providers/location_provider.dart';
import '../../theme/app_colors.dart';

class MapPickerPage extends ConsumerStatefulWidget {
  const MapPickerPage({
    super.key,
    this.title = '选择卸货点',
    this.pointLabel = '卸货点',
  });

  const MapPickerPage.start({super.key}) : title = '选择起吊点', pointLabel = '起吊点';

  final String title;

  /// 选点含义（卸货点 / 起吊点），用于提示文案。
  final String pointLabel;

  @override
  ConsumerState<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends ConsumerState<MapPickerPage> {
  late MissionMapController _mapController;
  LatLng? _point;

  @override
  void initState() {
    super.initState();
    _mapController = MissionMapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _setPoint(LatLng point) {
    setState(() => _point = point);
  }

  void _confirm() {
    final point = _point;
    if (point == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('请先在地图上选择${widget.pointLabel}')));
      return;
    }
    context.pop(
      '${point.latitude.toStringAsFixed(6)},'
      '${point.longitude.toStringAsFixed(6)}',
    );
  }

  void _showSearchHint() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('POI 搜索需后端提供搜索接口，即将上线')));
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(locationProvider);
    final center = LatLng(loc.latitude ?? 27.8981, loc.longitude ?? 112.9193);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _buildSearchBar(),
          ),
        ),
      ),
      body: Stack(
        children: [
          // 沉浸式全屏地图
          Positioned.fill(
            child: MissionMap(
              controller: _mapController,
              center: center,
              start: loc.latitude != null && loc.longitude != null
                  ? center
                  : null,
              destination: _point,
              onTap: _setPoint,
            ),
          ),
          // 底部面板：引导态 / 已选态
          Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomPanel()),
        ],
      ),
    );
  }

  /// 顶部搜索框（视觉骨架：真实 POI 搜索待后端接口）。
  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: _showSearchHint,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.bgWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: AppColors.onSurfaceVariant, size: 20),
            SizedBox(width: 8),
            Text(
              '搜索${widget.pointLabel}或附近建筑',
              style: TextStyle(color: AppColors.textHint, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  /// 底部面板：未选显示引导，已选显示坐标 + 确认 CTA。
  Widget _buildBottomPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _point == null ? _buildEmptyHint() : _buildSelected(),
        ),
      ),
    );
  }

  Widget _buildEmptyHint() {
    return Row(
      children: [
        Icon(Icons.touch_app, color: AppColors.primary, size: 22),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            '拖动地图，点击任意位置选择${widget.pointLabel}',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelected() {
    final point = _point!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on, color: Colors.red, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${point.latitude.toStringAsFixed(6)}, '
                '${point.longitude.toStringAsFixed(6)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '清除',
              onPressed: () => setState(() => _point = null),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: _confirm,
            icon: const Icon(Icons.check, size: 20),
            label: const Text('确认'),
          ),
        ),
      ],
    );
  }
}
