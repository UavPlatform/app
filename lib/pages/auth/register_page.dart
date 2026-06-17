import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _userNameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_userNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入用户名')),
      );
      return;
    }
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('密码至少6位')),
      );
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('两次密码不一致')),
      );
      return;
    }

    setState(() => _loading = true);

    await ref.read(authProvider.notifier).register(
          _userNameController.text,
          _passwordController.text,
        );

    if (!mounted) return;
    setState(() => _loading = false);

    final error = ref.read(authProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('注册成功，请登录')),
      );
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('注册'), backgroundColor: Colors.transparent),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 32),
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
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: '请输入密码（至少6位）',
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
              TextField(
                controller: _confirmController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _register(),
                decoration: const InputDecoration(
                  hintText: '请确认密码',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('注 册', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '已有账号？',
                    style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Text(
                      '返回登录',
                      style: TextStyle(fontSize: 13, color: AppColors.primary),
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
