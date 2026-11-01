import '../../widgets/flow_ui.dart';
import '../../providers/waybill_draft_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../api/generated/openapi_models.dart';
import '../../providers/dispatch_flight_provider.dart';
import '../../widgets/mission_map.dart';
import 'dispatch_live_panel.dart';

/// Actual samples are grouped by connection; never draw a line across an aircraft swap.
List<List<LatLng>> flightSegments(List<ApiFlightSampleVO> samples) {
  final groups = <String, List<ApiFlightSampleVO>>{};
  for (final s in samples) {
    if (s.connectionId != null &&
        s.sequence != null &&
        s.latitude != null &&
        s.longitude != null) {
      (groups[s.connectionId!] ??= []).add(s);
    }
  }
  return groups.values.map((items) {
    items.sort((a, b) => a.sequence!.compareTo(b.sequence!));
    return items.map((s) => LatLng(s.latitude!, s.longitude!)).toList();
  }).toList();
}

/// Straight-line estimate from current real measurements; never used for price or business transitions.
int? flightEtaSeconds(
  ApiFlightViewVO? view,
  double? distance, {
  bool requestFailed = false,
}) {
  final sample = view?.latest;
  final point = view?.lastPosition;
  if (requestFailed ||
      view?.stale != false ||
      sample?.flying != true ||
      sample?.latitude == null ||
      sample?.longitude == null ||
      sample?.connectionId != view?.connection?.connectionId ||
      sample?.sampleId != point?.sampleId ||
      distance == null ||
      !distance.isFinite ||
      distance < 0 ||
      sample?.speed == null ||
      !sample!.speed!.isFinite ||
      sample.speed! <= 0) {
    return null;
  }
  final seconds = distance / sample.speed!;
  return seconds.isFinite ? seconds.ceil() : null;
}

class DispatchFlightPanel extends ConsumerStatefulWidget {
  const DispatchFlightPanel({
    super.key,
    required this.orderId,
    this.destination,
  });
  final String orderId;
  final LatLng? destination;
  @override
  ConsumerState<DispatchFlightPanel> createState() =>
      _DispatchFlightPanelState();
}

class _DispatchFlightPanelState extends ConsumerState<DispatchFlightPanel> {
  final _map = MissionMapController();
  double? _remaining;
  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  String _value(num? v, String unit) => v == null ? '未知' : '$v $unit';
  Widget _metric(String key, String label, num? value) => Expanded(
    child: Semantics(
      label: '$label：${value ?? '未知'}',
      child: Container(
        height: 92,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _value(value, '').trim(),
              key: ValueKey('flight-$key'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2329),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
            ),
          ],
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dispatchFlightProvider(widget.orderId));
    final view = state.current;
    final sample = view?.latest;
    final point = view?.lastPosition;
    final position = point?.latitude == null || point?.longitude == null
        ? null
        : LatLng(point!.latitude!, point.longitude!);
    final stale = state.error != null || view?.stale != false;
    final eta = flightEtaSeconds(
      view,
      position == null ? null : _remaining,
      requestFailed: state.error != null,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '实际飞行数据',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2329),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => ref
                      .read(dispatchFlightProvider(widget.orderId).notifier)
                      .refresh(),
                  tooltip: '刷新飞行数据',
                  icon: const Icon(
                    Icons.refresh,
                    size: 20,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
            if (state.error != null) Text(state.error!),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: stale
                            ? const Color(0xFFFFA940)
                            : const Color(0xFF999999),
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          view?.connection == null
                              ? '尚未收到本单设备连接'
                              : '${view!.connection!.modelName} · ${shortReference(view.connection!.serialNumber ?? '')}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
                            height: 1.4,
                          ),
                        ),
                        Text(
                          stale ? '连接已结束或数据待更新；以下为最后收到的数值' : '正在接收设备数据',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (view?.connection?.overweight == true)
              const Text('货物重量上限超过目录载重，请飞手现场核对。'),
            if (view?.connection != null &&
                view?.connection?.maxPayloadKg == null)
              const Text('机型未匹配目录，载重提示不可用'),
            Row(
              children: [
                _metric('altitude', '相对高度(m)', sample?.altitude),
                const SizedBox(width: 8),
                _metric('speed', '水平速度(m/s)', sample?.speed),
                const SizedBox(width: 8),
                _metric('battery', '设备电量(%)', sample?.battery),
              ],
            ),
            Text(
              '飞行状态：${sample?.flying == null
                  ? '未知'
                  : sample!.flying!
                  ? '飞行中'
                  : '未飞行'}',
            ),
            if (position != null) ...[
              Text('最后位置接收时间：${point?.receivedAt ?? '未知'}'),
              SizedBox(
                height: 260,
                child: MissionMap(
                  controller: _map,
                  center: position,
                  destination: widget.destination,
                  onRemainingDistance: (meters) {
                    if (mounted && meters != _remaining) {
                      setState(() => _remaining = meters);
                    }
                  },
                  aircraft: position,
                  tracks: flightSegments(state.samples),
                  aircraftCoordinatesAreGps: true,
                  zoom: 15,
                ),
              ),
            ] else
              const Text('尚无本单实际位置，不绘制轨迹'),
            Text(
              '最后位置至卸货点直线距离：${_remaining == null ? '未知' : '${_remaining!.toStringAsFixed(0)} 米'}',
            ),
            if (view?.connectionHistory?.isNotEmpty == true)
              FlowDetailsLink(
                title: '本单设备与连接记录',
                summary:
                    '${view!.connectionHistory!.length} 次连接 · 查看完整机身号与连接时间',
                icon: Icons.sensors_rounded,
                builder: (_) => FlowDetailPage(
                  title: '设备连接记录',
                  scope: ref.read(waybillDraftScopeProvider),
                  builder: (_) => Consumer(
                    builder: (context, ref, _) {
                      final live = ref.watch(
                        dispatchFlightProvider(widget.orderId),
                      );
                      if (live.error != null) {
                        return const Center(child: Text('连接资料暂不可用，请返回重试'));
                      }
                      return FlowList(
                        children: [
                          for (final c in live.current?.connectionHistory ?? [])
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  spacing: 12,
                                  children: [
                                    Text(
                                      c.modelName ?? '未识别机型',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    FlowValue('机身号', c.serialNumber ?? '未知'),
                                    FlowValue('连接开始', c.openedAt ?? '未知'),
                                    FlowValue('连接结束', c.endedAt ?? '连接未结束'),
                                    if (c.endReason != null)
                                      FlowValue('结束原因', c.endReason!),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            Text(
              eta == null
                  ? '预计到达：暂无法估算，等待新位置和有效飞行速度'
                  : '预计到达（按当前速度直线估算）：约 ${(eta / 60).ceil()} 分钟',
            ),
            const Text('估算不含等待、装卸或航线绕行，不用于计费或确认送达。飞行控制请在 djifly 操作。'),
            DispatchLivePanel(orderId: widget.orderId),
          ],
        ),
      ),
    );
  }
}
