import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/mission_map_controller.dart';
import '../providers/map_provider.dart';
export '../controllers/mission_map_controller.dart';

/// Shared native AMap view for the home page and destination picker.
class MissionMap extends ConsumerStatefulWidget {
  const MissionMap({
    super.key,
    required this.controller,
    required this.center,
    this.start,
    this.destination,
    this.zoom = 16,
    this.onTap,
  });
  final MissionMapController controller;
  final LatLng center;
  final LatLng? start;
  final LatLng? destination;
  final double zoom;
  final ValueChanged<LatLng>? onTap;
  @override
  ConsumerState<MissionMap> createState() => _MissionMapState();
}

class _MissionMapState extends ConsumerState<MissionMap> {
  int? _viewId;
  bool _satellite = false;
  String? _error;
  Map<String, Object?> get _state => {
    'start': MissionMapController.coordinates(widget.start),
    'destination': MissionMapController.coordinates(widget.destination),
    'satellite': _satellite,
    'dark': Theme.of(context).brightness == Brightness.dark,
  };

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on PlatformException {
      if (mounted) {
        _detach();
        setState(() => _error = '地图加载失败，请重试');
      }
    }
  }

  void _created(int id) {
    if (!mounted) return;
    _viewId = id;
    widget.controller.attach(
      id,
      onTap: (point) {
        if (mounted) widget.onTap?.call(point);
      },
    );
    _update();
  }

  void _update() {
    if (widget.controller.isAttached) {
      unawaited(_guard(() => widget.controller.update(_state)));
    }
  }

  @override
  void didUpdateWidget(MissionMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller && _viewId != null) {
      oldWidget.controller.detach(_viewId!);
      _created(_viewId!);
    }
    _update();
    if (widget.controller.isAttached &&
        (oldWidget.center != widget.center || oldWidget.zoom != widget.zoom)) {
      unawaited(
        _guard(() => widget.controller.move(widget.center, widget.zoom)),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _update();
  }

  void _detach() {
    final id = _viewId;
    if (id != null) widget.controller.detach(id);
    _viewId = null;
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const Center(child: Text('当前平台暂不支持地图'));
    }
    final config = ref.watch(amapMapConfigProvider);
    if (config.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (config.hasError || _error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 36),
            const SizedBox(height: 12),
            Text(_error ?? '地图服务暂不可用'),
            TextButton(
              onPressed: () {
                _detach();
                setState(() => _error = null);
                ref.invalidate(amapMapConfigProvider);
              },
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    return Stack(
      children: [
        Positioned.fill(
          child: PlatformViewLink(
            viewType: 'com.fuwaki.app/amap',
            surfaceFactory: (context, controller) => AndroidViewSurface(
              controller: controller as AndroidViewController,
              gestureRecognizers: {
                Factory<OneSequenceGestureRecognizer>(
                  () => EagerGestureRecognizer(),
                ),
              },
              hitTestBehavior: PlatformViewHitTestBehavior.opaque,
            ),
            onCreatePlatformView: (params) {
              final controller = PlatformViewsService.initExpensiveAndroidView(
                id: params.id,
                viewType: 'com.fuwaki.app/amap',
                layoutDirection: TextDirection.ltr,
                creationParams: {
                  'apiKey': config.requireValue.key,
                  'center': MissionMapController.coordinates(widget.center),
                  'zoom': widget.zoom,
                  ..._state,
                },
                creationParamsCodec: const StandardMessageCodec(),
                onFocus: () => params.onFocusChanged(true),
              );
              controller.addOnPlatformViewCreatedListener(
                params.onPlatformViewCreated,
              );
              controller.addOnPlatformViewCreatedListener(_created);
              unawaited(_guard(controller.create));
              return controller;
            },
          ),
        ),
        Positioned(
          right: 12,
          top: MediaQuery.paddingOf(context).top + 10,
          child: FilledButton.tonalIcon(
            key: const ValueKey('map-type-toggle'),
            onPressed: () {
              setState(() => _satellite = !_satellite);
              _update();
            },
            icon: Icon(
              _satellite ? Icons.map_outlined : Icons.satellite_alt,
              size: 18,
            ),
            label: Text(_satellite ? '道路地图' : '卫星地图'),
          ),
        ),
      ],
    );
  }
}
