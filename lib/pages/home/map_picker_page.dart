// 地图选点页（单点模式）：全屏地图精挑一个坐标点，pop 返回 "lat,lng"。
// 由首页「卸货点」入口调起；沿用仓库既有 flutter_map 选点能力（REQ-APP-002）。

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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

  /// 起吊点选点：首页定位不可用时手动选择起吊点（`/map/pick?point=start`）。
  const MapPickerPage.start({super.key})
      : title = '选择起吊点',
        pointLabel = '起吊点';

  final String title;

  /// 选点含义（卸货点 / 起吊点），用于提示与结果卡片文案。
  final String pointLabel;

  @override
  ConsumerState<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends ConsumerState<MapPickerPage> {
  late MapController _mapController;
  LatLng? _point;

  static const _tileUrl =
      'https://webrd0{s}.is.autonavi.com/appmaptile'
      '?lang=zh_cn&size=1&scale=1&style=8&x={x}&y={y}&z={z}';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _setPoint(TapPosition position, LatLng point) {
    setState(() => _point = point);
  }

  void _confirm() {
    final point = _point;
    if (point == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请先在地图上选择${widget.pointLabel}')),
      );
      return;
    }
    context.pop('${point.latitude.toStringAsFixed(6)},'
        '${point.longitude.toStringAsFixed(6)}');
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(locationProvider);
    final center = LatLng(
      loc.latitude ?? 27.8981,
      loc.longitude ?? 112.9193,
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          // 地图区域
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outline),
              ),
              clipBehavior: Clip.hardEdge,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 16,
                  onTap: _setPoint,
                  // 关闭双击缩放：单击即选点，避免双击判定带来的选点延迟。
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.drag |
                        InteractiveFlag.pinchZoom |
                        InteractiveFlag.flingAnimation,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: _tileUrl,
                    subdomains: const ['1', '2', '3', '4'],
                    maxZoom: 18,
                  ),
                  // 我的位置
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: center,
                        width: 36,
                        height: 36,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.my_location,
                                color: Colors.blue, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // 已选卸货点
                  if (_point != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _point!,
                          width: 36,
                          height: 44,
                          child: const Icon(Icons.location_on,
                              color: Colors.red, size: 34),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // 提示文字
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.touch_app, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  _point == null ? '点击地图选择${widget.pointLabel}' : '再次点击可更改选择',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 已选点信息
          Expanded(
            child: Center(
              child: _point == null
                  ? Text(
                      '尚未选择${widget.pointLabel}',
                      style:
                          TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        child: ListTile(
                          leading: const Icon(Icons.location_on,
                              color: Colors.red),
                          title: Text(widget.pointLabel),
                          subtitle: Text(
                            '${_point!.latitude.toStringAsFixed(6)}, '
                            '${_point!.longitude.toStringAsFixed(6)}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => setState(() => _point = null),
                          ),
                        ),
                      ),
                    ),
            ),
          ),

          // 底部按钮
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _point == null
                          ? null
                          : () => setState(() => _point = null),
                      child: const Text('清空'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _confirm,
                      icon: const Icon(Icons.check, size: 20),
                      label: const Text('确认'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
