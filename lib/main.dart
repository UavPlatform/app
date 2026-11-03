import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'widgets/double_back_exit_dispatcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api/http_client.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/chat_provider.dart';
import 'services/chat_websocket_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  _setupDroneCheck();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MyApp(),
    ),
  );
}

void _setupDroneCheck() {
  HttpClient.onDroneRequired = () {
    final nav = rootNavigatorKey.currentState;
    if (nav == null) return;
    showDialog(
      context: nav.context,
      builder: (ctx) => AlertDialog(
        title: const Text('需要无人机信息'),
        // ADR-0007 #6/#9：不再在 app 手填无人机编号；由 djifly 连机自动记录。
        content: const Text(
          '无人机由 djifly 在连机时自动记录机型和机身号，无需在此填写。请在 djifly 连接飞机后重试。',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  };
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});
  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  late final DoubleBackExitDispatcher _back;
  GoRouter? _observedRouter;

  @override
  void initState() {
    super.initState();
    _back = DoubleBackExitDispatcher(
      showPrompt: () {
        final messenger = _messenger.currentState;
        messenger?.hideCurrentSnackBar();
        messenger?.showSnackBar(
          const SnackBar(
            content: Text('再按一次返回键退出'),
            duration: Duration(seconds: 2),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _observedRouter?.routeInformationProvider.removeListener(_back.reset);
    _back.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 401 刷新失败兜底（P1-4）与聊天实时链路生命周期（P1-3）。
    ref.watch(unauthorizedSessionGuardProvider);
    ref.watch(chatRealtimeLifecycleProvider);

    // 顶号提示（t28③，Q12=A）：WS 收到 4001 被新登录顶掉 → 上抛 UI。
    ref.listen<AsyncValue<ChatWebSocketStatus>>(chatStatusProvider, (
      prev,
      next,
    ) {
      if (next.value == ChatWebSocketStatus.superseded) {
        final nav = rootNavigatorKey.currentState;
        if (nav != null) {
          ScaffoldMessenger.of(
            nav.context,
          ).showSnackBar(const SnackBar(content: Text('账号已在其他设备登录')));
        }
      }
    });

    final router = ref.watch(goRouterProvider);
    if (_observedRouter != router) {
      _observedRouter?.routeInformationProvider.removeListener(_back.reset);
      _observedRouter = router;
      router.routeInformationProvider.addListener(_back.reset);
      _back.reset();
    }

    return MaterialApp.router(
      title: '飞翼通',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ref.watch(themeModeProvider),
      scaffoldMessengerKey: _messenger,
      routeInformationProvider: router.routeInformationProvider,
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
      backButtonDispatcher: _back,
      // Keep Android root backs in Flutter, including predictive-back devices.
      onNavigationNotification:
          !kIsWeb && defaultTargetPlatform == TargetPlatform.android
          ? (_) {
              unawaited(SystemNavigator.setFrameworkHandlesBack(true));
              return true;
            }
          : null,
      debugShowCheckedModeBanner: false,
    );
  }
}
