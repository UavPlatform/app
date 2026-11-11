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
  final _formKey = GlobalKey<FormState>();
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
    if (_loading || !_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final ok = await ref
        .read(riderRegisterProvider.notifier)
        .register(
          userName: _userNameController.text,
          password: _passwordController.text,
        );

    if (!mounted) return;

    if (ok) {
      await ref
          .read(authProvider.notifier)
          .login(_userNameController.text, _passwordController.text);
      if (!mounted) return;
      final auth = ref.read(authProvider);
      if (auth.status == AuthStatus.authenticated) {
        context.go('/pilot/home');
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(auth.error ?? '账号已创建，请重新登录')));
        context.go('/login');
      }
    } else {
      setState(() => _loading = false);
      final error = ref.read(riderRegisterProvider).error;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error ?? '注册失败')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('飞手注册'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              children: [
                const SizedBox(height: 24),
                const _EnrollmentSteps(),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _userNameController,
                  validator: (value) =>
                      (value ?? '').trim().isEmpty ? '请输入用户名' : null,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: '请输入用户名',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  validator: (value) =>
                      (value ?? '').length < 6 ? '密码至少 6 位' : null,
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
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  validator: (value) => (value ?? '').isEmpty
                      ? '请确认密码'
                      : value != _passwordController.text
                      ? '两次密码不一致'
                      : null,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _register(),
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
                        : const Text('注册飞手', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '已有账号？',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: const Text(
                        '返回登录',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EnrollmentSteps extends StatelessWidget {
  const _EnrollmentSteps();

  @override
  Widget build(BuildContext context) {
    const steps = ['创建飞手账号', '补充实名与证件资料', '登记执飞机型和执照等级'];
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text('入驻步骤', style: theme.textTheme.titleSmall),
            for (final (index, label) in steps.indexed)
              Row(
                spacing: 8,
                children: [
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    child: Text(
                      '${index + 1}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                  Expanded(
                    child: Text(label, style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
