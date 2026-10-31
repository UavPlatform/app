// 地图选点页（单点模式）：全屏地图精挑一个坐标点，pop 返回 "lat,lng[;名称;地址]"。
// 由发单表单的起吊点/卸货点入口调起；使用共享高德原生地图选点能力（REQ-SHIP-PUB-002）。
// 顶部搜索框走 Android 高德 SDK POI 检索（`PlaceSearch`），选中结果后回填坐标并移动地图；
// 底部面板承载引导态/已选态与确认 CTA。

import 'dart:async';

import 'package:flutter/material.dart';
import '../../widgets/mission_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../providers/location_provider.dart';
import '../../models/amap_config.dart';
import '../../providers/map_provider.dart';
import '../../services/place_search.dart';
import '../../theme/app_colors.dart';

class MapPickerPage extends ConsumerStatefulWidget {
  const MapPickerPage({
    super.key,
    this.title = '选择卸货点',
    this.pointLabel = '卸货点',
  });

  const MapPickerPage.start({super.key}) : title = '选择起吊点', pointLabel = '起吊点';

  final String title;

  /// 选点含义（卸货点 / 起吊点），用于提示文案。
  final String pointLabel;

  @override
  ConsumerState<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends ConsumerState<MapPickerPage> {
  static const _searchDebounce = Duration(milliseconds: 350);

  late MissionMapController _mapController;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;
  int _searchSeq = 0;

  LatLng? _point;
  PlaceSearchResult? _place;
  List<PlaceSearchResult> _results = const [];
  bool _searching = false;
  bool _showResults = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _mapController = MissionMapController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _setPoint(LatLng point) {
    _searchFocus.unfocus();
    _searchController.clear();
    setState(() {
      _point = point;
      _place = null;
      _results = const [];
      _searchError = null;
      _showResults = false;
    });
  }

  void _confirm() {
    final point = _point;
    if (point == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('请先在地图上选择${widget.pointLabel}')));
      return;
    }
    final coordinates =
        '${point.latitude.toStringAsFixed(6)},'
        '${point.longitude.toStringAsFixed(6)}';
    final place = _place;
    // 名称/地址是可选的附加段；消费方只读第一段坐标（site_fields.dart）。
    final name = _segment(place?.name);
    final address = _segment(place?.description);
    context.pop(
      [coordinates, if (name.isNotEmpty) name, if (address.isNotEmpty) address]
          .join(';'),
    );
  }

  static String _segment(String? value) =>
      (value ?? '').replaceAll(';', '，').trim();

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final keyword = value.trim();
    if (keyword.isEmpty) {
      // 取消 = 作废代次：递增 _searchSeq，在途回调即使返回也丢弃。
      _searchSeq++;
      setState(() {
        _results = const [];
        _searching = false;
        _searchError = null;
        _showResults = false;
      });
      return;
    }
    _debounce = Timer(_searchDebounce, () => _runSearch(keyword));
    setState(() {});
  }

  Future<void> _runSearch(String keyword) async {
    final AmapConfig config;
    try {
      config = await ref.read(amapMapConfigProvider.future);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _showResults = true;
        _searchError = '地图服务暂不可用，无法搜索';
      });
      return;
    }
    // 等待配置期间关键词可能已改/已清空：只对当前输入发起检索。
    if (!mounted || _searchController.text.trim() != keyword) return;
    final seq = ++_searchSeq;
    setState(() {
      _searching = true;
      _showResults = true;
      _searchError = null;
      // 开搜即清旧列表，避免上一关键词结果在加载态残留。
      _results = const [];
    });
    try {
      final results = await ref
          .read(placeSearchProvider)
          .search(
            key: config.key,
            keyword: keyword,
            city: _city(),
            center: _sortOrigin(),
          );
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _results = results;
        _searching = false;
        _searchError = results.isEmpty ? '没有找到相关地点，换个关键词试试' : null;
      });
    } on PlaceSearchException catch (error) {
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _results = const [];
        _searching = false;
        _searchError = error.message;
      });
    } on Exception {
      // 兜底：任何未归一的通道异常都不能留下转圈状态。
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _results = const [];
        _searching = false;
        _searchError = '搜索失败，请稍后重试';
      });
    }
  }

  String? _city() {
    final city = ref.read(locationProvider).city;
    if (city.isEmpty || city == '定位中...' || city.startsWith('定位不可用')) {
      return null;
    }
    return city;
  }

  /// 排序原点：当前用定位坐标（非相机中心；以后可改为读相机）。
  LatLng _sortOrigin() {
    final loc = ref.read(locationProvider);
    return LatLng(loc.latitude ?? 27.8981, loc.longitude ?? 112.9193);
  }

  void _selectResult(PlaceSearchResult result) {
    _debounce?.cancel();
    _searchSeq++;
    _searchFocus.unfocus();
    _searchController.text = result.name;
    setState(() {
      _point = result.point;
      _place = result;
      _results = const [];
      _searching = false;
      _showResults = false;
      _searchError = null;
    });
    unawaited(_mapController.move(result.point, 17));
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchSeq++;
    _searchController.clear();
    setState(() {
      _results = const [];
      _searching = false;
      _showResults = false;
      _searchError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(locationProvider);
    final center = LatLng(loc.latitude ?? 27.8981, loc.longitude ?? 112.9193);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _buildSearchBar(),
          ),
        ),
      ),
      body: Stack(
        children: [
          // 沉浸式全屏地图
          Positioned.fill(
            child: MissionMap(
              controller: _mapController,
              center: center,
              start: loc.latitude != null && loc.longitude != null
                  ? center
                  : null,
              destination: _point,
              onTap: _setPoint,
            ),
          ),
          if (_showResults && (_results.isNotEmpty || _searchError != null))
            Positioned(
              left: 12,
              right: 12,
              top: 8,
              child: _buildResultPanel(),
            ),
          // 底部面板：引导态 / 已选态
          Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomPanel()),
        ],
      ),
    );
  }

  /// 顶部搜索框：输入即检索高德 POI（350ms 防抖），结果浮层覆盖地图。
  Widget _buildSearchBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: AppColors.onSurfaceVariant, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              key: const ValueKey('place-search-field'),
              controller: _searchController,
              focusNode: _searchFocus,
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              onTap: () {
                if (!_showResults &&
                    (_results.isNotEmpty || _searchError != null)) {
                  setState(() => _showResults = true);
                }
              },
              onSubmitted: (value) {
                _debounce?.cancel();
                final keyword = value.trim();
                if (keyword.isNotEmpty) unawaited(_runSearch(keyword));
              },
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: '搜索${widget.pointLabel}或附近建筑',
                hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
              ),
            ),
          ),
          if (_searching)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (_searchController.text.isNotEmpty)
            GestureDetector(
              key: const ValueKey('place-search-clear'),
              onTap: _clearSearch,
              child: Icon(
                Icons.close,
                color: AppColors.onSurfaceVariant,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultPanel() {
    final children = <Widget>[
      if (_searchError != null)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Text(
            _searchError!,
            key: const ValueKey('place-search-message'),
            style: TextStyle(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      for (final result in _results)
        ListTile(
          key: ValueKey('place-${result.id.isEmpty ? result.name : result.id}'),
          dense: true,
          leading: Icon(Icons.place_outlined, color: AppColors.primary),
          title: Text(
            result.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: result.description.isEmpty
              ? null
              : Text(
                  result.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
          onTap: () => _selectResult(result),
        ),
    ];
    return Material(
      key: const ValueKey('place-search-results'),
      color: AppColors.bgWhite,
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 320),
        child: children.isEmpty
            ? const SizedBox.shrink()
            : ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: children,
              ),
      ),
    );
  }

  /// 底部面板：未选显示引导，已选显示地点/坐标 + 确认 CTA。
  Widget _buildBottomPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _point == null ? _buildEmptyHint() : _buildSelected(),
        ),
      ),
    );
  }

  Widget _buildEmptyHint() {
    return Row(
      children: [
        Icon(Icons.touch_app, color: AppColors.primary, size: 22),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            '拖动地图，点击任意位置选择${widget.pointLabel}，或搜索地点',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelected() {
    final point = _point!;
    final place = _place;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on, color: Colors.red, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (place != null && place.name.isNotEmpty)
                    Text(
                      place.name,
                      key: const ValueKey('place-selected-name'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Text(
                    '${point.latitude.toStringAsFixed(6)}, '
                    '${point.longitude.toStringAsFixed(6)}',
                    style: TextStyle(
                      fontSize: place == null ? 15 : 12,
                      fontWeight: place == null
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: place == null
                          ? null
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                  if (place != null && place.description.isNotEmpty)
                    Text(
                      place.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '清除',
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _point = null;
                  _place = null;
                  _results = const [];
                  _searchError = null;
                  _showResults = false;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: _confirm,
            icon: const Icon(Icons.check, size: 20),
            label: const Text('确认'),
          ),
        ),
      ],
    );
  }
}
