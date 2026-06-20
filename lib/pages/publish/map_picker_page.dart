import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../providers/location_provider.dart';
import '../../theme/app_colors.dart';

class MapPickerPage extends ConsumerStatefulWidget {
  const MapPickerPage({super.key});

  @override
  ConsumerState<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends ConsumerState<MapPickerPage> {
  late MapController _mapController;
  final List<LatLng> _waypoints = [];

  static const _tileUrl =
      'https://webrd0{s}.is.autonavi.com/appmaptile'
      '?lang=zh_cn&size=1&scale=1&style=8&x={x}&y={y}&z={z}';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  void _addWaypoint(TapPosition position, LatLng point) {
    setState(() => _waypoints.add(point));
  }

  void _removeWaypoint(int index) {
    setState(() => _waypoints.removeAt(index));
  }

  void _confirm() {
    if (_waypoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少添加一个航点')),
      );
      return;
    }
    final coords = _waypoints
        .map((p) => '${p.latitude.toStringAsFixed(6)},${p.longitude.toStringAsFixed(6)}')
        .join(';');
    context.pop(coords);
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(locationProvider);
    final center = LatLng(
      loc.latitude ?? 27.8981,
      loc.longitude ?? 112.9193,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('选择航点')),
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
                  onTap: _addWaypoint,
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
                            child: Icon(Icons.my_location, color: Colors.blue, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // 航点标记
                  MarkerLayer(
                    markers: List.generate(_waypoints.length, (i) {
                      return Marker(
                        point: _waypoints[i],
                        width: 36,
                        height: 44,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Icon(Icons.location_on, color: Colors.red, size: 26),
                          ],
                        ),
                      );
                    }),
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
                  _waypoints.isEmpty ? '点击地图添加航点' : '继续点击地图添加更多航点',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 已选航点列表
          Expanded(
            child: _waypoints.isEmpty
                ? Center(
                    child: Text(
                      '暂无航点，请点击地图添加',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _waypoints.length,
                    itemBuilder: (context, index) {
                      final p = _waypoints[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          dense: true,
                          leading: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            '航点 ${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            '${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () => _removeWaypoint(index),
                          ),
                        ),
                      );
                    },
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
                      onPressed: _waypoints.isEmpty
                          ? null
                          : () {
                              setState(() => _waypoints.clear());
                            },
                      child: const Text('清空'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _confirm,
                      icon: const Icon(Icons.check, size: 20),
                      label: Text('确认（${_waypoints.length}个点）'),
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
