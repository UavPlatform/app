import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPointPicker extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final void Function(double lat, double lng) onPointPicked;

  const MapPointPicker({
    super.key,
    required this.initialLat,
    required this.initialLng,
    required this.onPointPicked,
  });

  @override
  State<MapPointPicker> createState() => _MapPointPickerState();
}

class _MapPointPickerState extends State<MapPointPicker> {
  late MapController _mapController;
  LatLng? _selectedPoint;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  void _onTap(TapPosition position, LatLng point) {
    setState(() => _selectedPoint = point);
    widget.onPointPicked(point.latitude, point.longitude);
  }

  static const _tileUrl =
      'https://webrd0{s}.is.autonavi.com/appmaptile'
      '?lang=zh_cn&size=1&scale=1&style=8&x={x}&y={y}&z={z}';

  @override
  Widget build(BuildContext context) {
    final center = LatLng(widget.initialLat, widget.initialLng);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 360,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          clipBehavior: Clip.hardEdge,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 15,
              onTap: _onTap,
            ),
            children: [
              TileLayer(
                urlTemplate: _tileUrl,
                subdomains: const ['1', '2', '3', '4'],
                maxZoom: 18,
              ),
              if (_selectedPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPoint!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _selectedPoint != null
              ? '已选: ${_selectedPoint!.latitude.toStringAsFixed(6)}, ${_selectedPoint!.longitude.toStringAsFixed(6)}'
              : '点击地图选择航点位置',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
