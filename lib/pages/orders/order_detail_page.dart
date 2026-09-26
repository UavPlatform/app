import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../models/task_application_vo.dart';
import '../../models/task_vo.dart';
import '../../providers/aircraft_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/rider_account_provider.dart';
import '../../providers/rider_provider.dart';
import '../../providers/task_provider.dart';
import '../live/live_watch_page.dart';
import 'deliverables_section.dart';
import 'pay_entry.dart';
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

/// 飞手端任务详情（GET /rider/task/detail 拉取权威撮合状态，
/// 已加载列表兜底首帧渲染，应征/确认后重载对齐服务端）。
class _PilotDetailView extends ConsumerStatefulWidget {
  final String taskNum;
  const _PilotDetailView({required this.taskNum});

  @override
  ConsumerState<_PilotDetailView> createState() => _PilotDetailViewState();
}

class _PilotDetailViewState extends ConsumerState<_PilotDetailView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(riderTaskDetailProvider.notifier).load(widget.taskNum);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(riderTaskDetailProvider);
    final fresh =
        detail.task?.taskNum == widget.taskNum ? detail.task : null;
    final task = fresh ?? riderTaskLookup(ref, widget.taskNum);

    if (task == null) {
      if (detail.loading && detail.error == null) {
        return const Scaffold(
            body: Center(child: CircularProgressIndicator()));
      }
      return Scaffold(
        appBar: AppBar(title: const Text('任务详情')),
        body: Center(
          child: Text(detail.error ?? '未找到任务',
              style: const TextStyle(color: AppColors.onSurfaceVariant)),
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
          // 飞手端撮合区（TASK-APP-005 / ADR-0003）：选机型应征 → 只读系统报价
          // → 确认约定时间 → 执飞引导 + 订单内聊天；不存在价格输入控件。
          if (isPilot) ...[
            _PilotMatchSection(
              task: task,
              onTaskRefreshed: () => ref
                  .read(riderTaskDetailProvider.notifier)
                  .load(task.taskNum),
            ),
            const SizedBox(height: 8),
          ],
          // 撮合中心（TASK-APP-003 / ADR-0003）：应征飞手列表 + 订单内聊天，
          // 系统报价只读展示，无任何议价/调价入口。
          if (!isPilot)
            ApplicationsSection(
              taskNum: task.taskNum,
              inMatching: task.isInMatchingStage,
            ),
          // 撮合状态（TASK-APP-004 / ADR-0003 决定 4、6）：待飞手确认 / 已确认 /
          // 进行中……描述文案以上方 actionHint 横幅为准（服务端统一计算），
          // 此处只补可核验事实：状态名 + 双确认时间（有则展示）。
          if (!isPilot && !task.isInMatchingStage) _buildMatchStatusSection(task),
          _buildSection('任务信息', [
            _infoRow('任务编号', task.taskNum),
            _infoRow('任务名称', task.taskName),
            _infoRow('任务类型', task.taskTypeName),
            if (task.formattedTaskTime.isNotEmpty)
              _infoRow('任务时间', task.formattedTaskTime),
            // 吊运货物信息（ADR-0003 计价输入：重量 + 类别）
            if (task.cargoLabel.isNotEmpty) _infoRow('货物', task.cargoLabel),
            // 系统报价只读回显（ADR-0003 决定 2：客户端不得改价）
            if (task.quotedAmountText.isNotEmpty)
              _infoRow('系统报价', '${task.quotedAmountText}（平台计价）'),
            if (task.formattedScheduledTime.isNotEmpty)
              _infoRow('约定作业时间', task.formattedScheduledTime),
            if (task.aircraftModelName != null &&
                task.aircraftModelName!.isNotEmpty)
              _infoRow(
                '机型',
                task.modelCode != null && task.modelCode!.isNotEmpty
                    ? '${task.aircraftModelName}（${task.modelCode}）'
                    : task.aircraftModelName!,
              ),
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

/// 详情页下拉刷新：飞手侧刷新 /rider/task/detail（撮合状态权威源）；
/// 用户侧同时刷新应征列表与任务内会话，使空状态「等待飞手接单」
/// 在飞手应征后能被拉到最新数据。
Future<void> _refreshDetail(WidgetRef ref, TaskVo task,
    {required bool isPilot}) async {
  if (isPilot) {
    await ref.read(riderTaskDetailProvider.notifier).load(task.taskNum);
    return;
  }
  await ref.read(taskDetailProvider(task.taskNum).notifier).loadDetail(task.taskNum);
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

/// 撮合状态区块（TASK-APP-004）：状态名 + 双确认时间戳。
/// 描述性文案不在这里重复——服务端 actionHint 横幅是唯一文案源。
Widget _buildMatchStatusSection(TaskVo task) {
  return Container(
    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '撮合状态',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        _infoRow('状态', _matchStatusLabel(task)),
        // 双确认（ADR-0003 决定 4）：下单即用户确认；飞手确认后才进入进行中。
        if (task.formattedUserConfirmedAt.isNotEmpty)
          _infoRow('用户确认时间', task.formattedUserConfirmedAt),
        if (task.formattedRiderConfirmedAt.isNotEmpty)
          _infoRow('飞手确认时间', task.formattedRiderConfirmedAt),
      ],
    ),
  );
}

/// 撮合状态名：执行/完成态优先看 TaskStatus，否则按 matchStatus 映射。
/// 仅作状态名展示，阶段描述文案仍以 actionHint 为准。
String _matchStatusLabel(TaskVo task) {
  if (task.isInProgress) return '进行中';
  if (task.isCompleted) return '已完成';
  switch (task.matchStatus) {
    case 'AWAITING_PAYMENT':
      return '待支付';
    case 'AWAITING_RIDER_CONFIRM':
      return '待飞手确认';
    case 'CONFIRMED':
      return '已确认';
    case 'PENDING_ACCEPTANCE':
      return '待验收';
    case 'CLOSED':
      return '已关闭';
    default:
      return task.taskStatusName;
  }
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

/// 待支付订单支付入口（TASK-APP-004：先做锁价校验 totalAmount == quotedAmount，
/// 不一致不发起支付；校验通过才跳转既有模拟收银台，完成后刷新详情）。
Future<void> _onPayUser(
  BuildContext context,
  WidgetRef ref,
  TaskVo task,
) {
  return openPayEntry(
    context,
    ref,
    taskNum: task.taskNum,
    quotedAmount: task.quotedAmount,
  );
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

  // 履约证据（TASK-APP-004）：0 条 = 明确无证据 → 禁用「确认完成」并提示；
  // null = 证据列表尚未加载成功 → 放行，由服务端 DELIVERY_EVIDENCE_REQUIRED 兜底。
  final evidenceCount = ref.watch(taskEvidenceCountProvider(task.taskNum));
  final noEvidence = evidenceCount == 0;

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
                  onPressed:
                      noEvidence ? null : () => _onConfirmUser(context, ref, task),
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
          if (noEvidence) ...[
            const SizedBox(height: 8),
            const SizedBox(
              width: double.infinity,
              child: Text(
                '暂无履约证据，待飞手上传后方可确认完成',
                style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
          ],
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

  // 撮合双确认阶段（TASK-APP-004 / ADR-0003 决定 4）：待飞手确认 / 已确认待执飞
  // 的任务仍是 IDLE，但不能落到下方「删除任务」分支——此阶段要提供履约沟通
  // （联系飞手）与直播入口，等待/可开飞文案由服务端 actionHint 横幅承担。
  if (task.isIdle &&
      !(task.isAwaitingRiderConfirm || task.isConfirmedForFlight)) {
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

  // 已接单状态（含双确认阶段、执行中、已完成等有飞手的任务）：
  // 联系飞手 + 观看直播入口（履约中沟通与直播沿用既有链路）。
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

/// 飞手端撮合区（TASK-APP-005 / ADR-0003）：
///   招募中 → 选机型应征（绑定设备映射机型优先；未绑机/未映射 → 引导去绑机页）；
///   应征成功 → 只读展示系统报价 quotedAmount（客户端不传金额，无议价入口）；
///   待我确认 → 确认约定作业时间（回显 scheduledTime）后调用 confirm-order；
///   已确认 → 执飞引导（djifly，无系统深链时展示任务号 + 说明文案）；
///   聊天入口绑定 taskNum（应用内已应征时附 applicationId）进入订单内会话。
class _PilotMatchSection extends ConsumerStatefulWidget {
  final TaskVo task;
  final VoidCallback onTaskRefreshed;

  const _PilotMatchSection({
    required this.task,
    required this.onTaskRefreshed,
  });

  @override
  ConsumerState<_PilotMatchSection> createState() =>
      _PilotMatchSectionState();
}

class _PilotMatchSectionState extends ConsumerState<_PilotMatchSection> {
  /// 绑定设备映射的机型 ID（null = 未绑机或旧注册路径未映射机型）。
  int? _boundModelId;

  int? _selectedModelId;
  String? _error;
  bool _preparing = false;
  bool _submitting = false;
  bool _confirming = false;
  TaskApplicationVo? _applied;

  TaskVo get task => widget.task;

  @override
  void initState() {
    super.initState();
    if (task.canApply) {
      _preparing = true;
      // 延迟到 build 之外再改 provider（Riverpod 禁止生命周期内同步修改）。
      Future.microtask(_prepare);
    }
  }

  /// 应征前置：拉绑定设备（映射机型优先预选）+ 机型目录（aircraftModelsProvider）。
  Future<void> _prepare() async {
    await ref.read(droneListProvider.notifier).load();
    if (!mounted) return;

    int? bound;
    for (final drone in ref.read(droneListProvider).drones) {
      if (drone.aircraftModelId != null) {
        bound = drone.aircraftModelId;
        break;
      }
    }

    int? preselect;
    String? catalogError;
    if (bound != null) {
      await ref.read(aircraftModelsProvider.notifier).load();
      if (!mounted) return;
      final catalog = ref.read(aircraftModelsProvider);
      if (catalog.models.any((m) => m.id == bound)) {
        preselect = bound;
      }
      catalogError = catalog.error;
    }

    setState(() {
      _boundModelId = bound;
      _selectedModelId = preselect;
      _error = catalogError;
      _preparing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final myJobs = ref.watch(myRiderTasksProvider);
    final inMyJobs = myJobs.activeTasks.any((t) => t.taskNum == task.taskNum);
    final showApply = task.canApply &&
        _applied == null &&
        !inMyJobs;
    final awaitingConfirm = task.isAwaitingRiderConfirm;
    final confirmed = task.isConfirmedForFlight || task.isInProgress;

    // 系统报价只读（ADR-0003）：仅展示应用内刚应征拿到的系统报价；
    // 任务回显报价由下方「任务信息」统一展示，避免重复。
    final quote = _applied?.quotedAmountText ?? '';

    final children = <Widget>[];

    if (quote.isNotEmpty) {
      children.add(_infoRow('系统报价', '$quote（平台计价）'));
      children.add(const SizedBox(height: 4));
    }

    if (showApply) {
      children.addAll(_buildApplyForm());
    } else if (_applied != null) {
      children.add(_appliedBox('应征成功，等待用户选定下单'));
    }

    if (_error != null && !showApply) {
      children.add(Text(
        _error!,
        style: const TextStyle(fontSize: 13, color: AppColors.error),
      ));
      children.add(const SizedBox(height: 8));
    }

    if (awaitingConfirm) {
      children.add(SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _confirming ? null : _onConfirm,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(_confirming ? '确认中…' : '确认订单',
              style: const TextStyle(fontSize: 16)),
        ),
      ));
    }

    if (confirmed) {
      children.add(SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _onOpenDjifly,
          icon: const Icon(Icons.flight_takeoff, size: 18),
          label: const Text('打开 djifly', style: TextStyle(fontSize: 16)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ));
    }

    // 订单内聊天：已应征/已选定/已确认后可与用户沟通（同 taskNum 会话）。
    if (!showApply) {
      final creating = ref.watch(sessionListProvider).creatingSession;
      children.add(SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: creating ? null : _onContactUser,
          icon: creating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.chat_bubble_outline, size: 18),
          label: Text(creating ? '正在连接' : '联系用户'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: _buildSection('吊运撮合', children),
    );
  }

  /// 应征表单：机型下拉（绑定设备映射优先预选）+ 应征按钮。
  /// 未选机型时拒绝提交；无任何金额输入（ADR-0003 禁止改价）。
  List<Widget> _buildApplyForm() {
    if (_preparing) {
      return const [
        SizedBox(height: 8),
        Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        SizedBox(height: 8),
      ];
    }

    // 未绑机 / 绑定设备未映射机型 → 引导去绑机页（服务端 AIRCRAFT_MODEL_REQUIRED 门禁）。
    if (_boundModelId == null) {
      return [
        Text(
          '尚未绑定已映射机型的无人机，无法应征吊运任务。',
          style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => context.push('/pilot/drones'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('去绑定设备', style: TextStyle(fontSize: 16)),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ];
    }

    final models = ref.watch(aircraftModelsProvider).models;
    return [
      DropdownButtonFormField<int>(
        initialValue: _selectedModelId,
        decoration: const InputDecoration(
          labelText: '本次使用机型',
          border: OutlineInputBorder(),
        ),
        items: [
          for (final model in models)
            DropdownMenuItem<int>(
              value: model.id,
              child: Text(
                [
                  model.displayName ?? model.modelCode ?? '未知机型',
                  if (model.maxPayloadKg != null)
                    '载重 ${_kgText(model.maxPayloadKg!)} kg',
                ].join(' · '),
                style: const TextStyle(fontSize: 14),
              ),
            ),
        ],
        hint: const Text('请选择机型'),
        onChanged: _submitting
            ? null
            : (value) => setState(() {
                  _selectedModelId = value;
                  _error = null;
                }),
      ),
      const SizedBox(height: 8),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            _error!,
            style: const TextStyle(fontSize: 13, color: AppColors.error),
          ),
        ),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _submitting ? null : _onApply,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(_submitting ? '应征中…' : '应征任务',
              style: const TextStyle(fontSize: 16)),
        ),
      ),
    ];
  }

  /// 载重展示：整数去小数点（30 而非 30.0）。
  static String _kgText(double kg) =>
      kg == kg.roundToDouble() ? '${kg.toInt()}' : '$kg';

  Widget _appliedBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.statusInProgress,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, color: AppColors.statusInProgressText),
      ),
    );
  }

  /// 应征提交：只发 taskNum + aircraftModelId，金额由平台计价（ADR-0003）。
  Future<void> _onApply() async {
    final modelId = _selectedModelId;
    if (modelId == null) {
      setState(() => _error = '请先选择本次使用的机型');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await ref
        .read(riderApiProvider)
        .apply(taskNum: task.taskNum, aircraftModelId: modelId);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!result.success || result.data == null) {
      // 服务端业务失败（超重/机型不可吊运/机型不匹配等）直接展示 message。
      setState(() => _error = result.message ?? '应征失败，请稍后重试');
      return;
    }
    setState(() => _applied = result.data);
    widget.onTaskRefreshed();
  }

  /// 确认订单：先回显约定作业时间，再调用 confirm-order（ADR-0003 决定 4）。
  Future<void> _onConfirm() async {
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
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('再想想'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确认接单'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _confirming = true);
    final result = await ref.read(riderApiProvider).confirmOrder(task.taskNum);
    if (!mounted) return;
    setState(() => _confirming = false);
    if (!result.success) {
      setState(() => _error = result.message ?? '确认失败，请稍后重试');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已确认订单')),
    );
    widget.onTaskRefreshed();
  }

  /// 执飞引导：无系统深链时降级为任务号 + 说明文案（ADR-0002 边界）。
  void _onOpenDjifly() {
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

  /// 订单内聊天（ADR-0003 决定 1）：同 taskNum 建会话（服务端按任务 + 飞手去重），
  /// 应用内刚应征时附 applicationId 精确挂到应征记录。
  Future<void> _onContactUser() async {
    final session = await ref.read(sessionListProvider.notifier).createDirectSession(
          name: '${task.taskTypeName} - ${task.taskName}',
          userId: task.userId,
          taskNum: task.taskNum,
          applicationId: _applied?.applicationId,
        );
    if (!mounted) return;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(sessionListProvider).error ?? '创建会话失败'),
        ),
      );
      return;
    }
    final name = session.otherUserName ?? '用户';
    context.push('/chat/${session.id}?name=${Uri.encodeComponent(name)}');
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
