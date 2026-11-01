import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/dispatch_provider.dart';

class DispatchFeesCard extends ConsumerWidget {
  const DispatchFeesCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
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
              children: [
                const Text(
                  '已确认费用',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: '下单定金',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF555555),
                          ),
                          children: [
                            TextSpan(
                              text: '（结算时抵扣）',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF888888),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '¥${settings.depositAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D6FE9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        '飞手服务费',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF555555),
                        ),
                      ),
                    ),
                    Text(
                      '¥${settings.pilotServiceFee.toStringAsFixed(2)}/单',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF222222),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Color(0xFF999999),
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '定金为预付款，最终费用以结算账单为准。',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    ),
  );
}
