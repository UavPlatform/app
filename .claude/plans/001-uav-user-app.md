# 无人机服务用户端 App 实施计划

## 项目定位

**飞翼通** - 无人机服务用户端 App（类似滴滴乘客端）
- 用户发布无人机服务需求（航拍、植保、巡检等）
- 等待飞手接单、报价
- 确认订单、支付（模拟）
- 查看任务进度、验收、评价

## 一、技术栈选型

| 类别 | 方案 | 依赖包 |
|------|------|--------|
| 状态管理 | Provider | `provider` |
| 路由 | go_router | `go_router` |
| 屏幕适配 | flutter_screenutil | `flutter_screenutil` |
| 本地存储 | shared_preferences | `shared_preferences` |
| 轮播图 | carousel_slider | `carousel_slider` |
| 图标 | flutter_svg | `flutter_svg` |

## 二、全局设计规范

### 色彩体系（Material Design 3 蓝色系）
- Primary: `#1565C0` - 主按钮、导航栏
- Primary Container: `#D1E4FF` - 选中态背景
- Surface: `#FAFCFF` - 页面背景
- Surface Variant: `#E7EEF6` - 卡片背景
- Error: `#BA1A1A` - 错误/紧急
- Success: `#2E7D32` - 成功状态

### 字体层次
- Display Large: 28sp Bold - 页面大标题
- Title Large: 20sp SemiBold - 区域标题
- Title Medium: 16sp Medium - 列表项标题
- Body Large: 16sp Regular - 正文
- Body Medium: 14sp Regular - 辅助说明
- Label Small: 12sp Regular - 标签、时间戳

### 间距 & 圆角
- 页面内边距: 16dp
- 卡片间距: 12dp
- 卡片圆角: 16dp
- 按钮圆角: 12dp
- 输入框圆角: 12dp

## 三、页面清单 & 实施顺序

### 阶段 1：基础框架
1. **依赖配置** - pubspec.yaml 添加所需依赖
2. **主题系统** - app_theme.dart (色彩、字体、形状)
3. **路由配置** - app_router.dart (go_router)
4. **底部导航栏** - MainShell (首页/订单/消息/我的)
5. **模拟数据** - MockData 服务

### 阶段 2：登录流程
6. **启动页** - SplashPage (品牌展示)
7. **引导页** - OnboardingPage (3页滑动介绍)
8. **登录页** - LoginPage (手机号+验证码)

### 阶段 3：首页
9. **首页** - HomePage
   - 顶部定位+搜索栏
   - Banner 轮播
   - 服务分类网格（8类）
   - 进行中任务卡片
   - 热门飞手横向滚动
   - 最新任务列表

### 阶段 4：任务发布
10. **任务发布页** - PublishPage (4步流程)
    - Step 1: 选择服务类型
    - Step 2: 填写详情（时间/地点/描述/图片/预算）
    - Step 3: 确认信息 + 费用预估
    - Step 4: 提交成功

### 阶段 5：订单管理
11. **订单列表页** - OrderListPage
    - Tab 筛选（全部/待接单/进行中/已完成）
    - 订单卡片（状态标签+信息）
    - 空状态设计
12. **订单详情页** - OrderDetailPage
    - 状态进度条
    - 任务信息区
    - 飞手信息区（接单后）
    - 费用明细
    - 操作按钮（按状态变化）

### 阶段 6：消息 & 个人中心
13. **消息列表页** - MessageListPage
    - 系统通知入口
    - 聊天消息列表
14. **个人中心页** - ProfilePage
    - 用户信息头部
    - 订单快捷入口
    - 功能菜单列表
15. **地址管理页** - AddressListPage + AddressEditPage

## 四、项目目录结构

```
lib/
├── main.dart
├── app.dart
├── theme/
│   ├── app_theme.dart
│   └── app_colors.dart
├── routes/
│   └── app_router.dart
├── models/
│   ├── user_model.dart
│   ├── order_model.dart
│   ├── service_type_model.dart
│   ├── pilot_model.dart
│   └── address_model.dart
├── services/
│   └── mock_data_service.dart
├── pages/
│   ├── splash/
│   │   ├── splash_page.dart
│   │   └── onboarding_page.dart
│   ├── auth/
│   │   └── login_page.dart
│   ├── home/
│   │   ├── home_page.dart
│   │   └── widgets/
│   ├── publish/
│   │   ├── publish_page.dart
│   │   └── steps/
│   ├── orders/
│   │   ├── order_list_page.dart
│   │   ├── order_detail_page.dart
│   │   └── widgets/
│   ├── messages/
│   │   └── message_list_page.dart
│   └── profile/
│       ├── profile_page.dart
│       ├── address_list_page.dart
│       └── address_edit_page.dart
└── widgets/
    ├── app_bottom_nav.dart
    ├── step_indicator.dart
    ├── status_tag.dart
    └── ...
```

## 五、模拟数据设计

### 用户数据
```dart
User(
  id: 'user_001',
  phone: '138****8888',
  nickname: '飞翼用户',
  avatar: null,
  balance: 5000.0,
)
```

### 服务类型（8类）
- 航拍摄影、农业植保、电力巡检、物流配送
- 测绘建模、应急救援、环境监测、活动跟拍

### 飞手数据（5位）
```dart
PilotInfo(
  id: 'pilot_001',
  nickname: '张师傅',
  rating: 4.9,
  completedOrders: 326,
  serviceTypes: ['航拍', '婚礼跟拍'],
  isVerified: true,
)
```

### 订单数据（6条，覆盖各状态）
- 2条待接单
- 2条进行中
- 1条待验收
- 1条已完成

## 六、实施步骤

1. 配置依赖 + 主题 + 路由
2. 实现模拟数据服务
3. 搭建底部导航框架
4. 实现登录流程（启动页→引导页→登录页）
5. 实现首页
6. 实现任务发布流程
7. 实现订单列表 + 详情
8. 实现消息列表
9. 实现个人中心 + 地址管理
10. 整体调试、优化

## 七、预估文件数量

- 模型文件: 5个
- 页面文件: 12个
- 组件文件: 10个
- 服务/工具: 3个
- 配置文件: 3个

**总计约 33 个 Dart 文件**
