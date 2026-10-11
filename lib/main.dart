import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
        title: const Text('需要绑定无人机'),
        content: const Text('您还没有绑定无人机，无法使用此功能。请先绑定至少一台无人机。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('稍后'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              GoRouter.of(nav.context).push('/pilot/drones');
            },
            child: const Text('去绑定'),
          ),
        ],
      ),
    );
  };
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return MaterialApp.router(
      title: '飞翼通',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
