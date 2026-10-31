# 高德原生地图模块

当前地图与定位仅使用 Android 高德原生 SDK。旧瓦片地图、系统定位补偿及运行时回退开关已经移除。地图配置或加载失败会显示重试入口，不会切换渲染方案。

## 代码职责

- `lib/widgets/mission_map.dart`：共享地图视图、主题和地图类型切换。
- `lib/controllers/mission_map_controller.dart`：每个视图的通道、选点回调和相机控制。
- `lib/providers/map_provider.dart`：统一读取后端地图配置接口。
- `lib/services/location_service.dart`：高德定位通道、超时与请求释放。
- `lib/services/place_search.dart`：POI 关键字搜索通道（`PlaceSearch`），结果解析与错误归一。
- `android/app/src/main/kotlin/com/fuwaki/app/NativeAmapView.kt`：原生视图、标记和 Activity 生命周期。
- `android/app/src/main/kotlin/com/fuwaki/app/PlaceSearchRequest.kt`：`PoiSearch` 检索，按地图中心距离排序，超时/取消与代次丢弃。

地图使用 Hybrid Composition。默认道路地图，支持卫星图和道路夜间样式。固定 SDK 合包版本 `11.3.100_loc11.3.000_sea9.8.1`，避免地图与定位重复类。

## 配置与日志

地图、定位与 POI 搜索统一使用后端 `GET /config/map` 下发的 Key，不提供本地文件或构建参数配置入口。`securityKey` 是网页配置字段，原生 SDK 不使用它。

## 地点搜索

选点页顶部搜索框走 Android 高德 SDK `PoiSearch`（与地图/定位同一个 Android SDK key），不经过后端，因此不需要新增接口或契约同步。

- 输入 350ms 防抖后检索，`PoiSearch` 结果以地图中心距离排序；城市仅作排序偏好，不限制行政区。
- 检索前统一调用 `ServiceSettings.updatePrivacyShow/updatePrivacyAgree` 并 `setApiKey`（POI 检索与地图/定位各自独立初始化）。
- 一次只保留一个在途请求：新关键词以 `SEARCH_CANCELLED` 结束旧请求，回调按代次丢弃过期结果；15s 超时返回 `SEARCH_TIMEOUT`。
- 结果列表展示名称与「行政区 + 地址」，选中后地图移动到该点并显示名称；确认时回传 `lat,lng;名称;地址`。
- 名称/地址以 `start.place`/`end.place`、`start.placeAddress`/`end.placeAddress` 存在本机草稿，**不在** `WaybillDraft.cloudFieldNames` 内，不会提交后端。
- 搜索失败（Key 无效、超限、频繁、断网）统一显示中文提示，不伪造结果。

已移除 Key 和密钥专用打印。HTTP 调试日志对 JSON 中的 Key 字段脱敏，不打印请求头；发布版本不启用 HTTP 调试日志。
