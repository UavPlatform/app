# app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## OpenAPI 契约（消费侧）

后端契约由 backend 仓导出（`backend/spec/openapi/drone-backend.openapi.json`），本仓 **vendor + sha256 对账 + 生成物入库**。
决策见 `../docs/adr/0004-OpenAPI契约流水线与消费端接入.md`。

```
openapi/drone-backend.openapi.json    # vendor 进来的规格（本仓唯一事实源副本）
openapi/drone-backend.openapi.sha256  # 对账文件（sha256sum 格式）
lib/api/generated/openapi_paths.dart  # 生成的路径表 ApiPaths（端点常量 + 路径参数/查询参数构造器）
lib/api/generated/openapi_models.dart # 生成的契约模型 ApiResult<T> / Api<Schema>
tool/sha256.dart                      # 纯 Dart sha256（工具链自检，无第三方依赖）
tool/openapi_sync.dart                # vendor + 写 sha256
tool/openapi_gen.dart                 # 生成（--check 只校验漂移）
```

| 目的 | 命令 |
|---|---|
| vendor 规格 | `dart run tool/openapi_sync.dart` |
| 生成契约代码 | `dart run tool/openapi_gen.dart` |
| 校验生成物未过期（CI/门禁） | `dart run tool/openapi_gen.dart --check` |
| 契约门禁 + 全量测试 | `flutter test`（含 `test/api_contract_test.dart`） |
| 类型/静态门禁 | `flutter analyze` |

写调用点的固定动作：

1. **URL 只允许来自 `ApiPaths`**：普通端点用常量（`ApiPaths.taskList`），带路径参数用 `ApiPaths.xxxPath(...)`，带查询参数用 `ApiPaths.xxxQuery(...)`——路径写错、必填查询参数漏传会在编译期暴露；
2. **响应只允许经 `Api<Schema>` 解析**：`lib/models/**` 保留面向 UI 的模型（字段名/可空性/默认值不变），但 `fromJson` 必须从生成的契约模型取值，后端改字段名会在这里编译失败；
3. 新增调用点时先在 `tool/openapi_gen.dart` 的 `endpoints` 登记并重跑生成器，门禁会核对「登记表 ↔ 代码」双向一致；
4. 契约与代码不一致时**先改后端注解并重新导出**，不要在端上绕过。
