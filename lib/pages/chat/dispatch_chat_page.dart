import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/dispatch_api.dart';
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
      error: (error, _) => _unavailable(context, ref, error: error),
      data: (order) {
        if (order.data.assignmentVersion != version ||
            order.waiting ||
            order.cancelled ||
            order.completed ||
            order.awaitingDeposit) {
          return _unavailable(context, ref, ended: true);
        }
        return ref
            .watch(dispatchChatSessionProvider((orderId, version)))
            .when(
              loading: () => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => _unavailable(context, ref, error: error),
              data: (id) => ChatDetailPage(
                key: ValueKey('${ref.watch(waybillDraftScopeProvider)}/$id'),
                sessionId: id,
                sessionName: '订单聊天',
                orderId: orderId,
                orderStatus: order.stageLabel,
                counterpartyRole: pilot ? '货主' : '飞手',
                pilot: pilot,
              ),
            );
      },
    );
  }

  Widget _unavailable(
    BuildContext context,
    WidgetRef ref, {
    bool ended = false,
    Object? error,
  }) {
    final closed =
        ended ||
        (error is DispatchApiException &&
            error.code == 'DISPATCH_ASSIGNMENT_CHANGED');
    return Scaffold(
      appBar: AppBar(title: const Text('订单聊天')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                closed ? '本次订单会话已结束' : '暂时无法加载订单聊天',
                textAlign: TextAlign.center,
              ),
              FilledButton(
                onPressed: () {
                  if (closed) {
                    final prefix = pilot ? '/pilot' : '';
                    context.replace(
                      '$prefix/dispatch/orders/${Uri.encodeComponent(orderId)}',
                    );
                    return;
                  }
                  ref.invalidate(
                    dispatchChatSessionProvider((orderId, version)),
                  );
                  ref.invalidate(
                    pilot
                        ? dispatchPilotOrderProvider(orderId)
                        : dispatchOrderProvider(orderId),
                  );
                },
                child: Text(closed ? '查看最新订单' : '重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
