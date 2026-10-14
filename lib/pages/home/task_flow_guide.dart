import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const taskFlowGuideDismissedKey = 'task_flow_guide_dismissed_v1';
const pilotTaskFlowGuideDismissedKey = 'pilot_task_flow_guide_dismissed_v1';

Future<void> showTaskFlowGuide(
  BuildContext context,
  SharedPreferences prefs, {
  bool isPilot = false,
}) async {
  final hide = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: .68),
    barrierDismissible: false,
    builder: (_) => TaskFlowGuide(isPilot: isPilot),
  );
  if (hide == true) {
    final saved = await prefs.setBool(
      isPilot ? pilotTaskFlowGuideDismissedKey : taskFlowGuideDismissedKey,
      true,
    );
    if (!saved && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('偏好未保存，下次进入首页仍会显示指南')));
    }
  }
}

class TaskFlowGuide extends StatefulWidget {
  const TaskFlowGuide({super.key, this.isPilot = false});
  final bool isPilot;
  @override
  State<TaskFlowGuide> createState() => _TaskFlowGuideState();
}

class _TaskFlowGuideState extends State<TaskFlowGuide> {
  bool _hide = false;
  static const _steps = [
    (
      '发布吊运需求',
      '填写起吊点、卸货点、货物与期望时间，核对信息后确认发布。此时无需支付。',
      Icons.add_location_alt_outlined,
    ),
    (
      '洽谈并选择飞手',
      '多名飞手可以应征。查看系统报价，通过任务内聊天沟通，再选定一名飞手和作业时间。',
      Icons.people_alt_outlined,
    ),
    (
      '支付，等待双方确认',
      '核对订单金额并支付，再等待飞手确认作业时间。双方确认后进入可执行阶段。',
      Icons.verified_user_outlined,
    ),
    (
      '跟进吊运作业',
      '在订单详情查看任务进度，与飞手保持沟通；有直播时可进入观看。进行中不代表已经起飞。',
      Icons.flight_takeoff_rounded,
    ),
    (
      '验收后结束任务',
      '飞手交付后，核对成果与履约证据。确认验收后交易完成；有问题先沟通，不要提前确认。',
      Icons.fact_check_outlined,
    ),
  ];
  static const _pilotSteps = [
    (
      '查看需求，选择机型应征',
      '核对起卸点、货物重量与作业要求，选择支持吊运且载重满足要求的机型提交应征。',
      Icons.precision_manufacturing_outlined,
    ),
    (
      '查看报价，与用户洽谈',
      '报价由平台计算。通过任务内聊天沟通作业安排，等待用户选定；应征成功不代表已获得任务。',
      Icons.forum_outlined,
    ),
    (
      '用户支付后，确认订单',
      '被选定并由用户支付后，核对约定作业时间再确认订单。双方确认后才可进入执行阶段。',
      Icons.verified_user_outlined,
    ),
    (
      '做好准备，执行吊运',
      '完成作业准备与安全检查，在 djifly 中执行真实飞行。本 App 用于任务协作与进度查询，进行中不代表已起飞。',
      Icons.flight_takeoff_rounded,
    ),
    (
      '交付成果，等待用户验收',
      '作业完成后上传履约证据并提交交付，等待用户核对和确认验收。交付完成不等于交易已结束。',
      Icons.fact_check_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    const accent = Color(0xFFFF8A24);
    final steps = widget.isPilot ? _pilotSteps : _steps;
    return Dialog(
      key: const ValueKey('task-flow-guide'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: MediaQuery.sizeOf(context).height * .86,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF172A42), Color(0xFF263F5D)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.route_outlined, color: accent, size: 19),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.isPilot ? '新手指南 · 飞手作业' : '新手指南 · 吊运服务',
                          style: const TextStyle(
                            color: Color(0xFFBDCCDD),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: '本次关闭',
                        onPressed: () => Navigator.of(context).pop(false),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    widget.isPilot ? '从应征到交付，\n每一步都有方向' : '从发布到验收，\n每一步都有方向',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isPilot ? '应征不是接单，双方确认后再执行' : '先发布需求，选定飞手后再支付',
                    style: TextStyle(color: Color(0xFFD1DCE8), fontSize: 13),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                key: const ValueKey('task-flow-guide-steps'),
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  final step = steps[index];
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 32,
                          child: Column(
                            children: [
                              Container(
                                height: 30,
                                width: 30,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: dark
                                      ? const Color(0xFF523722)
                                      : const Color(0xFFFFEBD9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: accent,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (index < steps.length - 1)
                                Expanded(
                                  child: Container(
                                    width: 1,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    color: scheme.outlineVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        step.$1,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: scheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      step.$3,
                                      size: 19,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  step.$2,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.6,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                children: [
                  CheckboxListTile(
                    key: const ValueKey('task-flow-guide-hide'),
                    value: _hide,
                    onChanged: (value) =>
                        setState(() => _hide = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text(
                      '不再自动显示，可在首页「流程指南」重看',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const ValueKey('task-flow-guide-done'),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: const Color(0xFF172A42),
                        minimumSize: const Size.fromHeight(46),
                      ),
                      onPressed: () => Navigator.of(context).pop(_hide),
                      child: Text(widget.isPilot ? '知道了，去看任务' : '知道了，开始发布'),
                    ),
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
