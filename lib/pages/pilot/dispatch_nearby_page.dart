import '../../widgets/flow_ui.dart';
import 'dispatch_hall_ui.dart';
import '../../widgets/infinite_list.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/generated/openapi_models.dart';
import '../../models/dispatch_order.dart';
import '../../providers/dispatch_nearby_provider.dart';
import '../../providers/dispatch_order_provider.dart';
import '../../providers/map_provider.dart';
import '../../providers/waybill_draft_provider.dart';

class DispatchNearbyPage extends ConsumerWidget {
  const DispatchNearbyPage({super.key, this.orderId});
  final String? orderId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => _NearbyBody(
    key: ValueKey(ref.watch(waybillDraftScopeProvider)),
    orderId: orderId,
  );
}

class _NearbyBody extends ConsumerStatefulWidget {
  const _NearbyBody({super.key, this.orderId});
  final String? orderId;
  @override
  ConsumerState<_NearbyBody> createState() => _NearbyBodyState();
}

class _NearbyBodyState extends ConsumerState<_NearbyBody>
    with WidgetsBindingObserver {
  bool _enabled = false, _claiming = false, _stopping = false;
  bool _locationFailed = false, _stopUnconfirmed = false;
  bool _foreground = true, _routeActive = false;
  int _epoch = 0;
  String? _error;
  String? _sessionKey;
  ApiDispatchPositionVO? _position;
  Timer? _timer;
  Future<void>? _pending;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = ModalRoute.of(context)?.isCurrent ?? true;
    if (active == _routeActive) return;
    _routeActive = active;
    if (!active) {
      _epoch++;
      _timer?.cancel();
      _timer = null;
    } else if (_enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refresh();
      });
    }
  }

  @override
  void dispose() {
    _epoch++;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _timer?.cancel();
    _timer = null;
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground && _enabled && _routeActive) {
      _refresh();
    } else if (state != AppLifecycleState.resumed) {
      _epoch++;
    }
  }

  Future<void> _refresh() {
    if (_pending != null) return _pending!;
    return _pending = _locate().whenComplete(() {
      _pending = null;
      if (mounted &&
          _enabled &&
          _foreground &&
          _routeActive &&
          _timer == null) {
        _timer = Timer(Duration.zero, _refresh);
      }
    });
  }

  Future<void> _locate() async {
    final epoch = _epoch, scope = ref.read(waybillDraftScopeProvider);
    bool current() =>
        mounted &&
        _enabled &&
        _foreground &&
        _routeActive &&
        epoch == _epoch &&
        scope == ref.read(waybillDraftScopeProvider);
    if (!current()) return;
    _timer?.cancel();
    try {
      final api = ref.read(dispatchNearbyApiProvider);
      var key = _sessionKey;
      if (key == null) {
        key = await api.begin();
        if (!current()) {
          if (mounted && scope == ref.read(waybillDraftScopeProvider)) {
            await api.clear(key);
          }
          return;
        }
        _sessionKey = key;
      }
      final config = await ref.read(amapMapConfigProvider.future);
      if (!current()) return;
      final fix = await ref.read(dispatchLocationProvider).locate(config.key);
      if (!current()) return;
      final result = await api.update(fix, key);
      if (!current()) return;
      setState(() {
        _position = result;
        _locationFailed = false;
        _error = null;
      });
      ref.invalidate(dispatchNearbyHallProvider);
    } catch (_) {
      if (current()) {
        setState(() {
          _locationFailed = true;
          _error = '位置更新失败，请检查定位权限和网络';
        });
      }
    } finally {
      if (current()) _timer = Timer(const Duration(seconds: 60), _refresh);
    }
  }

  Future<void> _start() async {
    if (_stopping) return;
    setState(() {
      _enabled = true;
      _locationFailed = false;
      _error = null;
    });
    await _refresh();
  }

  Future<void> _stop() async {
    if (_stopping) return;
    final scope = ref.read(waybillDraftScopeProvider);
    final key = _sessionKey;
    _sessionKey = null;
    _epoch++;
    _timer?.cancel();
    setState(() {
      _enabled = false;
      _stopping = true;
      _position = null;
    });
    try {
      await _pending;
      if (!mounted || scope != ref.read(waybillDraftScopeProvider)) return;
      await ref.read(dispatchNearbyApiProvider).clear(key);
      if (mounted && scope == ref.read(waybillDraftScopeProvider)) {
        setState(() {
          _stopUnconfirmed = false;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted && scope == ref.read(waybillDraftScopeProvider)) {
        setState(() {
          _stopUnconfirmed = true;
          _error = '暂停结果未确认，请重试';
        });
      }
    } finally {
      if (mounted) setState(() => _stopping = false);
    }
  }

  Future<void> _claim(ApiDispatchNearbyOfferVO item) async {
    if (_claiming) return;
    final scope = ref.read(waybillDraftScopeProvider);
    setState(() => _claiming = true);
    try {
      final order = await ref
          .read(dispatchOrderApiProvider)
          .claim(item.offer!.orderId!, item.offer!.offerRevision!);
      if (!mounted || scope != ref.read(waybillDraftScopeProvider)) return;
      ref.invalidate(dispatchNearbyHallProvider);
      ref.invalidate(dispatchPilotOrdersProvider);
      ref.invalidate(dispatchPilotHallProvider);
      context.push('/pilot/dispatch/orders/${Uri.encodeComponent(order.id)}');
    } catch (error) {
      if (mounted && scope == ref.read(waybillDraftScopeProvider)) {
        setState(() => _error = '$error');
        ref.invalidate(dispatchNearbyHallProvider);
      }
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  Widget _buildHall() {
    final hall = ref.watch(dispatchNearbyHallProvider);
    if (hall.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (hall.error != null && hall.items.isEmpty) {
      return Center(
        child: TextButton(
          onPressed: () =>
              ref.read(dispatchNearbyHallProvider.notifier).load(refresh: true),
          child: const Text('附近订单查询失败，点击重试'),
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Text(
            '起点周边 ${hall.radiusKm} 公里 · 直线距离估算',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: InfiniteList(
            onRefresh: () => ref
                .read(dispatchNearbyHallProvider.notifier)
                .load(refresh: true),
            onLoadMore: () =>
                ref.read(dispatchNearbyHallProvider.notifier).load(),
            hasMore: hall.hasNext,
            loadingMore: hall.loading && hall.items.isNotEmpty,
            itemCount: hall.items.length,
            empty: const FlowEmptyState(
              title: '暂无附近待接订单',
              icon: Icons.radar_rounded,
            ),
            itemBuilder: (context, index) {
              final item = hall.items[index];
              return DispatchHallOfferCard(
                offer: DispatchOffer(item.offer!),
                distanceMeters: item.distanceMeters,
                highlighted: item.offer!.orderId == widget.orderId,
                onClaim: _claiming ? null : () => _claim(item),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationState = _enabled && _position != null
        ? ref.watch(dispatchNearbyHallProvider).locationState
        : null;
    final expiresAt = _position?.expiresAt;
    final needsLocation =
        _enabled &&
        (_locationFailed ||
            (expiresAt != null &&
                expiresAt <= DateTime.now().millisecondsSinceEpoch) ||
            (locationState != null && locationState != 'READY'));
    final action = _stopping
        ? '正在暂停…'
        : _stopUnconfirmed
        ? '重试暂停'
        : needsLocation
        ? '重新定位'
        : _enabled
        ? '暂停听单'
        : '开始听单';
    return Scaffold(
      appBar: AppBar(
        title: const Text('附近订单'),
        actions: [
          if (needsLocation)
            PopupMenuButton<void>(
              tooltip: '听单选项',
              itemBuilder: (_) => [
                PopupMenuItem(onTap: _stop, child: const Text('暂停听单')),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _stopping
                    ? null
                    : _stopUnconfirmed
                    ? _stop
                    : needsLocation
                    ? _refresh
                    : _enabled
                    ? _stop
                    : _start,
                child: Text(action),
              ),
            ),
          ),
          if (_error != null)
            Padding(padding: const EdgeInsets.all(8), child: Text(_error!))
          else if (needsLocation)
            const Text('位置已失效')
          else if (_enabled && _position == null)
            const Text('正在定位…'),
          if (_enabled && _position != null && !needsLocation)
            Expanded(child: _buildHall()),
        ],
      ),
    );
  }
}
