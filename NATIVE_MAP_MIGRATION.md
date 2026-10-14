# 高德原生地图模块

当前地图与定位仅使用 Android 高德原生 SDK。旧瓦片地图、系统定位补偿及运行时回退开关已经移除。地图配置或加载失败会显示重试入口，不会切换渲染方案。

## 代码职责

- `lib/widgets/mission_map.dart`：共享地图视图、主题和地图类型切换。
- `lib/controllers/mission_map_controller.dart`：每个视图的通道、选点回调和相机控制。
- `lib/providers/map_provider.dart`：统一读取后端地图配置接口。
- `lib/services/location_service.dart`：高德定位通道、超时与请求释放。
- `android/app/src/main/kotlin/com/fuwaki/app/NativeAmapView.kt`：原生视图、标记和 Activity 生命周期。

地图使用 Hybrid Composition。默认道路地图，支持卫星图和道路夜间样式。固定 SDK 合包版本 `11.3.100_loc11.3.000_sea9.8.1`，避免地图与定位重复类。

## 配置与日志

地图与定位统一使用后端 `/task/init` 下发的 Key，不提供本地文件或构建参数配置入口。`securityKey` 是网页配置字段，原生 SDK 不使用它。

已移除 Key 和密钥专用打印。HTTP 调试日志对 JSON 中的 Key 字段脱敏，不打印请求头；发布版本不启用 HTTP 调试日志。
