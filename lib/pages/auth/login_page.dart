import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/api_config.dart';
import '../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/token_storage.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _serverController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  bool _showServer = false;

  @override
  void initState() {
    super.initState();
    // 服务器地址预填：本地已存地址优先，新装首启回落内置默认环境（P1-5）。
    _serverController.text = ApiConfig.resolveBaseUrl(
      TokenStorage.normalizeHttpServerUrl(
        ref.read(tokenStorageProvider).getServerUrl(),
      ),
    );
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _passwordController.dispose();
    _serverController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_userNameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入用户名')));
      return;
    }
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入密码')));
      return;
    }

    setState(() => _loading = true);

    await ref
        .read(authProvider.notifier)
        .login(_userNameController.text, _passwordController.text);

    if (!mounted) return;
    setState(() => _loading = false);

    final authState = ref.read(authProvider);
    if (authState.status == AuthStatus.authenticated) {
      final isPilot = authState.user?.isPilot ?? false;
      context.go(isPilot ? '/pilot/tasks' : '/home');
    } else if (authState.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authState.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 32,
          right: 32,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.flight,
                  size: 44,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '欢迎使用飞翼通',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '无人机飞手接单平台',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _userNameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: '请输入用户名',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(),
                decoration: InputDecoration(
                  hintText: '请输入密码',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => setState(() => _showServer = !_showServer),
                child: Row(
                  children: [
                    Icon(
                      _showServer ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '服务器设置',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (_showServer) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _serverController,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: '公网示例 120.77.x.x:8888；局域网直连 192.168.x.x:8081',
                    prefixIcon: Icon(Icons.dns_outlined, size: 20),
                  ),
                  onChanged: (v) {
                    final url = TokenStorage.normalizeHttpServerUrl(v) ?? '';
                    ref.read(tokenStorageProvider).saveServerUrl(url);
                    ref.read(httpClientProvider).updateBaseUrl(url);
                  },
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('登 录', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '还没有账号？',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/register'),
                    child: const Text(
                      '用户注册',
                      style: TextStyle(fontSize: 13, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => context.push('/rider/register'),
                    child: const Text(
                      '飞手注册',
                      style: TextStyle(fontSize: 13, color: Color(0xFF2E7D32)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
