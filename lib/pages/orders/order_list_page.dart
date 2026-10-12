// 我的订单（t29：真实对接 /order/list、/order/detail，替代原任务列表视图）。
// 待支付订单提供「去支付」入口（模拟收银台，走 t21 mock 通道）。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/order_api.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/task_provider.dart';
import '../../theme/app_colors.dart';
import '../../models/task_vo.dart';
import '../pay/pay_page.dart';

class OrderListPage extends ConsumerStatefulWidget {
  const OrderListPage({super.key});

  @override
  ConsumerState<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends ConsumerState<OrderListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tabs = const ['全部', '待支付', '已支付', '待验收', '已完成'];
  static const _statusFilters = <int?>[
    null,
    OrderStatusCode.pending,
    OrderStatusCode.paid,
    OrderStatusCode.waitingConfirm,
    OrderStatusCode.completed,
  ];

  List<OrderVo>? _orders;
  bool _loading = true;
  String? _error;

  OrderApi get _orderApi => OrderApi(ref.read(httpClientProvider));

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _orderApi.listOrders();
      if (!mounted) return;
      if (result.success && result.data != null) {
        setState(() {
          _orders = result.data!.orders;
          _loading = false;
        });
      } else {
        setState(() {
          _error = result.message ?? '加载失败';
          _loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '加载失败，请检查网络';
        _loading = false;
      });
    }
  }

  Future<void> _goPay(OrderVo order) async {
    final paid = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PayPage(orderNum: order.orderNum)),
    );
    if (paid == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('支付成功')));
      _loadOrders();
    }
  }

  void _openDetail(OrderVo order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderRecordDetailView(orderNum: order.orderNum),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 按单未读红点（REQ-APP-002 场景 2）：会话未读按 taskNum → 订单聚合，
    // 替换 APP-001 的「首项全局占位」；未绑定任务的会话不计入。
    final unreadByOrder = ref.watch(orderUnreadProvider);
    final tasks = ref.watch(taskListProvider).tasks;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('我的订单'),
        actions: [
          TextButton.icon(
            onPressed: _showPublishedTasks,
            icon: Icon(Icons.assignment_outlined, size: 18),
            label: Text('已发布任务'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          indicatorColor: Theme.of(context).colorScheme.primary,
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        tooltip: '刷新订单',
        onPressed: _loadOrders,
        child: Icon(Icons.refresh),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorView()
          : TabBarView(
              controller: _tabController,
              children: _statusFilters.map((status) {
                final orders = _orders ?? const <OrderVo>[];
                final filtered = status == null
                    ? orders
                    : orders.where((o) => o.orderStatus == status).toList();
                if (filtered.isEmpty) return _buildEmpty();
                return RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _buildCard(
                      filtered[i],
                      unread: unreadByOrder[filtered[i].orderNum] ?? 0,
                      task: _taskForOrder(tasks, filtered[i].orderNum),
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _error!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 16),
          OutlinedButton(onPressed: _loadOrders, child: Text('重试')),
        ],
      ),
    );
  }

  Future<void> _showPublishedTasks() async {
    final notifier = ref.read(taskListProvider.notifier);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * 0.75,
        child: Consumer(
          builder: (context, sheetRef, _) {
            final state = sheetRef.watch(taskListProvider);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Text(
                    '已发布任务',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  child: state.loading
                      ? Center(child: CircularProgressIndicator())
                      : state.error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(state.error!),
                              TextButton(
                                onPressed: notifier.loadTasks,
                                child: Text('重试'),
                              ),
                            ],
                          ),
                        )
                      : state.tasks.isEmpty
                      ? Center(child: Text('暂无已发布任务'))
                      : RefreshIndicator(
                          onRefresh: notifier.loadTasks,
                          child: ListView.separated(
                            physics: AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            itemCount: state.tasks.length,
                            separatorBuilder: (_, _) => SizedBox(height: 8),
                            itemBuilder: (_, index) {
                              final task = state.tasks[index];
                              return Card(
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  title: Text(task.taskName),
                                  subtitle: Text(
                                    task.actionHint ?? task.taskStatusName,
                                  ),
                                  trailing: Icon(Icons.chevron_right),
                                  onTap: () {
                                    Navigator.of(sheetContext).pop();
                                    this.context.push('/order/${task.taskNum}');
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
          SizedBox(height: 16),
          Text(
            '暂无订单',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            child: Text('去发布任务'),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(OrderVo order, {int unread = 0, TaskVo? task}) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(6),
          bottomRight: Radius.circular(6),
        ),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => _openDetail(order),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(6),
          bottomRight: Radius.circular(6),
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: order.isPending
                    ? AppColors.accent
                    : Theme.of(context).colorScheme.primary,
                width: 3,
              ),
            ),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _statusTag(order.orderStatus),
                  if (unread > 0) ...[
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        unread > 99 ? '99+' : '$unread',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  Spacer(),
                  Text(
                    order.totalAmount != null
                        ? '¥${order.totalAmount!.toStringAsFixed(2)}'
                        : '价格待确认',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                order.taskName ?? '任务信息待同步',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 6),
              Text(
                '订单号 ${order.orderNum}',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 16),
              if (task != null) ...[
                if (task.scheduledTime != null || task.taskTime != null)
                  _summaryLine(
                    Icons.schedule,
                    '作业时间',
                    task.scheduledTime ?? task.taskTime!,
                  ),
                if (task.cargoCategory != null || task.cargoWeightKg != null)
                  _summaryLine(
                    Icons.inventory_2_outlined,
                    '货物',
                    [
                      if (task.cargoCategory != null)
                        const {
                              'CONSTRUCTION': '建材',
                              'EQUIPMENT': '设备',
                              'AGRICULTURAL': '农产品',
                              'DAILY_SUPPLIES': '生活物资',
                              'FURNITURE': '家具家居',
                            }[task.cargoCategory] ??
                            '其他货物',
                      if (task.cargoWeightKg != null)
                        '${task.cargoWeightKg} kg',
                    ].join(' · '),
                  ),
                if (task.riderName != null && task.riderName!.isNotEmpty)
                  _summaryLine(Icons.person_outline, '服务飞手', task.riderName!),
              ],
              if (order.distance != null)
                _summaryLine(
                  Icons.route_outlined,
                  '运输距离',
                  '${order.distance!.toStringAsFixed(0)} m',
                ),
              Divider(color: Theme.of(context).colorScheme.outlineVariant),
              SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    order.isPending
                        ? Icons.payment_outlined
                        : Icons.route_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task?.actionHint ?? _orderHint(order.orderStatus),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
              if (order.isPending) ...[
                SizedBox(height: 12),
                Row(
                  children: [
                    Spacer(),
                    FilledButton.icon(
                      onPressed: () => _goPay(order),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      icon: Icon(Icons.payment, size: 18),
                      label: Text('去支付'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusTag(int status) {
    final label = OrderStatusCode.labelOf(status);
    Color bg;
    Color text;
    switch (status) {
      case OrderStatusCode.pending:
        bg = AppColors.statusPending;
        text = AppColors.statusPendingText;
        break;
      case OrderStatusCode.paid:
      case OrderStatusCode.waitingConfirm:
        bg = AppColors.statusInProgress;
        text = AppColors.statusInProgressText;
        break;
      case OrderStatusCode.completed:
        bg = AppColors.statusCompleted;
        text = AppColors.statusCompletedText;
        break;
      case OrderStatusCode.cancelled:
      case OrderStatusCode.refunded:
        bg = AppColors.statusCancelled;
        text = AppColors.statusCancelledText;
        break;
      default:
        bg = AppColors.surfaceVariant;
        text = Theme.of(context).colorScheme.onSurfaceVariant;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: text)),
    );
  }

  TaskVo? _taskForOrder(List<TaskVo> tasks, String orderNum) {
    for (final task in tasks) {
      if (task.orderNum == orderNum) return task;
    }
    return null;
  }

  Widget _summaryLine(IconData icon, String label, String value) => Padding(
    padding: EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: 8),
        Text(
          '$label  ',
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(child: Text(value, style: TextStyle(fontSize: 13))),
      ],
    ),
  );

  String _orderHint(int status) {
    switch (status) {
      case OrderStatusCode.pending:
        return '待支付，请确认订单金额';
      case OrderStatusCode.paid:
        return '已支付，进入详情查询作业进度';
      case OrderStatusCode.waitingConfirm:
        return '作业待验收，请查看交付内容';
      case OrderStatusCode.completed:
        return '订单已完成，可查看作业记录';
      case OrderStatusCode.cancelled:
        return '订单已取消';
      case OrderStatusCode.refunded:
        return '订单已退款';
      default:
        return '状态待确认，请刷新或进入详情查询';
    }
  }
}

/// 订单详情视图（/order/detail，含状态流转与支付入口）。
class OrderRecordDetailView extends ConsumerStatefulWidget {
  final String orderNum;

  const OrderRecordDetailView({super.key, required this.orderNum});

  @override
  ConsumerState<OrderRecordDetailView> createState() =>
      OrderRecordDetailViewState();
}

class OrderRecordDetailViewState extends ConsumerState<OrderRecordDetailView> {
  OrderVo? _order;
  bool _loading = true;
  String? _error;
  bool _paying = false;

  OrderApi get _orderApi => OrderApi(ref.read(httpClientProvider));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _orderApi.getOrderDetail(widget.orderNum);
      if (!mounted) return;
      if (result.success && result.data != null) {
        setState(() {
          _order = result.data;
          _loading = false;
        });
      } else {
        setState(() {
          _error = result.message ?? '订单加载失败';
          _loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '订单加载失败';
        _loading = false;
      });
    }
  }

  Future<void> _pay() async {
    if (_paying) return;
    setState(() => _paying = true);
    final paid = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PayPage(orderNum: widget.orderNum)),
    );
    if (!mounted) return;
    setState(() => _paying = false);
    if (paid == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('支付成功')));
      _load();
    }
  }

  /// 订单 → 任务编号（本人任务列表按 orderNum 反查；仅在 build 期访问）。
  String? get _taskNumForOrder {
    for (final task in ref.watch(taskListProvider).tasks) {
      if (task.orderNum == widget.orderNum) return task.taskNum;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('订单详情')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 16),
                  OutlinedButton(onPressed: _load, child: Text('重试')),
                ],
              ),
            )
          : _buildBody(),
      bottomNavigationBar: (_order?.isPending ?? false)
          ? Container(
              padding: EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surface,
              child: SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _paying ? null : _pay,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: Text('去支付', style: TextStyle(fontSize: 16)),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    final order = _order!;
    final taskNum = _taskNumForOrder;
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _statusFlow(order.orderStatus),
        // 订单 → 任务详情（撮合中心：应征列表 + 订单内聊天），
        // 订单本身不携带 taskNum，经本人任务列表按 orderNum 反查。
        if (taskNum != null) ...[
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/order/$taskNum'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: Icon(Icons.forum_outlined, size: 18),
              label: Text('应征飞手与订单聊天', style: TextStyle(fontSize: 15)),
            ),
          ),
        ],
        SizedBox(height: 16),
        _buildSection('订单信息', [
          _infoRow('订单编号', order.orderNum),
          if (order.taskName != null && order.taskName!.isNotEmpty)
            _infoRow('任务名称', order.taskName!),
          _infoRow('订单状态', order.statusLabel),
          if (order.totalAmount != null)
            _infoRow('订单金额', '¥${order.totalAmount!.toStringAsFixed(2)}'),
          if (order.distance != null)
            _infoRow('总距离', '${order.distance!.toStringAsFixed(0)} m'),
        ]),
      ],
    );
  }

  /// 状态流转：待支付 → 已支付 → 待验收 → 已完成。
  Widget _statusFlow(int status) {
    final steps = const ['待支付', '已支付', '待验收', '已完成'];
    final stepCodes = const [
      OrderStatusCode.pending,
      OrderStatusCode.paid,
      OrderStatusCode.waitingConfirm,
      OrderStatusCode.completed,
    ];
    final currentIndex = stepCodes.indexOf(status);
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xFF23648B)],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                if (i > 0) _flowLine(currentIndex >= i) else SizedBox(width: 0),
                _flowDot(steps[i], currentIndex >= i),
              ],
            ],
          ),
          SizedBox(height: 16),
          Text(
            '当前状态: ${OrderStatusCode.labelOf(status)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _flowDot(String label, bool active) {
    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? Colors.white : Colors.white38,
          ),
          child: active
              ? Icon(
                  Icons.check,
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: active ? Colors.white : Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _flowLine(bool active) {
    return Container(
      width: 40,
      height: 2,
      color: active ? Colors.white : Colors.white38,
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
