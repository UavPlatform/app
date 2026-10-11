// 我的订单（t29：真实对接 /order/list、/order/detail，替代原任务列表视图）。
// 待支付订单提供「去支付」入口（模拟收银台，走 t21 mock 通道）。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/order_api.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/task_provider.dart';
import '../../models/task_vo.dart';
import '../../theme/app_colors.dart';
import '../../widgets/stage_tag.dart';
import '../pay/pay_page.dart';

class OrderListPage extends ConsumerStatefulWidget {
  const OrderListPage({super.key});

  @override
  ConsumerState<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends ConsumerState<OrderListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // 分栏 = REQ-APP-002 用户侧状态机的阶段名，并且按卡片自身的阶段标签筛选：
  // 分栏名、卡片标签、详情页头部永远是同一个词（REQ-APP-002「各阶段文案必须一致」）。
  // 不再按订单码分栏——MATCHING 同时覆盖「招募飞手中」「洽谈中」，PAID 同时覆盖
  // 「待飞手确认」「进行中」，按码分栏必然出现分栏名与卡片标签不一致。
  static const _tabs = <(String, Set<String>?)>[
    ('全部', null),
    ('招募飞手中', {'招募飞手中'}),
    ('洽谈中', {'洽谈中'}),
    ('待支付', {'待支付'}),
    ('待飞手确认', {'待飞手确认'}),
    ('进行中', {'进行中'}),
    ('待验收', {'待验收'}),
    ('已完成', {'已完成'}),
    // REQ-APP-002 主状态机之外的旁路终态（后端 OrderStatus：取消/退款/争议），单独一栏，
    // 保证每张卡片都落在某个分栏里，而不是只出现在「全部」。
    ('取消/售后', {'已取消', '已退款', '争议中'}),
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
      // 同时刷新本人任务列表：订单卡片的阶段文案与跳转都依赖 orderNum → 任务反查。
      // 推迟到下一事件循环：_loadOrders 会在 initState 中被调用，此时不得同步修改 provider。
      final tasksFuture =
          Future(() => ref.read(taskListProvider.notifier).loadTasks());
      final result = await _orderApi.listOrders();
      await tasksFuture;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('支付成功')),
      );
      _loadOrders();
    }
  }

  /// 卡片阶段标签：反查到任务用任务阶段（与首页/详情同源），否则按订单码兜底。
  /// 分栏筛选也用它，保证分栏名与卡片标签一致。
  static String stageLabelOf(OrderVo order, TaskVo? task) =>
      task?.stageLabel ?? OrderStatusCode.labelOf(order.orderStatus);

  /// 订单 → 本人任务（订单本身不带 taskNum，按 orderNum 在本人任务列表反查）。
  TaskVo? _taskFor(OrderVo order, List<TaskVo> tasks) {
    for (final task in tasks) {
      if (task.orderNum == order.orderNum) return task;
    }
    return null;
  }

  /// 点订单直达撮合中心（任务详情：应征/聊天/支付/确认/验收都在这里）；
  /// 反查不到任务（如任务列表尚未加载）时退回订单详情视图。返回后刷新列表。
  Future<void> _openDetail(OrderVo order, TaskVo? task) async {
    if (task != null) {
      await context.push('/order/${task.taskNum}');
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _OrderDetailView(orderNum: order.orderNum),
        ),
      );
    }
    if (!mounted) return;
    _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    // 按单未读红点（REQ-APP-002 场景 2）：会话未读按 taskNum → 订单聚合，
    // 替换 APP-001 的「首项全局占位」；未绑定任务的会话不计入。
    final unreadByOrder = ref.watch(orderUnreadProvider);
    final tasks = ref.watch(taskListProvider).tasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的订单'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _tabs.map((t) => Tab(text: t.$1)).toList(),
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.primary,
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _loadOrders,
        child: const Icon(Icons.refresh),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: _tabs.map((tab) {
                    final orders = _orders ?? const <OrderVo>[];
                    final labels = tab.$2;
                    final filtered = labels == null
                        ? orders
                        : orders
                            .where((o) => labels
                                .contains(stageLabelOf(o, _taskFor(o, tasks))))
                            .toList();
                    if (filtered.isEmpty) return _buildEmpty();
                    return RefreshIndicator(
                      onRefresh: _loadOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _buildCard(
                          filtered[i],
                          task: _taskFor(filtered[i], tasks),
                          unread: unreadByOrder[filtered[i].orderNum] ?? 0,
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
          Text(_error!, style: const TextStyle(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: _loadOrders, child: const Text('重试')),
        ],
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
            color: AppColors.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无订单',
            style: TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            child: const Text('去发布任务'),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(OrderVo order, {TaskVo? task, int unread = 0}) {
    // 撮合阶段（招募/洽谈）尚未锁价：草稿订单金额为 0，不展示「¥0.00」。
    final priceLocked = order.orderStatus != OrderStatusCode.matching &&
        order.totalAmount != null &&
        order.totalAmount! > 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openDetail(order, task),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (task != null)
                    StageTag(task: task)
                  else
                    _statusTag(order.orderStatus),
                  if (unread > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        unread > 99 ? '99+' : '$unread',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (priceLocked)
                    Text(
                      '¥${order.totalAmount!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    )
                  else if (order.orderStatus == OrderStatusCode.matching)
                    const Text(
                      '选定飞手后锁价',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                order.taskName ?? '任务信息待同步',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              Text(
                '订单号 ${order.orderNum}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              if (order.isPending) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () => _goPay(order),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      icon: const Icon(Icons.payment, size: 18),
                      label: const Text('去支付'),
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
      case OrderStatusCode.matching:
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
      default:
        bg = AppColors.statusCancelled;
        text = AppColors.statusCancelledText;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 12, color: text)),
    );
  }
}

/// 订单详情视图（/order/detail，含状态流转与支付入口）。
class _OrderDetailView extends ConsumerStatefulWidget {
  final String orderNum;

  const _OrderDetailView({required this.orderNum});

  @override
  ConsumerState<_OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends ConsumerState<_OrderDetailView> {
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
      MaterialPageRoute(
        builder: (_) => PayPage(orderNum: widget.orderNum),
      ),
    );
    if (!mounted) return;
    setState(() => _paying = false);
    if (paid == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('支付成功')),
      );
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
      appBar: AppBar(title: const Text('订单详情')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(onPressed: _load, child: const Text('重试')),
                    ],
                  ),
                )
              : _buildBody(),
      bottomNavigationBar: (_order?.isPending ?? false)
          ? Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _paying ? null : _pay,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('去支付', style: TextStyle(fontSize: 16)),
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
      padding: const EdgeInsets.all(16),
      children: [
        _statusFlow(order.orderStatus),
        // 订单 → 任务详情（撮合中心：应征列表 + 订单内聊天），
        // 订单本身不携带 taskNum，经本人任务列表按 orderNum 反查。
        if (taskNum != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/order/$taskNum'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.forum_outlined, size: 18),
              label: const Text(
                '应征飞手与订单聊天',
                style: TextStyle(fontSize: 15),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
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

  /// 状态流转（反查不到任务时的兜底视图，按订单码）：待支付 → 待飞手确认 → 待验收 → 已完成。
  Widget _statusFlow(int status) {
    final steps = const ['待支付', '待飞手确认', '待验收', '已完成'];
    final stepCodes = const [
      OrderStatusCode.pending,
      OrderStatusCode.paid,
      OrderStatusCode.waitingConfirm,
      OrderStatusCode.completed,
    ];
    final currentIndex = stepCodes.indexOf(status);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, Color(0xFF42A5F5)]),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                if (i > 0)
                  _flowLine(currentIndex >= i)
                else
                  const SizedBox(width: 0),
                _flowDot(steps[i], currentIndex >= i),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '当前状态: ${OrderStatusCode.labelOf(status)}',
            style: const TextStyle(
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
              ? const Icon(Icons.check, size: 14, color: AppColors.primary)
              : null,
        ),
        const SizedBox(height: 4),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
