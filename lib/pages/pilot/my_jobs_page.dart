import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../models/task_vo.dart';
import '../../providers/rider_provider.dart';
import '../../providers/chat_provider.dart';

class MyJobsPage extends ConsumerStatefulWidget {
  const MyJobsPage({super.key});

  @override
  ConsumerState<MyJobsPage> createState() => _MyJobsPageState();
}

class _MyJobsPageState extends ConsumerState<MyJobsPage>
    with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myRiderTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的接单'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: '进行中 (${state.activeTasks.length})'),
            const Tab(text: '已完成'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => ref.read(myRiderTasksProvider.notifier).loadTasks(),
        child: const Icon(Icons.refresh),
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, MyRiderTasksState state) {
    if (state.loading && state.activeTasks.isEmpty && state.historyTasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.activeTasks.isEmpty && state.historyTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: AppColors.outlineVariant),
            const SizedBox(height: 16),
            Text(state.error!, style: const TextStyle(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref.read(myRiderTasksProvider.notifier).loadTasks(),
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildActiveGroups(state.activeTasks),
        _buildTabContent(
          state.historyTasks.where((t) => t.isCompleted).toList(),
          '暂无已完成的任务',
          null,
        ),
      ],
    );
  }

  /// 进行中 Tab 按撮合阶段分组（ADR-0003 状态机）：
  /// 待用户下单（NEGOTIATING/AWAITING_PAYMENT）/ 待我确认（AWAITING_RIDER_CONFIRM）/
  /// 已确认待执飞（CONFIRMED）；卡片文案以服务端 actionHint 为准。
  Widget _buildActiveGroups(List<TaskVo> tasks) {
    if (tasks.isEmpty) {
      return _emptyState('暂无进行中的任务', '去任务大厅接单吧');
    }

    final groups = <(String, List<TaskVo>)>[
      ('待用户下单', tasks.where((t) => t.isAwaitingUserOrder).toList()),
      ('待我确认', tasks.where((t) => t.isAwaitingRiderConfirm).toList()),
      ('已确认待执飞', tasks.where((t) => t.isConfirmedForFlight).toList()),
      (
        '其他',
        tasks
            .where((t) =>
                !t.isAwaitingUserOrder &&
                !t.isAwaitingRiderConfirm &&
                !t.isConfirmedForFlight)
            .toList(),
      ),
    ];

    final children = <Widget>[];
    for (final (title, group) in groups) {
      if (group.isEmpty) continue;
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
        child: Row(
          children: [
            Container(width: 4, height: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              '$title (${group.length})',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ));
      children.addAll(group.map((t) => _buildCard(context, t)));
      children.add(const SizedBox(height: 4));
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: children,
    );
  }

  Widget _emptyState(String title, String? subtitle) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              Icon(Icons.assignment_outlined, size: 64,
                  color: AppColors.outlineVariant.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(title,
                  style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 16)),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(subtitle,
                    style: const TextStyle(color: AppColors.outline, fontSize: 13)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(List<TaskVo> tasks, String emptyTitle, String? emptySubtitle) {
    if (tasks.isEmpty) {
      return _emptyState(emptyTitle, emptySubtitle);
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) => _buildCard(context, tasks[index]),
    );
  }

  Widget _buildCard(BuildContext context, TaskVo task) {
    final isActive = task.isInProgress;
    final creatingSession = ref.watch(sessionListProvider).creatingSession;

    // 撮合阶段徽标（ADR-0003 状态机；提示文案统一取服务端 actionHint）
    final String badgeText;
    final Color badgeBg;
    final Color badgeFg;
    if (task.isCompleted && task.matchStatus == 'PENDING_ACCEPTANCE') {
      // 已交付、等用户验收：不要提前显示「已完成」
      badgeText = '待验收';
      badgeBg = AppColors.statusPending;
      badgeFg = AppColors.statusPendingText;
    } else if (task.isCompleted) {
      badgeText = '已完成';
      badgeBg = AppColors.statusCompleted;
      badgeFg = AppColors.statusCompletedText;
    } else if (task.isAwaitingUserOrder) {
      badgeText = '待用户下单';
      badgeBg = AppColors.primaryLight;
      badgeFg = AppColors.primary;
    } else if (task.isAwaitingRiderConfirm) {
      badgeText = '待我确认';
      badgeBg = AppColors.statusPending;
      badgeFg = AppColors.statusPendingText;
    } else if (task.isConfirmedForFlight || isActive) {
      badgeText = '已确认';
      badgeBg = AppColors.statusInProgress;
      badgeFg = AppColors.statusInProgressText;
    } else {
      badgeText = '进行中';
      badgeBg = AppColors.statusCompleted;
      badgeFg = AppColors.statusCompletedText;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      // 整卡可点进任务详情（交付成果上传、航点、完成说明都在详情里）
      child: InkWell(
        key: ValueKey('job-card-${task.taskNum}'),
        onTap: () => context.push('/order/${task.taskNum}'),
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(fontSize: 12, color: badgeFg),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.taskTypeName,
                    style: const TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                ),
                const Spacer(),
                Text(
                  task.priceText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              task.taskName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                task.description!,
                style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            // 服务端 actionHint 为唯一提示文案源（t32/t42 状态矩阵）
            if (task.actionHint != null && task.actionHint!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  task.actionHint!,
                  style: const TextStyle(fontSize: 13, color: AppColors.primary),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _infoRow(Icons.tag_outlined, '编号: ${task.taskNum}'),
            if (task.cargoLabel.isNotEmpty) ...[
              const SizedBox(height: 6),
              _infoRow(Icons.inventory_2_outlined, task.cargoLabel),
            ],
            if (task.formattedScheduledTime.isNotEmpty) ...[
              const SizedBox(height: 6),
              _infoRow(Icons.schedule, '约定作业时间: ${task.formattedScheduledTime}'),
            ],
            if (task.totalDistance != null && task.totalDistance! > 0) ...[
              const SizedBox(height: 6),
              _infoRow(Icons.route_outlined, '距离: ${task.totalDistance!.toStringAsFixed(0)} m'),
            ],
            const SizedBox(height: 6),
            _infoRow(Icons.access_time, task.formattedCreateTime),
            if (!task.isCompleted) ...[
              const SizedBox(height: 8),
              // 订单内聊天（ADR-0003 决定 1：同 taskNum 建会话）
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: creatingSession ? null : () => _onChat(context, task),
                  icon: creatingSession
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chat_bubble_outline, size: 18),
                  label: Text(creatingSession ? '正在连接' : '联系用户'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
            // 待我确认 → 确认订单（回显约定时间后调 confirm-order）
            if (task.isAwaitingRiderConfirm) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _onConfirm(context, task),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('确认订单'),
                ),
              ),
            ],
            // 已确认 → 执飞引导；未确认的任务在此不出现任何执飞入口
            if (task.isConfirmedForFlight) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _onOpenDjifly(context, task),
                  icon: const Icon(Icons.flight_takeoff, size: 18),
                  label: const Text('打开 djifly'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
            if (isActive) ...[
              const SizedBox(height: 8),
              // 交付门禁：完成前必须先上传履约证据，入口直达详情页「交付成果」
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/order/${task.taskNum}'),
                  icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                  label: const Text('上传交付凭证'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _onCancel(context, task),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('取消接单'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _onComplete(context, task),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('完成任务'),
                    ),
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

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _onCancel(BuildContext context, TaskVo task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认取消'),
        content: Text('确定要取消「${task.taskName}」的接单吗？\n取消后任务将回到任务广场。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('再想想')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确定取消', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final notifier = ref.read(myRiderTasksProvider.notifier);
    final ok = await notifier.cancelTask(task.taskNum);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '已取消接单' : ref.read(myRiderTasksProvider).error ?? '取消失败')),
    );
  }

  Future<void> _onChat(BuildContext context, TaskVo task) async {
    final fallbackName = '${task.taskTypeName} - ${task.taskName}';
    // 订单内会话（ADR-0003 决定 1）：同 taskNum 绑定任务，服务端按任务 + 飞手去重。
    final session = await ref.read(sessionListProvider.notifier).createDirectSession(
          name: fallbackName,
          userId: task.userId,
          taskNum: task.taskNum,
        );
    if (!context.mounted) return;

    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(sessionListProvider).error ?? '创建会话失败')),
      );
      return;
    }

    final chatName = session.otherUserName ?? fallbackName;
    context.push('/chat/${session.id}?otherUserName=${Uri.encodeComponent(chatName)}');
  }

  /// 确认订单（TASK-APP-005）：先回显约定作业时间，再调 confirm-order；
  /// 成功后用服务端返回 VO 推进分组（待我确认 → 已确认待执飞）。
  Future<void> _onConfirm(BuildContext context, TaskVo task) async {
    final scheduled = task.formattedScheduledTime;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认订单'),
        content: Text(
          scheduled.isEmpty
              ? '确定接下「${task.taskName}」吗？\n（服务端未回显约定作业时间）'
              : '确认按约定作业时间「$scheduled」接单吗？\n确认后任务将进入待执飞。',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('再想想')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确认接单'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final notifier = ref.read(myRiderTasksProvider.notifier);
    final ok = await notifier.confirmOrder(task.taskNum);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '已确认订单' : ref.read(myRiderTasksProvider).error ?? '确认失败')),
    );
  }

  /// 执飞引导（ADR-0002：app 引导 → djifly 执飞）：
  /// 暂无系统深链，降级为任务号 + 说明文案。
  void _onOpenDjifly(BuildContext context, TaskVo task) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('打开 djifly 执飞'),
        content: Text(
          '本 App 不执行真实飞行，请打开 djifly 完成执飞。\n\n'
          '任务编号：${task.taskNum}\n'
          '登录同一账号后，在 djifly「待执飞任务」中按任务号查看本任务。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Future<void> _onComplete(BuildContext context, TaskVo task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认完成'),
        content: Text('确定「${task.taskName}」已经完成了吗？\n完成后将通知用户确认收货。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('再等等')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('确认完成'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final notifier = ref.read(myRiderTasksProvider.notifier);
    final ok = await notifier.completeTask(task.taskNum);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '任务已完成，等待用户确认' : ref.read(myRiderTasksProvider).error ?? '操作失败')),
    );
  }
}
