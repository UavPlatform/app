import '../../widgets/flow_ui.dart';
import '../../providers/waybill_draft_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../api/generated/openapi_models.dart';
import '../../providers/dispatch_flight_provider.dart';
import '../../widgets/mission_map.dart';
import 'dispatch_live_panel.dart';

LatLng? _position(ApiFlightEventVO? event) {
  final lat = event?.payload?['latitudeDegE7'];
  final lng = event?.payload?['longitudeDegE7'];
  if (lat is! num || lng is! num) return null;
  return LatLng(lat / 10000000, lng / 10000000);
}

ApiFlightEventVO? _event(ApiAircraft? aircraft, String type) {
  final raw = aircraft?.latest?[type];
  return raw is Map<String, dynamic> ? ApiFlightEventVO.fromJson(raw) : null;
}

ApiAircraft? _aircraft(ApiFlightProjectionVO? view) {
  final point = view?.lastPosition;
  final aircraft = view?.aircraft;
  if (point == null) return aircraft?.length == 1 ? aircraft!.first : null;
  return aircraft
      ?.where(
        (item) =>
            item.serialNumber == point.serialNumber &&
            item.serialSource == point.serialSource,
      )
      .firstOrNull;
}

num? _reading(ApiFlightEventVO? event, String field, int scale) {
  final value = event?.payload?[field];
  if (value is! num || !value.isFinite) return null;
  return value % scale == 0 ? value ~/ scale : value / scale;
}

bool? _flying(ApiAircraft? aircraft) {
  final value = _event(aircraft, 'ACTUAL_FLYING_STATE')?.payload?['flying'];
  return value is bool ? value : null;
}

/// Sort by capture time, then split at aircraft changes.
List<List<LatLng>> flightSegments(List<ApiFlightEventVO> samples) {
  final positions =
      samples
          .where(
            (event) =>
                event.type == 'POSITION' &&
                event.capturedAt != null &&
                event.serialNumber != null &&
                event.serialSource != null &&
                _position(event) != null,
          )
          .toList()
        ..sort((a, b) {
          final time = a.capturedAt!.compareTo(b.capturedAt!);
          return time == 0
              ? (a.eventId ?? '').compareTo(b.eventId ?? '')
              : time;
        });
  final segments = <List<LatLng>>[];
  (String?, String?)? previous;
  for (final event in positions) {
    final aircraft = (event.serialNumber, event.serialSource);
    if (aircraft != previous) segments.add([]);
    segments.last.add(_position(event)!);
    previous = aircraft;
  }
  return segments;
}

int? flightEtaSeconds(
  ApiFlightProjectionVO? view,
  double? distance, {
  bool requestFailed = false,
}) {
  final aircraft = _aircraft(view);
  final velocity = _event(aircraft, 'VELOCITY');
  final speed = _reading(velocity, 'speedMmps', 1000);
  final positionTime = view?.lastPosition?.capturedAt;
  final velocityTime = velocity?.capturedAt;
  if (requestFailed ||
      view?.stale != false ||
      aircraft?.stale != false ||
      _flying(aircraft) != true ||
      _position(view?.lastPosition) == null ||
      positionTime == null ||
      velocityTime == null ||
      (positionTime - velocityTime).abs() > 10000 ||
      distance == null ||
      !distance.isFinite ||
      distance < 0 ||
      speed == null ||
      speed <= 0) {
    return null;
  }
  final seconds = distance / speed;
  return seconds.isFinite ? seconds.ceil() : null;
}

