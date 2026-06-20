import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rider_account_provider.dart';

class RiderRegisterPage extends ConsumerStatefulWidget {
  const RiderRegisterPage({super.key});

  @override
  ConsumerState<RiderRegisterPage> createState() => _RiderRegisterPageState();
}

class _RiderRegisterPageState extends ConsumerState<RiderRegisterPage> {
  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _djiIdController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _userNameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _djiIdController.dispose();
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

    final ok = await ref.read(riderRegisterProvider.notifier).register(
      userName: _userNameController.text,
      password: _passwordController.text,
      djiId: _djiIdController.text.trim(),
    );

    if (!mounted) return;

    if (ok) {
      await ref.read(authProvider.notifier).login(
        _userNameController.text,
        _passwordController.text,
      );
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/pilot/tasks'));
      }
    } else {
      setState(() => _loading = false);
      final error = ref.read(riderRegisterProvider).error;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? '注册失败')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('飞手注册'), backgroundColor: Colors.transparent),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: AppColors.statusInProgress.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.person_add, size: 32, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(height: 16),
              const Text('飞手注册',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('注册成为飞手，接单赚钱',
                  style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
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
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: '请确认密码',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _djiIdController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _register(),
                decoration: const InputDecoration(
                  hintText: '无人机 DJI ID（选填，可后续绑定）',
                  prefixIcon: Icon(Icons.flight, size: 20),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('注册飞手', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('已有账号？',
                      style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Text('返回登录',
                        style: TextStyle(fontSize: 13, color: AppColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
