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
  bool _obscurePassword = true;
  bool _loading = false;
  bool _savingNetwork = false;

  @override
  void dispose() {
    _userNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _configureNetwork() async {
    final storage = ref.read(tokenStorageProvider);
    final url = await showDialog<String>(
      context: context,
      builder: (_) => _NetworkSettingsDialog(
        initialUrl: ApiConfig.resolveBaseUrl(storage.getServerUrl()),
      ),
    );
    if (!mounted || url == null) return;
    final client = ref.read(httpClientProvider);
    setState(() => _savingNetwork = true);
    try {
      await storage.saveServerUrl(url);
      client.updateBaseUrl(url);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('网络环境未保存，请重试')));
    } finally {
      if (mounted) setState(() => _savingNetwork = false);
    }
  }

  Future<void> _login() async {
    if (_loading || _savingNetwork) return;
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
      context.go(isPilot ? '/pilot/home' : '/home');
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
      appBar: AppBar(
        toolbarHeight: 44,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: '网络环境调试',
            onPressed: _loading || _savingNetwork ? null : _configureNetwork,
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 32,
          right: 32,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading || _savingNetwork ? null : _login,
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

class _NetworkSettingsDialog extends StatefulWidget {
  const _NetworkSettingsDialog({required this.initialUrl});
  final String initialUrl;

  @override
  State<_NetworkSettingsDialog> createState() => _NetworkSettingsDialogState();
}

class _NetworkSettingsDialogState extends State<_NetworkSettingsDialog> {
  late final _controller = TextEditingController(text: widget.initialUrl);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final url = TokenStorage.normalizeHttpServerUrl(_controller.text) ?? '';
    final uri = Uri.tryParse(url);
    if (url.isNotEmpty &&
        (uri == null ||
            !uri.hasAuthority ||
            uri.host.isEmpty ||
            uri.userInfo.isNotEmpty ||
            uri.hasQuery ||
            uri.hasFragment ||
            !const ['http', 'https'].contains(uri.scheme))) {
      setState(() => _error = '请输入有效的服务器地址');
      return;
    }
    Navigator.of(context).pop(url);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('网络环境调试'),
    scrollable: true,
    content: TextField(
      key: const Key('login_server_url'),
      controller: _controller,
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _save(),
      onChanged: (_) {
        if (_error != null) setState(() => _error = null);
      },
      decoration: InputDecoration(
        labelText: '服务器地址',
        helperText: '局域网示例：192.168.1.20:8081',
        errorText: _error,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(''),
        child: const Text('恢复默认'),
      ),
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('取消'),
      ),
      FilledButton(onPressed: _save, child: const Text('保存')),
    ],
  );
}
