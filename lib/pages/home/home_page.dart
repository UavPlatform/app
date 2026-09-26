// 首页 = 吊运发单主战场（REQ-APP-002 / ADR-0003）：
//   地图起终点（起吊点=当前定位，卸货点=地图选点） + 物资表单（类别/重量/体积/说明/期望时间）
//   + 发布 TRANSPORT（发单不支付，支付在选定飞手后） + 本人已发任务摘要。
// 已移除：服务四宫格、热门飞手推荐、任务广场（多品类公域推荐位）。

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../models/create_task_request.dart';
import '../../models/task_vo.dart';
import '../../providers/location_provider.dart';
import '../../providers/task_provider.dart';
import '../../theme/app_colors.dart';

/// 吊运任务类型（后端 TaskType.TRANSPORT；C 端唯一品类，REQ-APP-002 验收 1）。
const String kTransportTaskType = 'TRANSPORT';

/// 货物类别 → 中文标签（对齐后端 CargoCategory 描述）。
const Map<String, String> kCargoCategoryLabels = {
  'CONSTRUCTION': '建材',
  'EQUIPMENT': '设备',
  'AGRICULTURAL': '农产品',
};

/// 组装提交给后端的 taskTime（t15 契约："yyyy-MM-dd HH:mm:ss"，空格分隔）。
String? buildTaskTimeString(DateTime? date, TimeOfDay? time) {
  if (date == null || time == null) return null;
  final yyyy = date.year.toString().padLeft(4, '0');
  final mm = date.month.toString().padLeft(2, '0');
  final dd = date.day.toString().padLeft(2, '0');
  final hh = time.hour.toString().padLeft(2, '0');
  final mi = time.minute.toString().padLeft(2, '0');
  return '$yyyy-$mm-$dd $hh:$mi:00';
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  /// 地图默认中心（定位不可用时，沿用仓库既有默认坐标）。
  static const LatLng _fallbackCenter = LatLng(27.8981, 112.9193);

  /// 地图平瓦地址（与既有选点组件一致，高德 Web 瓦片）。
  static const String _tileUrl =
      'https://webrd0{s}.is.autonavi.com/appmaptile'
      '?lang=zh_cn&size=1&scale=1&style=8&x={x}&y={y}&z={z}';

  String? _category;
  final _weightController = TextEditingController();
  final _volumeController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _expectedDate;
  TimeOfDay? _expectedTime;
  LatLng? _destination;
  bool _submitting = false;
  bool _mapReady = false;
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _weightController.dispose();
    _volumeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// 从选点页取回终点后，把视野移到终点，保证标记可见。
  void _recenter(LatLng point) {
    if (!_mapReady) return;
    try {
      _mapController.move(point, 16);
    } catch (_) {
      // 地图尚未完成首帧渲染时忽略，标记仍会随初始中心展示。
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// 打开全屏地图精挑卸货点（复用既有选点组件 single 模式）。
  Future<void> _pickDestinationPrecisely() async {
    final result = await context.push<String>('/map/pick');
    if (result == null || !mounted) return;
    final first = result.split(';').first.split(',');
    if (first.length != 2) return;
    final lat = double.tryParse(first[0]);
    final lng = double.tryParse(first[1]);
    if (lat == null || lng == null) return;
    final point = LatLng(lat, lng);
    setState(() => _destination = point);
    _recenter(point);
  }

  void _setDestination(LatLng point) {
    setState(() => _destination = point);
  }

  void _clearDestination() {
    setState(() => _destination = null);
  }

  /// 期望作业时间（可选）：日期 + 时间一次选完，避免出现只选其一的中间态。
  Future<void> _pickExpectedTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _expectedTime ?? TimeOfDay.now(),
    );
    if (time == null || !mounted) return;
    setState(() {
      _expectedDate = date;
      _expectedTime = time;
    });
  }

  void _clearExpectedTime() {
    setState(() {
      _expectedDate = null;
      _expectedTime = null;
    });
  }

  void _resetForm() {
    setState(() {
      _category = null;
      _weightController.clear();
      _volumeController.clear();
      _descriptionController.clear();
      _expectedDate = null;
      _expectedTime = null;
      _destination = null;
    });
  }

  Future<void> _publish() async {
    if (_category == null) {
      _showError('请选择货物类别');
      return;
    }
    final weightText = _weightController.text.trim();
    if (weightText.isEmpty) {
      _showError('请输入货物重量');
      return;
    }
    final weight = double.tryParse(weightText);
    if (weight == null) {
      _showError('请输入正确的货物重量');
      return;
    }
    if (weight <= 0) {
      _showError('货物重量必须为正数');
      return;
    }
    final volumeText = _volumeController.text.trim();
    if (volumeText.isNotEmpty) {
      final volume = double.tryParse(volumeText);
      if (volume == null) {
        _showError('请输入正确的货物体积');
        return;
      }
      if (volume <= 0) {
        _showError('货物体积必须为正数');
        return;
      }
    }
    if (_destination == null) {
      _showError('请选择卸货点');
      return;
    }
    final location = ref.read(locationProvider);
    final startLat = location.latitude;
    final startLng = location.longitude;
    if (startLat == null || startLng == null) {
      _showError('无法获取当前位置作为起吊点，请稍后重试');
      return;
    }

    final categoryLabel = kCargoCategoryLabels[_category]!;
    final descriptionParts = <String>[
      if (volumeText.isNotEmpty) '体积：$volumeText m³',
      if (_descriptionController.text.trim().isNotEmpty)
        _descriptionController.text.trim(),
    ];

    setState(() => _submitting = true);
    // 发单不支付（ADR-0003）：仅创建 TRANSPORT 任务，不携带任何客户端价格，
    // 不触发任何支付/下单接口；支付发生在用户选定飞手并下单时。
    final request = CreateTaskRequest(
      taskName: '$categoryLabel吊运',
      type: kTransportTaskType,
      description: descriptionParts.join('\n'),
      waypoints: [
        WaypointRequest(orderIndex: 0, longitude: startLng, latitude: startLat),
        WaypointRequest(
          orderIndex: 1,
          longitude: _destination!.longitude,
          latitude: _destination!.latitude,
        ),
      ],
      taskTime: buildTaskTimeString(_expectedDate, _expectedTime),
      cargoWeightKg: weight,
      cargoCategory: _category,
    );

    final success = await ref.read(taskProvider.notifier).createTask(request);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('发布成功，等待飞手应征')),
      );
      _resetForm();
      unawaited(ref.read(taskListProvider.notifier).loadTasks());
    } else {
      final error = ref.read(taskProvider).error;
      _showError(error ?? '发布失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationProvider);
    final taskState = ref.watch(taskListProvider);
    final activeTasks =
        taskState.tasks.where((t) => !t.isCompleted).toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => ref.read(locationProvider.notifier).refresh(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, color: AppColors.primary, size: 20),
              const SizedBox(width: 4),
              Text(
                location.loading ? '定位中...' : location.city,
                style: const TextStyle(fontSize: 16),
              ),
              const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          _buildMap(location),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(taskListProvider.notifier).loadTasks(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _buildPointCard(location),
                  const SizedBox(height: 16),
                  _buildCargoForm(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('我发布的任务'),
                  const SizedBox(height: 12),
                  ..._buildTaskSection(taskState, activeTasks),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _submitting ? null : _publish,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('发布吊运需求'),
            ),
          ),
        ),
      ),
    );
  }

  /// 地图区：固定在滚动区之外（避免与列表滚动手势冲突）。
  /// 起吊点=当前定位（蓝），点击地图任意位置=设置卸货点（红）。
  Widget _buildMap(LocationState location) {
    final LatLng? start = (location.latitude != null && location.longitude != null)
        ? LatLng(location.latitude!, location.longitude!)
        : null;
    final LatLng center = _destination ?? start ?? _fallbackCenter;

    return SizedBox(
      height: 200,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outline),
        ),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 15,
                onMapReady: () => setState(() => _mapReady = true),
                onTap: (_, point) => _setDestination(point),
                // 关闭双击缩放：单击即选点，避免 250ms 双击判定延迟。
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
                MarkerLayer(
                  markers: [
                    if (start != null)
                      Marker(
                        point: start,
                        width: 36,
                        height: 36,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.my_location,
                                color: Colors.blue, size: 18),
                          ),
                        ),
                      ),
                    if (_destination != null)
                      Marker(
                        point: _destination!,
                        width: 36,
                        height: 44,
                        child: const Icon(Icons.location_on,
                            color: Colors.red, size: 34),
                      ),
                  ],
                ),
              ],
            ),
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _destination == null ? '点击地图选择卸货点' : '已选卸货点，点击地图可更改',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 起吊点（当前定位）与卸货点（地图选点）信息卡。
  Widget _buildPointCard(LocationState location) {
    final bool hasStart =
        location.latitude != null && location.longitude != null;
    final String startText;
    if (location.loading) {
      startText = '定位中...';
    } else if (hasStart) {
      startText =
          '${location.latitude!.toStringAsFixed(5)}, ${location.longitude!.toStringAsFixed(5)}';
    } else {
      startText = '定位不可用，点击右侧重试';
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.my_location, color: Colors.blue),
            title: const Text('起吊点（当前定位）'),
            subtitle: Text(startText),
            trailing: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.read(locationProvider.notifier).refresh(),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.location_on, color: Colors.red),
            title: const Text('卸货点'),
            subtitle: Text(
              _destination == null
                  ? '点击上方地图，或打开地图精挑'
                  : '${_destination!.latitude.toStringAsFixed(5)}, ${_destination!.longitude.toStringAsFixed(5)}',
            ),
            trailing: _destination == null
                ? const Icon(Icons.chevron_right, color: AppColors.outline)
                : IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: '清除卸货点',
                    onPressed: _clearDestination,
                  ),
            onTap: _pickDestinationPrecisely,
          ),
        ],
      ),
    );
  }

  /// 物资表单：类别（必选）、重量（必填正数）、体积（选填）、吊运说明（可折叠）、期望时间（可选）。
  Widget _buildCargoForm() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('物资信息',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('货物类别 *',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kCargoCategoryLabels.entries
                  .map(
                    (e) => ChoiceChip(
                      label: Text(e.value),
                      selected: _category == e.key,
                      onSelected: (_) => setState(() => _category = e.key),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('home-cargo-weight-field'),
                    controller: _weightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: '重量 *',
                      hintText: '例如 12.5',
                      suffixText: 'kg',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    key: const ValueKey('home-cargo-volume-field'),
                    controller: _volumeController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: '体积（选填）',
                      hintText: '例如 2.5',
                      suffixText: 'm³',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('吊运说明',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text(
                _descriptionController.text.isEmpty ? '点击展开填写' : '已填写',
                style: const TextStyle(fontSize: 12),
              ),
              children: [
                TextField(
                  key: const ValueKey('home-cargo-description-field'),
                  controller: _descriptionController,
                  maxLines: 4,
                  maxLength: 500,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: '吊点位置、绑扎要求、现场联系人等',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, size: 18,
                    color: AppColors.onSurfaceVariant),
                const SizedBox(width: 6),
                const Text('期望作业时间（选填）',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const Spacer(),
                if (_expectedDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    tooltip: '清除期望时间',
                    onPressed: _clearExpectedTime,
                  ),
              ],
            ),
            OutlinedButton.icon(
              onPressed: _pickExpectedTime,
              icon: const Icon(Icons.event, size: 18),
              label: Text(
                _expectedDate == null
                    ? '选择日期与时间'
                    : buildTaskTimeString(_expectedDate, _expectedTime)!,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  List<Widget> _buildTaskSection(
    TaskListState taskState,
    List<TaskVo> activeTasks,
  ) {
    if (taskState.loading && taskState.tasks.isEmpty) {
      return [
        const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (taskState.error != null && taskState.tasks.isEmpty) {
      return [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  taskState.error!,
                  style: const TextStyle(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => ref.read(taskListProvider.notifier).loadTasks(),
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      ];
    }
    if (activeTasks.isEmpty) {
      return [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                '暂无进行中的任务，发布后将显示在这里',
                style:
                    TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
              ),
            ),
          ),
        ),
      ];
    }
    return activeTasks.map(_buildTaskCard).toList(growable: false);
  }

  Widget _buildTaskCard(TaskVo task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/order/${task.taskNum}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildStatusTag(task.taskStatus),
                  const Spacer(),
                  Text(
                    task.formattedCreateTime,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(task.taskName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              if (task.description != null &&
                  task.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(task.description!,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
              if (task.actionHint != null &&
                  task.actionHint!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        task.actionHint!,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTag(String status) {
    Color bgColor;
    Color textColor;
    String label;
    switch (status) {
      case 'IDLE':
        bgColor = AppColors.statusPending;
        textColor = AppColors.statusPendingText;
        label = '空闲中';
        break;
      case 'IN_PROGRESS':
        bgColor = AppColors.statusInProgress;
        textColor = AppColors.statusInProgressText;
        label = '执行中';
        break;
      case 'COMPLETED':
        bgColor = AppColors.statusCompleted;
        textColor = AppColors.statusCompletedText;
        label = '已完成';
        break;
      default:
        bgColor = AppColors.statusCancelled;
        textColor = AppColors.statusCancelledText;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 12, color: textColor)),
    );
  }
}
