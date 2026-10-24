import '../../widgets/flow_ui.dart';
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
  bool _foreground = true, _routeActive = false;
  int _epoch = 0, _page = 0;
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
        _error = null;
      });
      ref.invalidate(dispatchNearbyHallProvider);
    } catch (_) {
      if (current()) {
        setState(() => _error = '位置更新失败，请检查定位权限、定位开关和网络后重试。过期位置不会用于附近匹配。');
      }
    } finally {
      if (current()) _timer = Timer(const Duration(seconds: 60), _refresh);
    }
  }

  Future<void> _start() async {
    if (_stopping) return;
    setState(() {
      _enabled = true;
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
        setState(() => _error = null);
      }
    } catch (_) {
      if (mounted && scope == ref.read(waybillDraftScopeProvider)) {
        setState(() => _error = '停止结果未确认，请重试停止；此前有效期内的位置仍可能参与站内匹配。');
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('附近订单')),
    body: Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            '开启后，仅在本页前台定期更新位置，用于附近订单和站内新单通知。离开后停止更新，位置在有效期结束后失效。可随时停止并清除最新位置。手机系统推送尚未接入。',
          ),
        ),
        Wrap(
          spacing: 12,
          children: [
            FilledButton(
              onPressed: _enabled || _stopping ? null : _start,
              child: const Text('开启附近接单'),
            ),
            TextButton(
              onPressed: _stopping ? null : _stop,
              child: Text(_stopping ? '正在停止…' : '停止并清除位置'),
            ),
            if (_enabled)
              TextButton(
                onPressed: () {
                  _refresh();
                  ref.invalidate(dispatchNearbyHallProvider);
                },
                child: const Text('重新定位并刷新'),
              ),
          ],
        ),
        if (_enabled && _position == null)
          const Text('正在定位；定位失败时不会使用默认坐标或显示全部订单。'),
        if (_error != null)
          Padding(padding: const EdgeInsets.all(8), child: Text(_error!)),
        if (widget.orderId != null)
          const Text('来自历史派单通知。通知中的订单若未列出，可能已被接走、取消或离开附近范围。'),
        if (_enabled && _position != null)
          Expanded(
            child: ref
                .watch(dispatchNearbyHallProvider(_page))
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: TextButton(
                      onPressed: () =>
                          ref.invalidate(dispatchNearbyHallProvider(_page)),
                      child: const Text('附近订单查询失败，点击重试'),
                    ),
                  ),
                  data: (hall) => hall.locationState != 'READY'
                      ? Center(
                          child: TextButton(
                            onPressed: _refresh,
                            child: const Text('位置已失效，重新定位'),
                          ),
                        )
                      : Column(
                          children: [
                            Text('起点周边 ${hall.radiusKm} 公里 · 直线距离估算'),
                            Expanded(
                              child: hall.items!.isEmpty
                                  ? const Center(child: Text('本页暂无附近待接订单'))
                                  : FlowList(
                                      children: [
                                        for (final item in hall.items!)
                                          Card(
                                            child: ListTile(
                                              selected:
                                                  item.offer!.orderId ==
                                                  widget.orderId,
                                              title: Text(
                                                '${item.offer!.fields!['category']} · 距起点约 ${item.distanceMeters!.toStringAsFixed(0)} 米',
                                              ),
                                              subtitle: Text(
                                                '${item.offer!.fields!['start.site']} → ${item.offer!.fields!['end.site']}\n${dispatchWeightLabel(item.offer!.fields!)} · 飞手服务费 ¥${item.offer!.pilotServiceFee}',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              isThreeLine: true,
                                              trailing: TextButton(
                                                onPressed: _claiming
                                                    ? null
                                                    : () => _claim(item),
                                                child: const Text('接单'),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: _page == 0
                                      ? null
                                      : () => setState(() => _page--),
                                  child: const Text('上一页'),
                                ),
                                Text('第 ${_page + 1} 页'),
                                TextButton(
                                  onPressed: hall.hasNext == true
                                      ? () => setState(() => _page++)
                                      : null,
                                  child: const Text('下一页'),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
          ),
      ],
    ),
  );
}
