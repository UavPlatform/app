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
import '../pages/publish/publish_page.dart';
import '../pages/publish/map_picker_page.dart';
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
  final authState = ref.watch(authProvider);
  final isPilot = authState.user?.isPilot ?? false;

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final isAuthPage = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/rider/register' ||
          state.matchedLocation == '/splash' ||
          state.matchedLocation == '/onboarding';

      if (!isLoggedIn && !isAuthPage) return '/login';
      if (isLoggedIn && isAuthPage) {
        return isPilot ? '/pilot/tasks' : '/home';
      }
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
        path: '/publish',
        builder: (context, state) => const PublishPage(),
      ),
      GoRoute(
        path: '/publish/map',
        builder: (context, state) => const MapPickerPage(),
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
            path: '/messages',
            pageBuilder: (context, state) => const NoTransitionPage(child: MessageListPage()),
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
});
