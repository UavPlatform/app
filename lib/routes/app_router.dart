import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'page_transition.dart';
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
import '../pages/chat/chat_detail_page.dart';
import '../pages/riders/rider_list_page.dart';
import '../pages/riders/rider_detail_page.dart';
import '../widgets/app_bottom_nav.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _userShellKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final isAuthPage = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/splash' ||
          state.matchedLocation == '/onboarding';

      if (!isLoggedIn && !isAuthPage) return '/login';
      if (isLoggedIn && isAuthPage) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => AppTransitionPage(key: state.pageKey, child: const SplashPage()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => AppTransitionPage(key: state.pageKey, child: const OnboardingPage()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => AppTransitionPage(key: state.pageKey, child: const LoginPage()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => AppTransitionPage(key: state.pageKey, child: const RegisterPage()),
      ),
      GoRoute(
        path: '/publish',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: PublishPage(serviceType: state.extra as String?),
        ),
      ),
      GoRoute(
        path: '/publish/map',
        pageBuilder: (context, state) => AppTransitionPage(key: state.pageKey, child: const MapPickerPage()),
      ),
      GoRoute(
        path: '/chat/:sessionId',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: ChatDetailPage(
            sessionId: int.parse(state.pathParameters['sessionId']!),
            sessionName: state.uri.queryParameters['name'],
          ),
        ),
      ),
      GoRoute(
        path: '/order/:taskNum',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: OrderDetailPage(taskNum: state.pathParameters['taskNum']!),
        ),
      ),
      GoRoute(
        path: '/riders',
        pageBuilder: (context, state) => AppTransitionPage(key: state.pageKey, child: const RiderListPage()),
      ),
      GoRoute(
        path: '/rider/:riderId',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: RiderDetailPage(riderId: int.parse(state.pathParameters['riderId']!)),
        ),
      ),
      GoRoute(
        path: '/addresses',
        pageBuilder: (context, state) => AppTransitionPage(key: state.pageKey, child: const AddressListPage()),
      ),
      GoRoute(
        path: '/address/edit',
        pageBuilder: (context, state) => AppTransitionPage(key: state.pageKey, child: const AddressEditPage()),
      ),

      // ========== 底部导航 ==========
      ShellRoute(
        navigatorKey: _userShellKey,
        builder: (context, state, child) => AppBottomNav(child: child),
        routes: [
          GoRoute(path: '/', redirect: (_, _) => '/home'),
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => AppTransitionPage(key: state.pageKey, child: const HomePage()),
          ),
          GoRoute(
            path: '/orders',
            pageBuilder: (context, state) => AppTransitionPage(key: state.pageKey, child: const OrderListPage()),
          ),
          GoRoute(
            path: '/messages',
            pageBuilder: (context, state) => AppTransitionPage(key: state.pageKey, child: const MessageListPage()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => AppTransitionPage(key: state.pageKey, child: const ProfilePage()),
          ),
        ],
      ),
    ],
  );
});
