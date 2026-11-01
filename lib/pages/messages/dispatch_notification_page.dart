import '../../widgets/flow_ui.dart';
import '../../widgets/infinite_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/generated/openapi_models.dart';
import '../../providers/dispatch_notification_provider.dart';
import '../../providers/waybill_draft_provider.dart';
import '../../providers/dispatch_order_provider.dart';
import '../../api/dispatch_api.dart';

class DispatchNotificationPage extends ConsumerStatefulWidget {
  const DispatchNotificationPage({super.key});
  @override
  ConsumerState<DispatchNotificationPage> createState() =>
      _DispatchNotificationPageState();
}

class _DispatchNotificationPageState
    extends ConsumerState<DispatchNotificationPage> {
  bool _opening = false;
  Future<void> _open(ApiDispatchNotificationVO item) async {
    if (_opening) return;
    final scope = ref.read(waybillDraftScopeProvider);
    setState(() => _opening = true);
    try {
      await ref.read(dispatchInboxProvider.notifier).read(item.notificationId!);
      if (!mounted || scope != ref.read(waybillDraftScopeProvider)) return;
      ref.invalidate(dispatchUnreadProvider);
      if (item.audience == 'PILOT_OFFER') {
        try {
          final current = await ref
              .read(dispatchOrderApiProvider)
              .pilotGet(item.orderId!);
          if (!mounted || scope != ref.read(waybillDraftScopeProvider)) return;
          await context.push(
            '/pilot/dispatch/orders/${Uri.encodeComponent(current.id)}',
          );
          return;
        } on DispatchApiException catch (error) {
          if (error.code != 'ORDER_NOT_FOUND') rethrow;
        }
        if (!mounted || scope != ref.read(waybillDraftScopeProvider)) return;
        await context.push(
          Uri(
            path: '/pilot/dispatch/nearby',
            queryParameters: {'orderId': item.orderId!},
          ).toString(),
        );
        return;
      }
      final prefix = item.audience == 'PILOT'
          ? '/pilot/dispatch/orders/'
          : '/dispatch/orders/';
      await context.push('$prefix${Uri.encodeComponent(item.orderId!)}');
    } catch (error) {
      if (mounted && scope == ref.read(waybillDraftScopeProvider)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dispatchInboxProvider);
    final groups = <String, List<ApiDispatchNotificationVO>>{};
    for (final item in state.items) {
      groups.putIfAbsent(item.orderId!, () => []).add(item);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('消息通知'),
        actions: [
          IconButton(
            tooltip: '刷新通知',
            onPressed: state.loading
                ? null
                : () async {
                    await ref
                        .read(dispatchInboxProvider.notifier)
                        .load(refresh: true);
                    ref.invalidate(dispatchUnreadProvider);
                  },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(dispatchInboxProvider.notifier).load(refresh: true);
          ref.invalidate(dispatchUnreadProvider);
        },
        child: LoadMoreListener(
          canLoadMore: state.hasNext && !state.loading && state.page >= 0,
          onLoadMore: () => ref.read(dispatchInboxProvider.notifier).load(),
          child: FlowList(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('手机系统推送尚未接入，请在应用内查看通知。站内通知会保留，点击后打开订单当前进度。'),
                ),
              ),
              if (state.loading && state.items.isEmpty)
                const LinearProgressIndicator(),
              if (state.error != null)
                TextButton(
                  onPressed: () => ref
                      .read(dispatchInboxProvider.notifier)
                      .load(refresh: state.items.isEmpty),
                  child: Text('${state.error}\n重新加载'),
                ),
              if (!state.loading && state.error == null && state.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('暂无派单通知')),
                ),
              for (final group in groups.entries) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    '订单 ${shortReference(group.key)}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                for (final item in group.value)
                  Card(
                    child: ListTile(
                      leading: Icon(
                        state.isRead(item)
                            ? Icons.mark_email_read_outlined
                            : Icons.mark_email_unread_outlined,
                      ),
                      title: Text(
                        '${state.isRead(item) ? '' : '未读 · '}${item.title ?? '订单通知'}',
                      ),
                      subtitle: Text(
                        '${item.body ?? ''}\n${item.createdAt}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      isThreeLine: true,
                      onTap: _opening ? null : () => _open(item),
                    ),
                  ),
              ],
              if (state.items.isNotEmpty || state.loading)
                InfiniteListFooter(
                  loading: state.loading && state.items.isNotEmpty,
                  hasMore: state.hasNext && state.page >= 0,
                  showEndMessage: state.items.isNotEmpty && !state.hasNext,
                ),
              if (_opening) const LinearProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
