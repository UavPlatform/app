import 'package:flutter/material.dart';

import '../models/task_vo.dart';
import '../theme/app_colors.dart';

/// 撮合阶段标签（REQ-APP-002：首页卡片、订单列表、详情页文案一致）。
///
/// 文案来自 [TaskVo.stageLabel]，配色按 [TaskVo.stageTone] 分组；
/// 订单列表在没有对应任务时可用 [StageTag.raw] 直接给出文案与分组。
class StageTag extends StatelessWidget {
  final String label;
  final StageTone tone;

  StageTag({super.key, required TaskVo task})
    : label = task.stageLabel,
      tone = task.stageTone;

  const StageTag.raw({super.key, required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (tone) {
      StageTone.todo => (AppColors.statusPending, AppColors.statusPendingText),
      StageTone.active => (
        AppColors.statusInProgress,
        AppColors.statusInProgressText,
      ),
      StageTone.done => (
        AppColors.statusCompleted,
        AppColors.statusCompletedText,
      ),
      StageTone.stopped => (
        AppColors.statusCancelled,
        AppColors.statusCancelledText,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: fg)),
    );
  }
}
