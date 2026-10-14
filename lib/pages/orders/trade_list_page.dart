import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/order_api.dart';
import '../../api/trade_api.dart';
import '../../models/task_vo.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import 'order_list_page.dart';
import '../../widgets/data_refresh.dart';

class TradeListPage extends ConsumerStatefulWidget {
  const TradeListPage({super.key, required this.kind});
  final String kind;
  @override
  ConsumerState<TradeListPage> createState() => _TradeListPageState();
}

class _TradeListPageState extends ConsumerState<TradeListPage> {
  List<OrderVo> _orders = [];
  List<TaskVo> _tasks = [];
  bool _loading = true;
  String? _error;
  int _page = 0;
  int _pages = 0;
  int _total = 0;
  String get _title => switch (widget.kind) {
    'published' => '我发布的',
    'sold' => '我卖出的',
    'review' => '待评价',
    _ => '我买到的',
  };

  @override
  void initState() {
    super.initState();
    _load(0);
  }

  Future<void> _load(int page) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.kind == 'published') {
        final result = await ref.read(taskApiProvider).listTasks(page: page);
        if (!result.success || result.data == null) {
          throw Exception(result.message ?? '任务加载失败');
        }
        if (!mounted) return;
        final data = result.data!;
        setState(() {
          _tasks = data.tasks;
          _page = data.currentPage;
          _pages = data.totalPages;
          _total = data.totalElements;
        });
      } else {
        final client = ref.read(httpClientProvider);
        final result = await switch (widget.kind) {
          'sold' => TradeApi(client).sold(page: page),
          'review' => TradeApi(client).pendingReview(page: page),
          _ => OrderApi(client).listOrders(page: page),
        };
        if (!result.success || result.data == null) {
          throw Exception(result.message ?? '订单加载失败');
        }
        final data = result.data!;
        if (!mounted) return;
        setState(() {
          _orders = data.orders;
          _page = data.currentPage;
          _pages = data.totalPages;
          _total = data.totalElements;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = '加载失败，请重试');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openOrder(OrderVo order) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderRecordDetailView(orderNum: order.orderNum),
      ),
    );
    if (mounted) _load(_page);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final published = widget.kind == 'published';
    final empty = published ? _tasks.isEmpty : _orders.isEmpty;
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? DataRefresh(
              onRefresh: () => _load(0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => _load(_page),
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _load(0),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    '共 $_total ${published ? '个任务' : '笔订单'}',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  if (empty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 80),
                      child: Center(child: Text('暂无$_title记录')),
                    ),
                  if (published)
                    ..._tasks.map(
                      (task) => Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Icon(
                            Icons.inventory_2_outlined,
                            color: scheme.primary,
                          ),
                          title: Text(task.taskName),
                          subtitle: Text(
                            '${task.taskNum}\n${task.userStageLabel}',
                            style: const TextStyle(height: 1.6),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await context.push(
                              '/order/${Uri.encodeComponent(task.taskNum)}',
                            );
                            if (mounted) _load(_page);
                          },
                        ),
                      ),
                    ),
                  if (!published)
                    ..._orders.map(
                      (order) => Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(order.taskName ?? '吊运订单'),
                          subtitle: Text(
                            '${order.orderNum}\n${order.statusLabel}',
                            style: const TextStyle(height: 1.6),
                          ),
                          trailing: Text(
                            order.priceLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                            ),
                          ),
                          // The backend order-detail endpoint is restricted to the buyer.
                          onTap: widget.kind == 'sold'
                              ? null
                              : () => _openOrder(order),
                        ),
                      ),
                    ),
                  if (_pages > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: _page > 0
                                ? () => _load(_page - 1)
                                : null,
                            child: const Text('上一页'),
                          ),
                          Text('${_page + 1} / $_pages'),
                          TextButton(
                            onPressed: _page + 1 < _pages
                                ? () => _load(_page + 1)
                                : null,
                            child: const Text('下一页'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
