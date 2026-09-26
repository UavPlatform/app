import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../models/task_vo.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/rider_provider.dart';
import '../live/live_watch_page.dart';
import '../pay/pay_page.dart';
import 'deliverables_section.dart';
import 'widgets/applications_section.dart';

class OrderDetailPage extends ConsumerWidget {
  final String taskNum;

  const OrderDetailPage({super.key, required this.taskNum});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPilot = ref.watch(authProvider).user?.isPilot ?? false;

    if (isPilot) {
      return _PilotDetailView(taskNum: taskNum);
    } else {
      return _UserDetailView(taskNum: taskNum);
    }
  }
}

/// 用户端任务详情（调用 /task/detail）
class _UserDetailView extends ConsumerWidget {
  final String taskNum;
  const _UserDetailView({required this.taskNum});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(taskDetailProvider(taskNum));

    if (state.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final task = state.task;
    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('任务详情')),
        body: Center(
          child: Text(state.error ?? '未找到任务',
              style: const TextStyle(color: AppColors.onSurfaceVariant)),
        ),
      );
    }

    return _buildScaffold(context, ref, task, isPilot: false);
  }
}

/// 飞手端任务详情（从已加载的列表中查找）
class _PilotDetailView extends ConsumerWidget {
  final String taskNum;
  const _PilotDetailView({required this.taskNum});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = riderTaskLookup(ref, taskNum);

    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('任务详情')),
        body: const Center(
          child: Text('未找到任务',
              style: TextStyle(color: AppColors.onSurfaceVariant)),
        ),
      );
    }

    return _buildScaffold(context, ref, task, isPilot: true);
  }
}

/// 共享的 Scaffold 构建
Widget _buildScaffold(BuildContext context, WidgetRef ref, TaskVo task,
    {required bool isPilot}) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('任务详情'),
      actions: [
        if (!isPilot && task.isIdle)
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => _onDeleteUser(context, ref, task),
          ),
      ],
    ),
    // 下拉刷新（REQ-APP-002 场景 2「有应征后刷新」）：任务详情 + 应征列表 +
    // 任务会话一起对齐服务端。
    body: RefreshIndicator(
      onRefresh: () => _refreshDetail(ref, task, isPilot: isPilot),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildStatusHeader(task),
          // t42：操作提示矩阵（t32 服务端统一计算，直接渲染不端上拼装）
          if (task.actionHint != null && task.actionHint!.isNotEmpty)
            _buildActionHintBanner(task.actionHint!),
          // 撮合中心（TASK-APP-003 / ADR-0003）：应征飞手列表 + 订单内聊天，
          // 系统报价只读展示，无任何议价/调价入口。
          if (!isPilot)
            ApplicationsSection(
              taskNum: task.taskNum,
              inMatching: task.isInMatchingStage,
            ),
          _buildSection('任务信息', [
            _infoRow('任务编号', task.taskNum),
            _infoRow('任务名称', task.taskName),
            _infoRow('任务类型', task.taskTypeName),
            if (task.formattedTaskTime.isNotEmpty)
              _infoRow('任务时间', task.formattedTaskTime),
            if (_orderStatusLabel(task.orderStatus) != null)
              _infoRow('订单状态', _orderStatusLabel(task.orderStatus)!),
            if (task.riderName != null && task.riderName!.isNotEmpty)
              _infoRow('接单飞手', task.riderName!),
            if (task.description != null && task.description!.isNotEmpty)
              _infoRow('任务描述', task.description!),
            if (task.formattedCreateTime.isNotEmpty)
              _infoRow('创建时间', task.formattedCreateTime),
            if (task.totalAmount != null && task.totalAmount! > 0)
              _infoRow('酬劳', '¥${task.totalAmount!.toStringAsFixed(0)}'),
            if (task.totalDistance != null && task.totalDistance! > 0)
              _infoRow('总距离', '${task.totalDistance!.toStringAsFixed(0)} m'),
            if (task.orderNum != null) _infoRow('订单号', task.orderNum!),
          ]),
          // t42：飞手完成说明（/rider/complete note 经 TaskVo.completeNote 下发）
          if (task.completeNote != null && task.completeNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildSection('完成说明', [
              Text(
                task.completeNote!,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ]),
          ],
          // t44：交付成果（t42 占位区块填充真实附件列表与上传）
          if (task.riderId != null) ...[
            const SizedBox(height: 8),
            DeliverablesSection(taskNum: task.taskNum),
          ],
          if (task.waypoints != null && task.waypoints!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildSection('航点', [
              ...task.waypoints!.asMap().entries.map((e) {
                final wp = e.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24, height: 24,
                        decoration: const BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('${e.key + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${wp.latitude.toStringAsFixed(6)}, ${wp.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                );
              }),
            ]),
          ],
          const SizedBox(height: 80),
        ],
      ),
    ),
    bottomNavigationBar: isPilot ? _buildPilotBottom(context, ref, task) : _buildUserBottom(context, ref, task),
  );
}

