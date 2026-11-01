import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/dispatch_chat_api.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dispatch_order_provider.dart';
import '../../providers/waybill_draft_provider.dart';
import 'chat_detail_page.dart';

final dispatchChatApiProvider = Provider(
  (ref) => DispatchChatApi(ref.watch(httpClientProvider)),
);
final dispatchChatSessionProvider = FutureProvider.autoDispose
    .family<int, (String, int)>((ref, key) {
      final scope = ref.watch(waybillDraftScopeProvider);
      if (scope == null) throw StateError('请先登录');
      return ref.watch(dispatchChatApiProvider).open(key.$1, key.$2);
    });

// Keep observing the order while chatting; release/reassignment removes the old conversation.
class DispatchChatPage extends ConsumerWidget {
  const DispatchChatPage({
    super.key,
    required this.orderId,
    required this.version,
    this.pilot = false,
  });
  final String orderId;
  final int version;
  final bool pilot;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(
      pilot
          ? dispatchPilotOrderProvider(orderId)
          : dispatchOrderProvider(orderId),
    );
    return order.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => _unavailable(ref, '$error'),
      data: (order) {
        if (order.data.assignmentVersion != version ||
            order.waiting ||
            order.cancelled ||
            order.awaitingDeposit) {
          return _unavailable(ref, '本次接单已结束，请返回订单查看最新状态');
        }
        return ref
            .watch(dispatchChatSessionProvider((orderId, version)))
            .when(
              loading: () => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => _unavailable(ref, '$error'),
              data: (id) => ChatDetailPage(
                key: ValueKey('${ref.watch(waybillDraftScopeProvider)}/$id'),
                sessionId: id,
                sessionName: '订单聊天',
                orderId: orderId,
                orderStatus: order.stageLabel,
                readOnly: order.completed,
              ),
            );
      },
    );
  }

  Widget _unavailable(WidgetRef ref, String text) => Scaffold(
    appBar: AppBar(title: const Text('订单聊天')),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text),
          TextButton(
            onPressed: () {
              ref.invalidate(dispatchChatSessionProvider((orderId, version)));
              ref.invalidate(
                pilot
                    ? dispatchPilotOrderProvider(orderId)
                    : dispatchOrderProvider(orderId),
              );
            },
            child: const Text('重新查询'),
          ),
        ],
      ),
    ),
  );
}
