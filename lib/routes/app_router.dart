import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../pages/splash/splash_page.dart';
import '../pages/splash/onboarding_page.dart';
import '../pages/auth/login_page.dart';
import '../pages/home/home_page.dart';
import '../pages/orders/order_list_page.dart';
import '../pages/orders/order_detail_page.dart';
import '../pages/messages/message_list_page.dart';
import '../pages/profile/profile_page.dart';
import '../pages/profile/address_list_page.dart';
import '../pages/profile/address_edit_page.dart';
import '../pages/publish/publish_page.dart';
import '../widgets/app_bottom_nav.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final goRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    // 启动页
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashPage(),
    ),
    // 引导页
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
    // 登录页
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    // 发布任务
    GoRoute(
      path: '/publish',
      builder: (context, state) => const PublishPage(),
    ),
    // 订单详情
    GoRoute(
      path: '/order/:id',
      builder: (context, state) => OrderDetailPage(
        orderId: state.pathParameters['id']!,
      ),
    ),
    // 地址管理
    GoRoute(
      path: '/addresses',
      builder: (context, state) => const AddressListPage(),
    ),
    // 新增/编辑地址
    GoRoute(
      path: '/address/edit',
      builder: (context, state) => const AddressEditPage(),
    ),
    // 底部导航 Shell
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => AppBottomNav(child: child),
      routes: [
        GoRoute(
          path: '/',
          redirect: (_, __) => '/home',
        ),
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomePage(),
          ),
        ),
        GoRoute(
          path: '/orders',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: OrderListPage(),
          ),
        ),
        GoRoute(
          path: '/messages',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: MessageListPage(),
          ),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfilePage(),
          ),
        ),
      ],
    ),
  ],
);
