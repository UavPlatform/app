import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/dispatch_order_provider.dart';
import '../../utils/failure_message.dart';
import '../waybill/dispatch_order_information.dart';

class OrderHistoryPage extends ConsumerWidget {
  const OrderHistoryPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    backgroundColor: const Color(0xFFF3F4F6),
    appBar: AppBar(title: const Text('历史订单'), backgroundColor: Colors.white),
    body: ref
        .watch(dispatchOrdersProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(failureMessage(error, fallback: '历史订单暂时无法加载，请稍后重试')),
                  TextButton(
                    onPressed: () => ref.invalidate(dispatchOrdersProvider),
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          ),
          data: (orders) {
            final history = orders
                .where((order) => order.completed || order.cancelled)
                .toList();
            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 0, 4, 10),
                  child: Text(
                    '最近50笔订单中的已结单与已取消记录',
                    style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
                  ),
                ),
                if (history.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 80),
                    child: Center(child: Text('最近订单中暂无已结束记录')),
                  ),
                for (final order in history)
                  DispatchOrderCard(
                    order: order,
                    onTap: () => context.push(
                      '/dispatch/orders/${Uri.encodeComponent(order.id)}',
                    ),
                  ),
              ],
            );
          },
        ),
  );
}