/// 详情页下拉刷新：任务详情始终刷新；用户侧同时刷新应征列表与任务内会话，
/// 使空状态「等待飞手接单」在飞手应征后能被拉到最新数据。
Future<void> _refreshDetail(WidgetRef ref, TaskVo task,
    {required bool isPilot}) async {
  await ref.read(taskDetailProvider(task.taskNum).notifier).loadDetail(task.taskNum);
  if (isPilot) return;
  await ref.read(taskApplicationsProvider(task.taskNum).notifier).load();
  await ref.read(taskChatSessionsProvider(task.taskNum).notifier).load();
}

/// t42：操作提示横幅（t32 服务端统一计算的 actionHint，直接渲染）
Widget _buildActionHintBanner(String hint) {
  return Container(
    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.flag_outlined, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            hint,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildStatusHeader(TaskVo task) {
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
            _stepDot('空闲', true),
            _stepLine(task.taskStatus != 'IDLE'),
            _stepDot('执行中', task.isInProgress || task.isCompleted),
            _stepLine(task.isCompleted),
            _stepDot('完成', task.isCompleted),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '当前状态: ${task.taskStatusName}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    ),
  );
}

Widget _stepDot(String label, bool active) {
  return Column(
    children: [
      Container(
        width: 20, height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? Colors.white : Colors.white38,
        ),
        child: active ? const Icon(Icons.check, size: 14, color: AppColors.primary) : null,
      ),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 12, color: active ? Colors.white : Colors.white54)),
    ],
  );
}

Widget _stepLine(bool active) {
  return Container(width: 40, height: 2, color: active ? Colors.white : Colors.white38);
}

Widget _buildSection(String title, List<Widget> children) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
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
          child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
      ],
    ),
  );
}

/// 后端 OrderStatus 枚举名 → 中文标签（/task/detail 返回枚举名字符串）。
String? _orderStatusLabel(String? orderStatus) {
  switch (orderStatus) {
    case 'PENDING':
      return '待支付';
    case 'PAID':
      return '已支付';
    case 'WAITING_CONFIRM':
      return '待验收';
    case 'COMPLETED':
      return '已完成';
    case 'CANCELLED':
      return '已取消';
    case 'REFUNDED':
      return '已退款';
    default:
      return null;
  }
}

/// 待支付订单支付入口（t29：跳转模拟收银台，完成后刷新详情）。
Future<void> _onPayUser(
  BuildContext context,
  WidgetRef ref,
  TaskVo task,
) async {
  final paid = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => PayPage(orderNum: task.orderNum!),
    ),
  );
  if (!context.mounted) return;
  if (paid == true) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('支付成功')),
    );
    // 重新拉取任务详情，订单状态流转可见（PENDING → PAID）
    await ref
        .read(taskDetailProvider(task.taskNum).notifier)
        .loadDetail(task.taskNum);
  }
}

/// 用户侧「联系飞手」（t34，P1-6）：创建直连会话并跳转聊天详情。
/// 复用既有 /chat/session/create 与 t28 聊天链路（WS 重连/补拉/4001）；
/// 会话带 taskNum 绑定到本任务（ADR-0003 订单内聊天，同任务 + 飞手去重）。
Future<void> _onContactRider(
  BuildContext context,
  WidgetRef ref,
  TaskVo task,
) async {
  final riderId = task.riderId;
  if (riderId == null) return;
  final session = await ref
      .read(sessionListProvider.notifier)
      .createDirectSession(
        name: task.riderName ?? '飞手',
        userId: riderId,
        taskNum: task.taskNum,
      );
  if (!context.mounted) return;
  if (session == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('创建会话失败，请稍后重试')),
    );
    return;
  }
  final riderName = task.riderName ?? '飞手';
  await context.push('/chat/${session.id}?name=${Uri.encodeComponent(riderName)}');
}

