import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('跳过'),
                ),
              ),
              Icon(
                Icons.flight_rounded,
                size: 52,
                color: theme.colorScheme.primary,
              ),
              Text(
                '开始使用飞翼通',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const ListTile(
                leading: Icon(Icons.pin_drop_outlined),
                title: Text('填写起终点与货物信息'),
                subtitle: Text('选好起吊点和卸货点，填写货重与现场条件。'),
              ),
              const ListTile(
                leading: Icon(Icons.route_outlined),
                title: Text('查看运单进度'),
                subtitle: Text('飞手接单后可在运单内沟通并追踪运输。'),
              ),
              FilledButton(
                onPressed: () => context.go('/login'),
                child: const Text('立即开始'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