class DispatchFlightPanel extends StatelessWidget {
  const DispatchFlightPanel({
    super.key,
    required this.orderId,
    this.destination,
  });
  final String orderId;
  final LatLng? destination;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      dense: true,
      leading: const Icon(Icons.sensors_rounded),
      title: const Text('实际飞行数据'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (context) => FractionallySizedBox(
          heightFactor: 0.9,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                ListTile(
                  title: const Text('实际飞行数据'),
                  trailing: IconButton(
                    tooltip: '关闭',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                    child: _FlightDetails(
                      orderId: orderId,
                      destination: destination,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _FlightDetails extends ConsumerStatefulWidget {
  const _FlightDetails({required this.orderId, required this.destination});
  final String orderId;
  final LatLng? destination;

  @override
  ConsumerState<_FlightDetails> createState() => _FlightDetailsState();
}

class _FlightDetailsState extends ConsumerState<_FlightDetails> {
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
        constraints: const BoxConstraints(minHeight: 70),
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
    final point = view?.lastPosition;
    final position = _position(point);
    final aircraft = _aircraft(view);
    final flying = _flying(aircraft);
    final altitude = _reading(_event(aircraft, 'ALTITUDE'), 'altitudeMm', 1000);
    final speed = _reading(_event(aircraft, 'VELOCITY'), 'speedMmps', 1000);
    final battery = _reading(_event(aircraft, 'BATTERY'), 'chargePermille', 10);
    final received = point?.receivedAt;
    final receivedAt = received == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(received).toLocal();
    final stale =
        state.error != null ||
        (position == null ? aircraft?.stale : view?.stale) != false;
    final signal = state.error != null
        ? '遥测更新失败${aircraft == null ? '' : '（显示最后记录值）'}'
        : aircraft == null && point == null
        ? '等待设备回传数据'
        : stale
        ? '信号更新延迟（显示最后记录值）'
        : '正在接收设备数据';
    final eta = flightEtaSeconds(
      view,
      position == null ? null : _remaining,
      requestFailed: state.error != null,
    );
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Row(
              spacing: 12,
              children: [
                _flightValue('位置', position == null ? '暂无实际位置' : '已收到实际位置'),
                _flightValue(
                  '距卸货点直线距离',
                  position == null || _remaining == null
                      ? '未知'
                      : '${_remaining!.toStringAsFixed(0)} 米',
                ),
                _flightValue(
                  '预计到达',
                  eta == null ? '暂无法估算' : '约 ${(eta / 60).ceil()} 分钟',
                ),
              ],
            ),
            Text(
              receivedAt == null
                  ? '最近更新：暂无记录'
                  : '最近更新：${MaterialLocalizations.of(context).formatShortDate(receivedAt)} ${TimeOfDay.fromDateTime(receivedAt).format(context)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              signal,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: stale
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Row(
              spacing: 8,
              children: [
                _metric('altitude', '相对高度(m)', altitude),
                _metric('speed', '水平速度(m/s)', speed),
                _metric('battery', '设备电量(%)', battery),
              ],
            ),
            DispatchLivePanel(orderId: widget.orderId),
            if (position != null)
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
            if (aircraft != null)
              Text(
                '${aircraft.modelCode ?? '未识别机型'} · ${shortReference(aircraft.serialNumber ?? '')}'
                '${flying == null
                    ? ''
                    : flying
                    ? ' · 飞行中'
                    : ' · 未飞行'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            Row(
              children: [
                _flightValue(
                  '飞行状态',
                  flying == null
                      ? '未知'
                      : flying
                      ? '飞行中'
                      : '未飞行',
                ),
              ],
            ),
            if (view?.flightPeriods?.isNotEmpty == true)
              FlowDetailsLink(
                title: '本单飞行记录',
                summary: '${view!.flightPeriods!.length} 段飞行',
                icon: Icons.sensors_rounded,
                builder: (_) => FlowDetailPage(
                  title: '飞行记录',
                  scope: ref.read(waybillDraftScopeProvider),
                  builder: (_) => FlowList(
                    children: [
                      for (final period in view.flightPeriods!)
                        Card(
                          child: ListTile(
                            title: Text(period.serialNumber ?? '未知机身号'),
                            subtitle: Text(
                              '${_eventTime(period.takeoffAt)} → ${_eventTime(period.landedAt)}',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            const Text(
              '估算不含等待、装卸或航线绕行，不用于计费或确认送达。飞行控制请在 djifly 操作。',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF9CA3AF),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _eventTime(int? value) => value == null
    ? '暂无记录'
    : DateTime.fromMillisecondsSinceEpoch(value).toLocal().toString();

Widget _flightValue(String label, String value, {String? tooltip}) => Expanded(
  child: Tooltip(
    message: tooltip ?? '$label：$value',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF333333),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  ),
);
