// 应征飞手区块（TASK-APP-003 / ADR-0003 撮合中心）：
//   GET /task/{taskNum}/applications → 飞手头像/昵称、机型名、载重、系统报价、应征时间；
//   点击应征项进入订单内聊天（已有会话直接进，否则 /chat/session/create 带
//   taskNum + applicationId，服务端按同任务 + 飞手去重）；
//   「选定飞手」（TASK-APP-004）→ 约定作业时间弹窗 → POST /task/{taskNum}/select-rider
//   → 刷新详情后进入既有支付流（锁价校验见 pay_entry.dart）。
// 红线（ADR-0003 决定 2）：quotedAmount 只读展示，本区块不存在任何价格输入控件。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/task_application_vo.dart';
import '../../../models/task_chat_session_vo.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../theme/app_colors.dart';
import '../pay_entry.dart';
import 'select_rider_dialog.dart';

class ApplicationsSection extends ConsumerWidget {
  final String taskNum;

  /// 是否处于招募/洽谈阶段（未选定飞手）：空状态文案只在该阶段出现，
  /// 后续阶段（已选定/已确认）无应征时直接隐藏，避免「等待接单」误导。
  final bool inMatching;

  const ApplicationsSection({
    super.key,
    required this.taskNum,
    required this.inMatching,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(taskApplicationsProvider(taskNum));
    // 选定飞手后其余应征自动关闭（ADR-0003 决定 1）：CLOSED 记录不再展示，
    // SELECTED（已选定）仍保留作为选定结果回显。
    final visible = state.applications
        .where((app) => app.status != 'CLOSED')
        .toList();

    if (!inMatching && visible.isEmpty) {
      return const SizedBox.shrink();
    }
    if (state.loading) {
      return _section(context, [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ]);
    }
    if (visible.isEmpty) {
      if (state.error != null) return _errorCard(context, ref);
      return _section(context, [
        // 空状态（REQ-APP-002 场景 2）：暂无应征时提示等待飞手接单。
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          alignment: Alignment.center,
          child: Column(
            children: [
              Icon(
                Icons.person_search_outlined,
                size: 40,
                color: AppColors.outline.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 8),
              const Text(
                '等待飞手接单',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ]);
    }

    final sessions = ref.watch(taskChatSessionsProvider(taskNum));
    return _section(context, [
      for (final app in visible)
        _ApplicationTile(
          taskNum: taskNum,
          application: app,
          unread: _unreadFor(sessions.sessions, app),
          canSelect: inMatching && app.applicationId != null,
        ),
      if (state.error != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '应征刷新失败：${state.error}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              TextButton(
                onPressed: () =>
                    ref.read(taskApplicationsProvider(taskNum).notifier).load(),
                child: const Text('重试', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
    ]);
  }

  Widget _errorCard(BuildContext context, WidgetRef ref) {
    return _section(context, [
      const Text(
        '应征列表加载失败',
        style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
      ),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton(
          onPressed: () =>
              ref.read(taskApplicationsProvider(taskNum).notifier).load(),
          child: const Text('重试'),
        ),
      ),
    ]);
  }

  Widget _section(BuildContext context, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '应征飞手',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          if (inMatching) ...[
            const SizedBox(height: 6),
            Text(
              '可先沟通比较，再选定一位飞手下单',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  /// 应征项 → 任务会话的未读数（按 applicationId 优先，riderId 兜底）。
  static int _unreadFor(
    List<TaskChatSessionVo> sessions,
    TaskApplicationVo app,
  ) {
    for (final session in sessions) {
      final sameApplication =
          app.applicationId != null &&
          session.applicationId == app.applicationId;
      final sameRider = app.riderId != null && session.riderId == app.riderId;
      if (sameApplication || sameRider) return session.unreadCount;
    }
    return 0;
  }
}

/// 应征列表单项：头像 + 昵称 + 机型/载重 + 系统报价（只读） + 应征时间，
/// 卡片底部的整行「选定飞手」主操作（招募/洽谈阶段）与独立聊天入口。
class _ApplicationTile extends ConsumerWidget {
  final String taskNum;
  final TaskApplicationVo application;
  final int unread;

  /// 是否可选定该飞手（仅招募/洽谈阶段且应征带 applicationId）。
  final bool canSelect;

  const _ApplicationTile({
    required this.taskNum,
    required this.application,
    required this.unread,
    required this.canSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = application;
    final scheme = Theme.of(context).colorScheme;
    final selected = app.status == 'SELECTED';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? scheme.primary : scheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: scheme.primaryContainer,
                child: Icon(
                  Icons.person_rounded,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        app.aircraftLabel,
                        if (app.payloadText.isNotEmpty) app.payloadText,
                      ].join(' · '),
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    '已选定',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: scheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                '系统报价',
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  app.quotedAmountText,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFFFB36B)
                        : AppColors.accentDark,
                  ),
                ),
              ),
            ],
          ),
          if (app.formattedAppliedAt.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '应征于 ${app.formattedAppliedAt}',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 14),
          if (canSelect && !selected) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: ValueKey('select-rider-${app.applicationId}'),
                onPressed: () => _onSelect(context, ref),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFC45100),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 21),
                label: const Text(
                  '选定飞手',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: ValueKey('chat-rider-${app.applicationId}'),
              onPressed: () => _openChat(context, ref),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                foregroundColor: scheme.primary,
                side: BorderSide(color: scheme.outlineVariant),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: Text(
                unread > 0
                    ? '聊一聊 · ${unread > 99 ? '99+' : unread} 条未读'
                    : '聊一聊',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 选定飞手完整路径（TASK-APP-004）：约定作业时间弹窗 →
  /// POST /task/{taskNum}/select-rider（锁价 totalAmount = quotedAmount）→
  /// 刷新应征列表（其余 CLOSED）→ 进入既有支付流（先做锁价一致性校验）。
  Future<void> _onSelect(BuildContext context, WidgetRef ref) async {
    final selected = await showSelectRiderDialog(
      context,
      taskNum: taskNum,
      application: application,
    );
    if (selected != true || !context.mounted) return;
    // 在任何 await 之前抓取页面级句柄：刷新应征列表后本卡片可能被重建卸载，
    // 不能再依赖本卡片的 context 进入收银台。
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final container = ProviderScope.containerOf(context, listen: false);
    final quoted = application.quotedAmount;
    await container.read(taskApplicationsProvider(taskNum).notifier).load();
    await openPayEntryWith(
      navigator: navigator,
      messenger: messenger,
      container: container,
      taskNum: taskNum,
      quotedAmount: quoted,
    );
  }

  /// 进入订单内聊天：优先复用 /task/{taskNum}/chat-sessions 里已有的会话，
  /// 否则创建（带 taskNum + applicationId，服务端按同任务 + 飞手去重）；
  /// 返回详情页后刷新任务会话，使未读红点与服务端已读推进对齐。
  Future<void> _openChat(BuildContext context, WidgetRef ref) async {
    final app = application;
    final existing = ref.read(taskChatSessionsProvider(taskNum)).sessions;
    int? sessionId;
    for (final session in existing) {
      final sameApplication =
          app.applicationId != null &&
          session.applicationId == app.applicationId;
      final sameRider = app.riderId != null && session.riderId == app.riderId;
      if (sameApplication || sameRider) {
        sessionId = session.sessionId;
        break;
      }
    }

    if (sessionId == null) {
      final riderId = app.riderId;
      if (riderId == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('该应征缺少飞手信息，无法发起会话')));
        }
        return;
      }
      final session = await ref
          .read(sessionListProvider.notifier)
          .createDirectSession(
            name: app.displayName,
            userId: riderId,
            taskNum: taskNum,
            applicationId: app.applicationId,
          );
      sessionId = session?.id;
    }

    if (!context.mounted) return;
    if (sessionId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('创建会话失败，请稍后重试')));
      return;
    }

    await context.push(
      '/chat/$sessionId?name=${Uri.encodeComponent(app.displayName)}',
    );
    if (!context.mounted) return;
    await ref.read(taskChatSessionsProvider(taskNum).notifier).load();
  }
}
