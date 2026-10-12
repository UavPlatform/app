// 首页 = 吊运发单主战场（REQ-APP-002 / ADR-0003，UI 重构版）：
//   沉浸式地图（起吊点=当前定位，卸货点=地图选点） + 悬浮起终点双竖线卡片
//   （起吊点展示逆地理编码的「人话」地址，不再暴露经纬度） + 紧凑物资表单
//   + 发布 TRANSPORT（发单不支付，支付在选定飞手后）。
// 已移除：服务四宫格、热门飞手推荐、任务广场、本人已发任务列表（任务列表
//   收敛到「订单」Tab，首页只专注「发单」一件事）。

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../api/generated/openapi_models.dart';
import '../../providers/location_provider.dart';
import '../../providers/task_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/scroll_pickers.dart';
import '../../widgets/mission_design.dart';

/// 吊运任务类型（后端 TaskType.TRANSPORT；C 端唯一品类，REQ-APP-002 验收 1）。
const String kTransportTaskType = 'TRANSPORT';

/// 货物类别 → 中文标签；新增类别需由后端同步支持。
const Map<String, String> kCargoCategoryLabels = {
  'CONSTRUCTION': '建材',
  'EQUIPMENT': '设备',
  'AGRICULTURAL': '农产品',
  'DAILY_SUPPLIES': '生活物资',
  'FURNITURE': '家具家居',
};

/// 货物类别 → 图标（图标+文字快捷选项，增强点击欲与辨识度）。
/// 首页标题城市：定位中 / 城市名 / 定位不可用（不展示「未知城市」占位）。
String homeCityTitle(LocationState location) {
  if (location.loading) return '定位中...';
  const placeholders = {'未知城市', '服务暂不可用', '定位中...', ''};
  if (!placeholders.contains(location.city)) return location.city;
  return '定位不可用';
}