/// 用户端底部按钮
Widget? _buildUserBottom(BuildContext context, WidgetRef ref, TaskVo task) {
  // t34（P1-6）：已接单状态提供「联系飞手」入口（创建直连会话并跳转聊天）
  final contactButton = task.riderId != null
      ? OutlinedButton.icon(
          onPressed: () => _onContactRider(context, ref, task),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.chat_bubble_outline, size: 18),
          label: const Text('联系飞手', style: TextStyle(fontSize: 16)),
        )
      : null;

  // t38（P0-4/Q3=C）+ t41 富化：直播运行中提供「观看直播」入口
  // 主判定 = 详情字段（deviceId 非空 && liveState==RUNNING），免额外往返
  final watchEntry = task.deviceId != null &&
          task.deviceId!.isNotEmpty &&
          task.liveState == 'RUNNING' &&
          task.orderNum != null
      ? _WatchLiveEntry(
          deviceId: task.deviceId!,
          orderNum: task.orderNum!,
        )
      : null;

  if (task.isWaitingConfirm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (watchEntry != null) ...[
            watchEntry,
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              if (contactButton != null) ...[
                Expanded(child: contactButton),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: () => _onConfirmUser(context, ref, task),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('确认完成', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  if (task.isIdle && task.orderStatus == 'PENDING' && task.orderNum != null) {
    // 待支付订单：提供支付入口（t29，走 mock 收银台）
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _onPayUser(context, ref, task),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('去支付', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _onDeleteUser(context, ref, task),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              child: const Text('删除任务'),
            ),
          ),
        ],
      ),
    );
  }

  if (task.isIdle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _onDeleteUser(context, ref, task),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              child: const Text('删除任务'),
            ),
          ),
        ],
      ),
    );
  }

  // 已接单状态（含执行中/已完成等有飞手的任务）：联系飞手 + 观看直播入口
  if (contactButton != null || watchEntry != null) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (watchEntry != null) ...[
            watchEntry,
            const SizedBox(height: 8),
          ],
          if (contactButton != null)
            SizedBox(width: double.infinity, child: contactButton),
        ],
      ),
    );
  }

  return null;
}

/// 直播观看入口按钮（t38+t41）：判定由调用方依据详情字段完成，
/// 点击进入观看页（凭证经 /live/get 拉取）。
class _WatchLiveEntry extends StatelessWidget {
  final String deviceId;
  final String orderNum;

  const _WatchLiveEntry({required this.deviceId, required this.orderNum});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LiveWatchPage(
              deviceId: deviceId,
              orderNum: orderNum,
            ),
          ),
        );
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: const BorderSide(color: AppColors.error),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: const Icon(Icons.live_tv, size: 18),
      label: const Text('观看直播', style: TextStyle(fontSize: 16)),
    );
  }
}

/// 飞手端底部按钮
Widget? _buildPilotBottom(BuildContext context, WidgetRef ref, TaskVo task) {
  if (task.isInProgress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _onCancel(context, ref, task),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('取消接单'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: () => _onComplete(context, ref, task),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('完成任务'),
            ),
          ),
        ],
      ),
    );
  }

  return null;
}

Future<void> _onCancel(BuildContext context, WidgetRef ref, TaskVo task) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('确认取消'),
      content: Text('确定要取消「${task.taskName}」的接单吗？'),
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

  final ok = await ref.read(myRiderTasksProvider.notifier).cancelTask(task.taskNum);
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(ok ? '已取消接单' : ref.read(myRiderTasksProvider).error ?? '取消失败')),
  );
  if (ok) WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/pilot/tasks'));
}

Future<void> _onComplete(BuildContext context, WidgetRef ref, TaskVo task) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('确认完成'),
      content: Text('确定「${task.taskName}」已经完成了吗？'),
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

  final ok = await ref.read(myRiderTasksProvider.notifier).completeTask(task.taskNum);
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(ok ? '任务已完成' : ref.read(myRiderTasksProvider).error ?? '操作失败')),
  );
  if (ok) WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/pilot/jobs'));
}

Future<void> _onConfirmUser(BuildContext context, WidgetRef ref, TaskVo task) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('确认完成'),
      content: Text('确认「${task.taskName}」已经完成了吗？\n确认后订单将完结。'),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.success),
          child: const Text('确认完成'),
        ),
      ],
    ),
  );

  if (confirm != true || !context.mounted) return;

  final ok = await ref.read(taskDetailProvider(task.taskNum).notifier).confirmTask(task.taskNum);
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(ok ? '确认完成成功' : ref.read(taskDetailProvider(task.taskNum)).error ?? '确认失败')),
  );
}

Future<void> _onDeleteUser(BuildContext context, WidgetRef ref, TaskVo task) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('确认删除'),
      content: const Text('删除后无法恢复'),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('删除', style: TextStyle(color: AppColors.error)),
        ),
      ],
    ),
  );

  if (confirm == true && context.mounted) {
    final ok = await ref.read(taskDetailProvider(task.taskNum).notifier).deleteTask(task.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? '已删除' : '删除失败')),
      );
      if (ok) WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/orders'));
    }
  }
}
