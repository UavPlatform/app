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
import '../widgets/app_bottom_nav.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
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
        path: '/order/:id',
        builder: (context, state) => OrderDetailPage(
          orderId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/addresses',
        builder: (context, state) => const AddressListPage(),
      ),
      GoRoute(
        path: '/address/edit',
        builder: (context, state) => const AddressEditPage(),
      ),
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
});