const Map<String, IconData> _cargoCategoryIcons = {
  'CONSTRUCTION': Icons.construction,
  'EQUIPMENT': Icons.precision_manufacturing,
  'AGRICULTURAL': Icons.agriculture,
  'DAILY_SUPPLIES': Icons.shopping_basket_outlined,
  'FURNITURE': Icons.chair_outlined,
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

  /// 卫星影像底图（高德，无标注）。
  static const String _satelliteTileUrl =
      'https://webst0{s}.is.autonavi.com/appmaptile'
      '?style=6&x={x}&y={y}&z={z}';

  /// 地名/POI 文字标注透明层（叠加在卫星图上，显示地名）。
  static const String _labelTileUrl =
      'https://wprd0{s}.is.autonavi.com/appmaptile'
      '?x={x}&y={y}&z={z}&lang=zh_cn&size=1&scl=1&style=8&ltype=4';

  String? _category;
  final _weightController = TextEditingController();
  final _volumeController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _expectedDate;
  TimeOfDay? _expectedTime;
  LatLng? _destination;

  /// 定位不可用时用户可在地图上手动选起吊点；非空时优先于当前定位。
  LatLng? _manualStart;
  bool _submitting = false;
  bool _mapReady = false;
  bool _sheetExpanded = true;
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

  Future<void> _pickStartManually() async {
    final result = await context.push<String>('/map/pick?point=start');
    if (result == null || !mounted) return;
    final first = result.split(';').first.split(',');
    if (first.length != 2) return;
    final lat = double.tryParse(first[0]);
    final lng = double.tryParse(first[1]);
    if (lat == null || lng == null) return;
    final point = LatLng(lat, lng);
    setState(() => _manualStart = point);
    _recenter(point);
  }

  void _useCurrentLocation() {
    setState(() => _manualStart = null);
    ref.read(locationProvider.notifier).refresh();
  }

  LatLng? _effectiveStart(LocationState location) {
    if (_manualStart != null) return _manualStart;
    if (location.latitude != null && location.longitude != null) {
      return LatLng(location.latitude!, location.longitude!);
    }
    return null;
  }

  void _setDestination(LatLng point) {
    setState(() => _destination = point);
  }

  void _clearDestination() {
    setState(() => _destination = null);
  }

  /// 期望作业时间（可选）：日期 + 时间用滚轮选择器一次选完，
  /// 避免原生 Material 选择器，观感更贴合品牌。
  Future<void> _pickExpectedTime() async {
    final date = await showScrollDatePicker(
      context,
      initial: _expectedDate ?? DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showScrollTimePicker(
      context,
      initial: _expectedTime ?? TimeOfDay.now(),
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
      _manualStart = null;
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
    final start = _effectiveStart(ref.read(locationProvider));
    if (start == null) {
      _showError('无法获取当前位置，请点击「起吊点」在地图上手动选择');
      return;
    }
    final startLat = start.latitude;
    final startLng = start.longitude;

    final categoryLabel = kCargoCategoryLabels[_category]!;
    final descriptionParts = <String>[
      if (volumeText.isNotEmpty) '体积：$volumeText m³',
      if (_descriptionController.text.trim().isNotEmpty)
        _descriptionController.text.trim(),
    ];

    setState(() => _submitting = true);
    // 发单不支付（ADR-0003）：仅创建 TRANSPORT 任务，不携带任何客户端价格，
    // 不触发任何支付/下单接口；支付发生在用户选定飞手并下单时。
    final request = ApiTaskDto(
      taskName: '$categoryLabel吊运',
      type: kTransportTaskType,
      description: descriptionParts.join('\n'),
      waypoints: [
        ApiWaypointDto(orderIndex: 0, longitude: startLng, latitude: startLat),
        ApiWaypointDto(
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('发布成功，等待飞手应征')));
      _resetForm();
      unawaited(ref.read(taskListProvider.notifier).loadTasks());
    } else {
      final error = ref.read(taskProvider).error;
      _showError(error ?? '发布失败');
    }
  }

  /// 起吊点展示文本：优先逆地理编码地址，退化为城市，最后才兜底提示。
  String _startLabel(LocationState location) {
    if (_manualStart != null) {
      return '${_manualStart!.latitude.toStringAsFixed(5)}, '
          '${_manualStart!.longitude.toStringAsFixed(5)}';
    }
    if (location.loading) return '定位中...';
    final address = location.address;
    if (address != null && address.isNotEmpty) return address;
    if (location.city.isNotEmpty && location.city != '未知城市') {
      return location.city;
    }
    return '定位不可用，点击在地图上选择起吊点';
  }

  String _startModeLabel(LocationState location) {
    if (_manualStart != null) return '手动选择';
    if (location.latitude != null && location.longitude != null) {
      return '当前定位';
    }
    return '待选择';
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 沉浸式地图背景（整块可点击选卸货点）
          Positioned.fill(child: _buildMap(location)),
          // 顶部定位条悬浮于地图之上
          if (!_sheetExpanded)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopBar(location),
            ),
          // 底部抽屉：起终点 + 货物表单，上滑展开盖住地图
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              final expanded = notification.extent > 0.32;
              if (expanded != _sheetExpanded)
                setState(() => _sheetExpanded = expanded);
              return false;
            },
            child: DraggableScrollableSheet(
              initialChildSize: 0.48,
              minChildSize: 0.28,
              maxChildSize: 0.9,
              builder: (context, scrollController) =>
                  _buildFormSheet(scrollController, location),
            ),
          ),
        ],
      ),
    );
  }

  /// 顶部定位条：城市名 + 下拉提示，点击刷新定位（悬浮于地图之上）。
  Widget _buildTopBar(LocationState location) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          elevation: 2,
          shadowColor: Color(0x18000000),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.fromLTRB(14, 10, 4, 10),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        homeCityTitle(location),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        location.address?.isNotEmpty == true
                            ? location.address!
                            : '定位当前作业区域',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '重新定位',
                  onPressed: () =>
                      ref.read(locationProvider.notifier).refresh(),
                  icon: Icon(
                    Icons.my_location,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 沉浸式地图：整块无边框，可点击任意位置设置卸货点；起终点卡片悬浮于底部。
  Widget _buildMap(LocationState location) {
    final LatLng? start = _effectiveStart(location);
    final LatLng center = _destination ?? start ?? _fallbackCenter;

    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 15,
              onMapReady: () => setState(() => _mapReady = true),
              onTap: (_, point) {
                if (!_sheetExpanded) _setDestination(point);
              },
              // 关闭双击缩放：单击即选点，避免 250ms 双击判定延迟。
              interactionOptions: InteractionOptions(
                flags:
                    InteractiveFlag.drag |
                    InteractiveFlag.pinchZoom |
                    InteractiveFlag.flingAnimation,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: _satelliteTileUrl,
                subdomains: const ['1', '2', '3', '4'],
                maxZoom: 18,
              ),
              TileLayer(
                urlTemplate: _labelTileUrl,
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
                          color: const Color(0xFF238561).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.my_location,
                            color: Color(0xFF238561),
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  if (_destination != null)
                    Marker(
                      point: _destination!,
                      width: 36,
                      height: 44,
                      child: Icon(
                        Icons.location_on,
                        color: AppColors.accent,
                        size: 34,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        // 提示角标（悬浮在地图左上）：告知用户地图可点击选卸货点。
        if (!_sheetExpanded)
          Positioned(
            left: 12,
            top: MediaQuery.paddingOf(context).top + 92,
            child: IgnorePointer(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _destination == null ? '点击地图选择卸货点' : '已选卸货点，点击地图可更改',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 起终点双竖线卡片：起吊点（当前定位，人话地址）+ 卸货点（地图选点）。
  Widget _buildRouteCard(LocationState location) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            _buildRouteRow(
              key: const ValueKey('home-start-point-tile'),
              dotColor: const Color(0xFF238561),
              title: _manualStart != null ? '起吊点（手动选择）' : '起吊点',
              subtitle: _startLabel(location),
              modeLabel: _startModeLabel(location),
              trailing: _manualStart != null
                  ? IconButton(
                      icon: const Icon(Icons.my_location, size: 20),
                      visualDensity: VisualDensity.compact,
                      tooltip: '改回当前定位',
                      onPressed: _useCurrentLocation,
                    )
                  : IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      visualDensity: VisualDensity.compact,
                      tooltip: '重新定位',
                      onPressed: () =>
                          ref.read(locationProvider.notifier).refresh(),
                    ),
              onTap: _pickStartManually,
            ),
            // 连接线（对齐圆点中心）。
            Row(
              children: [
                SizedBox(
                  width: 30,
                  height: 24,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        4,
                        (_) => Container(
                          width: 2,
                          height: 3,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(child: Divider(height: 24)),
              ],
            ),
            _buildRouteRow(
              key: const ValueKey('home-destination-row'),
              dotColor: AppColors.accent,
              title: '卸货点',
              subtitle: _destination == null ? '点击选择卸货点' : '已选择卸货点',
              modeLabel: null,
              trailing: _destination == null
                  ? Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.outline,
                    )
                  : IconButton(
                      icon: Icon(Icons.clear, size: 20),
                      visualDensity: VisualDensity.compact,
                      tooltip: '清除卸货点',
                      onPressed: _clearDestination,
                    ),
              onTap: _pickDestinationPrecisely,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteRow({
    Key? key,
    required Color dotColor,
    required String title,
    required String subtitle,
    String? modeLabel,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                title.startsWith('起吊点') ? '起' : '卸',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (modeLabel != null)
                        Text(
                          modeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  /// 底部抽屉：起终点卡片 + 货物详情 + 发布 CTA。
  Widget _buildFormSheet(
    ScrollController scrollController,
    LocationState location,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x140B3D66),
            blurRadius: 16,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                // 拖动手柄
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(2, 4, 2, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '创建吊运任务',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                _buildRouteCard(location),
                SizedBox(height: 14),
                Material(
                  color: Theme.of(context).colorScheme.surface,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 18, 16, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 3,
                              height: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '货物与作业信息',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        _buildCategoryField(),
                        SizedBox(height: 12),
                        _buildWeightVolumeFields(),
                        SizedBox(height: 16),
                        _buildDescriptionField(),
                        SizedBox(height: 12),
                        Divider(height: 1),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: _buildTimeField(),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12),
              ],
            ),
          ),
          Container(
            key: const ValueKey('home-publish-footer'),
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPublishButton(),
                SizedBox(height: 8),
                Text(
                  '发布后等待飞手报价，选择飞手后再确认支付',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFB9C3CE)
                        : const Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 货物类别：图标 + 文字快捷选项（ChoiceChip）。
  Widget _buildCategoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '货物类别 *',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: kCargoCategoryLabels.entries
              .map((e) {
                final icon =
                    _cargoCategoryIcons[e.key] ?? Icons.inventory_2_outlined;
                final selected = _category == e.key;
                final activeColor =
                    Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFFFB36D)
                    : AppColors.accentDark;
                return ChoiceChip(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  side: BorderSide(
                    color: selected
                        ? AppColors.accent
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
                  showCheckmark: false,
                  avatar: Icon(
                    icon,
                    size: 18,
                    color: selected
                        ? activeColor
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  label: Text(
                    e.value,
                    style: TextStyle(
                      color: selected
                          ? activeColor
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  selected: selected,
                  selectedColor: AppColors.accent.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.18
                        : 0.1,
                  ),
                  onSelected: (_) => setState(() => _category = e.key),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }

  /// 重量/体积：标准输入框 + 单位后缀，避免视觉上像禁用按钮。
  Widget _buildWeightVolumeFields() {
    return Column(
      children: [
        _buildMeasurementRow(
          label: '货物重量 *',
          fieldKey: 'home-cargo-weight-field',
          controller: _weightController,
          hint: '请输入重量',
          unit: 'kg',
        ),
        Divider(height: 1),
        _buildMeasurementRow(
          label: '货物体积',
          fieldKey: 'home-cargo-volume-field',
          controller: _volumeController,
          hint: '选填',
          unit: 'm³',
        ),
        Divider(height: 1),
      ],
    );
  }

  Widget _buildMeasurementRow({
    required String label,
    required String fieldKey,
    required TextEditingController controller,
    required String hint,
    required String unit,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 108,
          child: Text(label, style: TextStyle(fontSize: 15)),
        ),
        Expanded(
          child: TextField(
            key: ValueKey(fieldKey),
            controller: controller,
            textAlign: TextAlign.start,
            style: TextStyle(fontSize: 15),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: MissionFormStyles.input(
              context,
              hint: hint,
              unit: unit,
            ),
          ),
        ),
      ],
    );
  }

  /// 吊运说明：直接两行文本域（不再折叠），降低填写成本。
  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('吊运说明（选填）', style: TextStyle(fontSize: 15)),
        SizedBox(height: 8),
        Container(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            key: ValueKey('home-cargo-description-field'),
            controller: _descriptionController,
            maxLines: 2,
            maxLength: 500,
            onChanged: (_) => setState(() {}),
            decoration: MissionFormStyles.input(
              context,
              hint: '吊点位置、绑扎要求、现场联系人等',
            ),
          ),
        ),
      ],
    );
  }

  /// 期望作业时间：一行列表项，默认「现在」，点击弹日期+时间选择器。
  Widget _buildTimeField() {
    final hasTime = _expectedDate != null;
    return InkWell(
      onTap: _pickExpectedTime,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              Icons.schedule,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: 10),
            Text(
              '期望作业时间',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                hasTime
                    ? buildTaskTimeString(_expectedDate, _expectedTime)!
                    : '现在',
                style: TextStyle(
                  fontSize: 14,
                  color: hasTime
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.end,
                maxLines: 2,
              ),
            ),
            if (hasTime)
              IconButton(
                icon: Icon(Icons.clear, size: 18),
                visualDensity: VisualDensity.compact,
                tooltip: '恢复为现在',
                onPressed: _clearExpectedTime,
              )
            else
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.outline,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublishButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        onPressed: _submitting ? null : _publish,
        child: _submitting
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text('发布吊运需求'),
      ),
    );
  }
}
