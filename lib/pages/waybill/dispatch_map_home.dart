import '../../theme/dispatch_palette.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../models/dispatch_order.dart';
import '../../models/dispatch_tracking.dart';
import '../../widgets/mission_map.dart';
import '../../widgets/hud_surface.dart';
import 'dispatch_boarding_card.dart';

/// REQ-ALL-XC-004: a map and draggable order drawer share the same SSE snapshot.
class DispatchMapHome extends StatefulWidget {
  const DispatchMapHome({super.key, required this.orders});
  final List<DispatchOrder> orders;
  @override
  State<DispatchMapHome> createState() => _DispatchMapHomeState();
}

class _DispatchMapHomeState extends State<DispatchMapHome> {
  final _map = MissionMapController();
  final _drawer = DraggableScrollableController();
  String? _selected;
  String? _stop;
  bool _fitted = false;
  double _mapHeight = 0;
  ScrollController? _scroll;

  @override
  void didUpdateWidget(DispatchMapHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.orders.any((order) => order.id == _selected)) {
      _selected = null;
    }
    if (!dispatchMapStops(widget.orders).any((stop) => stop.id == _stop)) {
      _stop = null;
    }
    if (!_fitted &&
        _map.isAttached &&
        dispatchMapStops(widget.orders).isNotEmpty) {
      _fitted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_fit(dispatchMapStops(widget.orders)));
      });
    }
  }

  @override
  void dispose() {
    _drawer.dispose();
    _map.dispose();
    super.dispose();
  }

  Future<void> _fit(
    List<DispatchMapStop> stops, {
    bool expanded = false,
  }) async {
    if (stops.isEmpty || !_map.isAttached) return;
    try {
      await _map.fit(
        stops.map((stop) => stop.point).toList(),
        bottomInset: _mapHeight * (expanded ? .76 : .48),
      );
    } catch (_) {
      /* Map retry remains available in MissionMap. */
    }
  }

  void _expand() {
    if (_drawer.isAttached) {
      unawaited(
        _drawer.animateTo(
          .76,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        ),
      );
    }
  }

  void _chooseStop(String id) {
    final matches = dispatchMapStops(
      widget.orders,
    ).where((stop) => stop.id == id);
    if (matches.isEmpty) return;
    final stop = matches.first;
    setState(() {
      _stop = id;
      _selected = stop.orders.length == 1 ? stop.orders.single.id : null;
    });
    _expand();
    if (_scroll?.hasClients == true) {
      _scroll!.jumpTo(0);
    }
    unawaited(_fit([stop], expanded: true));
  }

  void _chooseOrder(DispatchOrder order) {
    setState(() => _selected = _selected == order.id ? null : order.id);
    final point = dispatchStart(order);
    if (point != null) {
      unawaited(
        _fit([
          DispatchMapStop('', point, [order]),
        ], expanded: true),
      );
    }
    _expand();
  }

  @override
  Widget build(BuildContext context) {
    final stops = dispatchMapStops(widget.orders);
    final scoped = stops.where((stop) => stop.id == _stop);
    final orders = scoped.isEmpty ? widget.orders : scoped.first.orders;
    final missing = widget.orders
        .where((order) => dispatchStart(order) == null)
        .length;
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        _mapHeight = constraints.maxHeight;
        return Stack(
          children: [
            Positioned.fill(
              child: MissionMap(
                controller: _map,
                center: stops.isEmpty
                    ? const LatLng(27.8981, 112.9193)
                    : stops.first.point,
                zoom: 13,
                orderMarkers: [
                  for (final stop in stops)
                    MissionOrderMarker(
                      id: stop.id,
                      point: stop.point,
                      label: stop.label,
                      color: _statusColor(stop.orders.first),
                      selected:
                          stop.id == _stop ||
                          stop.orders.any((order) => order.id == _selected),
                    ),
                ],
                onOrderMarkerTap: _chooseStop,
                onReady: () {
                  if (!_fitted && stops.isNotEmpty) {
                    _fitted = true;
                    unawaited(_fit(stops));
                  }
                },
              ),
            ),
            Positioned(
              top: 14,
              left: 12,
              right: 126,
              child: IgnorePointer(
                child: HudStatusCapsule(
                  activeCount: widget.orders
                      .where((order) => !order.completed && !order.cancelled)
                      .length,
                ),
              ),
            ),
            Positioned(
              right: 14,
              bottom: constraints.maxHeight * .47 + 12,
              child: HudGlass(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(
                      foregroundColor: dark ? Colors.white : hudInk,
                    ),
                    tooltip: '查看全部订单起点',
                    onPressed: stops.isEmpty
                        ? null
                        : () {
                            setState(() {
                              _stop = null;
                              _selected = null;
                            });
                            unawaited(_fit(stops));
                            if (_drawer.isAttached) {
                              unawaited(
                                _drawer.animateTo(
                                  .44,
                                  duration: const Duration(milliseconds: 240),
                                  curve: Curves.easeOut,
                                ),
                              );
                            }
                          },
                    icon: const Icon(
                      Icons.center_focus_strong_rounded,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
            DraggableScrollableSheet(
              controller: _drawer,
              initialChildSize: widget.orders.isEmpty
                  ? .62
                  : ((284 + (missing > 0 ? 28 : 0)) *
                            MediaQuery.textScalerOf(context).scale(1) /
                            constraints.maxHeight)
                        .clamp(.44, .94),
              minChildSize: .22,
              maxChildSize: .94,
              snap: true,
              snapSizes: const [.22, .44, .76, .94],
              builder: (context, controller) {
                _scroll = controller;
                return Material(
                  color: dark ? const Color(0xFF192B2A) : hudSand,
                  elevation: 10,
                  shadowColor: scheme.secondary.withValues(alpha: .16),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListView(
                    key: const ValueKey('dispatch-home-drawer'),
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
                    children: [
                      Center(
                        child: Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: scheme.outlineVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: hudTeal.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.route_rounded,
                              color: hudTeal,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _stop == null
                                  ? '我的吊运 · ${orders.length} 单'
                                  : '该起点 · ${orders.length} 单',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (_stop != null)
                            TextButton(
                              onPressed: () => setState(() {
                                _stop = null;
                                _selected = null;
                              }),
                              style: TextButton.styleFrom(
                                foregroundColor: hudTeal,
                              ),
                              child: const Text('全部订单'),
                            ),
                          if (_stop == null)
                            const Icon(
                              Icons.keyboard_arrow_up_rounded,
                              size: 18,
                              color: hudTeal,
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (widget.orders.isEmpty) ...[
                        const Icon(Icons.inventory_2_outlined, size: 34),
                        const SizedBox(height: 12),
                        const Center(
                          child: Text(
                            '暂无派单运单',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Center(
                          child: Text(
                            '创建第一单后，在地图上查看起点和进度。',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          key: const ValueKey('create-first-dispatch'),
                          style: FilledButton.styleFrom(
                            backgroundColor: hudAmber,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => context.push('/waybill/new'),
                          icon: const Icon(Icons.add),
                          label: const Text('创建第一单'),
                        ),
                      ],
                      if (missing > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            '$missing 单缺少有效起点坐标，仍可在下方查看',
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      for (final order in orders) ...[
                        _card(context, order),
                        const SizedBox(height: 12),
                      ],
                      if (orders.isNotEmpty)
                        Text(
                          '最近50笔 · 模拟支付，无真实资金变动',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Color _statusColor(DispatchOrder order) =>
      DispatchPalette.status(context, order.data.stage);

  Widget _card(BuildContext context, DispatchOrder order) =>
      DispatchBoardingCard(
        key: ValueKey('map-order-${order.id}'),
        order: order,
        selected: _selected == order.id,
        onTap: () => _chooseOrder(order),
        onDetails: () =>
            context.push('/dispatch/orders/${Uri.encodeComponent(order.id)}'),
      );
}
