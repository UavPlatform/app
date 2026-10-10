import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../pages/splash/splash_page.dart';
import '../pages/splash/onboarding_page.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/register_page.dart';
import '../pages/home/home_page.dart';
import '../pages/orders/order_list_page.dart';
import '../pages/orders/order_detail_page.dart';
import '../pages/messages/message_list_page.dart';
import '../pages/profile/profile_page.dart';
import '../pages/profile/address_list_page.dart';
import '../pages/profile/address_edit_page.dart';
import '../pages/home/map_picker_page.dart';
import '../pages/pilot/task_hall_page.dart';
import '../pages/pilot/my_jobs_page.dart';
import '../pages/pilot/pilot_profile_page.dart';
import '../pages/pilot/drone_manage_page.dart';
import '../pages/auth/rider_register_page.dart';
import '../pages/chat/chat_detail_page.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/pilot_bottom_nav.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _userShellKey = GlobalKey<NavigatorState>();
final _pilotShellKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  // 认证态变化只触发 redirect 重算（refreshListenable），不得重建 GoRouter：
  // 重建会把导航重置回 initialLocation(/splash)，表现为「注册/登录后被踢回
  // 启动页→引导页→登录页」（TASK-APP-006 修复前复现）。
  final authRefresh = ValueNotifier<int>(0);
  ref.listen<AuthState>(authProvider, (_, _) => authRefresh.value++);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final location = state.matchedLocation;
      final isAuthPage = location == '/login' ||
          location == '/register' ||
          location == '/rider/register' ||
          location == '/splash' ||
          location == '/onboarding';

      if (!isLoggedIn) {
        // 401 刷新失败被强制登出（sessionExpired）：仅从启动页/引导页直达
        // 登录页，不再经过启动页/引导页（P1-4）。注册页必须放行——否则登录页
        // 点「用户注册/飞手注册」会被重定向回登录页，表现为点击无效
        // （TASK-APP-006 用户实测根因）。
        final skipToLogin = authState.sessionExpired &&
            (location == '/splash' || location == '/onboarding');
        if (skipToLogin || !isAuthPage) return '/login';
      }
      if (isLoggedIn && isAuthPage) {
        final isPilot = authState.user?.isPilot ?? false;
        return isPilot ? '/pilot/tasks' : '/home';
      }
      // 一级「消息」Tab 已移除（REQ-APP-002 三 Tab）：旧深链统一落到订单列表。
      if (location == '/messages') return '/orders';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/map/pick',
        builder: (context, state) =>
            state.uri.queryParameters['point'] == 'start'
                ? const MapPickerPage.start()
                : const MapPickerPage(),
      ),
      GoRoute(
        path: '/chat/:sessionId',
        builder: (context, state) => ChatDetailPage(
          sessionId: int.parse(state.pathParameters['sessionId']!),
          sessionName: state.uri.queryParameters['otherUserName'] ??
              state.uri.queryParameters['name'],
        ),
      ),
      GoRoute(
        path: '/order/:taskNum',
        builder: (context, state) => OrderDetailPage(
          taskNum: state.pathParameters['taskNum']!,
        ),
      ),
      GoRoute(
        path: '/addresses',
        builder: (context, state) => const AddressListPage(),
      ),
      GoRoute(
        path: '/pilot/drones',
        builder: (context, state) => const DroneManagePage(),
      ),
      GoRoute(
        path: '/rider/register',
        builder: (context, state) => const RiderRegisterPage(),
      ),
      GoRoute(
        path: '/address/edit',
        builder: (context, state) => const AddressEditPage(),
      ),

      // ========== 用户端底部导航 ==========
      ShellRoute(
        navigatorKey: _userShellKey,
        builder: (context, state, child) => AppBottomNav(child: child),
        routes: [
          GoRoute(
            path: '/',
            redirect: (_, __) => '/home',
          ),
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(child: HomePage()),
          ),
          GoRoute(
            path: '/orders',
            pageBuilder: (context, state) => const NoTransitionPage(child: OrderListPage()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(child: ProfilePage()),
          ),
        ],
      ),

      // ========== 飞手端底部导航 ==========
      ShellRoute(
        navigatorKey: _pilotShellKey,
        builder: (context, state, child) => PilotBottomNav(child: child),
        routes: [
          GoRoute(
            path: '/pilot/tasks',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TaskHallPage()),
          ),
          GoRoute(
            path: '/pilot/jobs',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MyJobsPage()),
          ),
          GoRoute(
            path: '/pilot/messages',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MessageListPage()),
          ),
          GoRoute(
            path: '/pilot/profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PilotProfilePage()),
          ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    authRefresh.dispose();
    router.dispose();
  });
  return router;
});
