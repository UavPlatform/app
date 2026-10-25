import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/dispatch_provider.dart';

class DispatchFeesCard extends ConsumerWidget {
  const DispatchFeesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: ref
          .watch(dispatchSettingsProvider)
          .when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => Column(
              children: [
                const Text('平台金额暂时无法获取'),
                TextButton(
                  onPressed: () => ref.invalidate(dispatchSettingsProvider),
                  child: const Text('重新获取金额'),
                ),
              ],
            ),
            data: (settings) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                Text('已确认费用', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  '下单定金：¥${settings.depositAmount.toStringAsFixed(2)}（结算时抵扣）',
                ),
                const SizedBox(height: 8),
                Text('飞手服务费：¥${settings.pilotServiceFee.toStringAsFixed(2)}/单'),
                const SizedBox(height: 8),
                const Text('定金为预付款，最终费用以结算账单为准。'),
              ],
            ),
          ),
    ),
  );
}
