import 'dart:convert';
import 'dispatch_price_card.dart';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../models/dispatch_order.dart';
import '../../models/waybill_draft.dart';
import '../../providers/dispatch_order_provider.dart';
import '../../providers/dispatch_material_provider.dart';
import '../../services/dispatch_draft_materials.dart';
import '../../providers/waybill_draft_provider.dart';

class DispatchCheckoutCard extends ConsumerStatefulWidget {
  const DispatchCheckoutCard({super.key, required this.draft});
  final WaybillDraft draft;
  @override
  ConsumerState<DispatchCheckoutCard> createState() =>
      _DispatchCheckoutCardState();
}

class _DispatchCheckoutCardState extends ConsumerState<DispatchCheckoutCard> {
  bool _busy = false;
  bool _accepted = false;
  String? _message;
  DispatchAssessment? _assessment;
  String _fingerprint(WaybillDraft draft) =>
      jsonEncode(SplayTreeMap<String, String>.from(draft.cloudFields));
  @override
  void didUpdateWidget(covariant DispatchCheckoutCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_fingerprint(oldWidget.draft) != _fingerprint(widget.draft)) {
      _assessment = null;
      _accepted = false;
      _message = null;
    }
  }

  Future<void> _run({required bool submit}) async {
    if (_busy) return;
    final draft = widget.draft;
    for (var step = 0; step < 4; step++) {
      if (draft.errorsFor(step).isNotEmpty) {
        setState(() => _message = '请返回“${WaybillDraft.steps[step]}”补全并检查信息');
        return;
      }
    }
    if (submit && !_accepted) return;
    final scope = ref.read(waybillDraftScopeProvider);
    bool current() =>
        mounted &&
        scope == ref.read(waybillDraftScopeProvider) &&
        _fingerprint(draft) == _fingerprint(widget.draft);
    final api = ref.read(dispatchOrderApiProvider);
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final readiness = await api.readiness();
      if (!current()) return;
      if (!readiness.enabled) {
        setState(
          () => _message = readiness.blockers.isEmpty
              ? '下单条件尚未就绪，请稍后重试'
              : readiness.blockers.join('\n'),
        );
        return;
      }
      if (!submit) {
        final result = await api.assess(draft);
        if (current()) setState(() => _assessment = result);
        return;
      }
      final assessment = _assessment;
      if (assessment == null || !assessment.allowed) return;
      final notifier = ref.read(waybillDraftProvider.notifier);
      final fingerprint = _fingerprint(draft);
      var key = draft.value('submission.requestKey');
      if (key.isEmpty || draft.value('submission.fingerprint') != fingerprint) {
        key = const Uuid().v4();
        notifier.update('submission.requestKey', key);
        notifier.update('submission.fingerprint', fingerprint);
      }
      // Save the key before sending: process death/timeouts must retain the same attempt.
      if (!await notifier.save()) throw StateError('下单标识保存失败，请重试');
      if (!current()) return;
      final order = await api.create(draft, assessment.id, key);
      if (!current()) return;
      notifier.update('submission.orderId', order.id);
      await notifier.save();
      if (!current()) return;
      if (draft.fields.entries.any(
        (entry) => entry.key.contains('.photo.') && entry.value.isNotEmpty,
      )) {
        await uploadDispatchDraftMaterials(
          draft: draft,
          orderId: order.id,
          api: ref.read(dispatchMaterialApiProvider),
          current: current,
          saved: (key) => ref.read(waybillDraftProvider).draft.value(key),
          persist: (key, value) async {
            notifier.update(key, value);
            if (!await notifier.save()) throw StateError('凭证上传记录保存失败，请重试');
          },
        );
      }
      if (!current()) return;
      if (!mounted) return;
      ref.invalidate(dispatchOrdersProvider);
      context.push('/dispatch/orders/${Uri.encodeComponent(order.id)}');
    } catch (error) {
      if (current()) setState(() => _message = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assessment = _assessment;
    final evaluation = assessment?.data.evaluation;
    final previousOrder =
        widget.draft.value('submission.fingerprint') ==
            _fingerprint(widget.draft)
        ? widget.draft.value('submission.orderId')
        : '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Text('确认下单', style: Theme.of(context).textTheme.titleMedium),
            const Text('当前使用模拟支付，不会真实扣款。按起终点直线距离计价，加固定飞手服务费；定金在结算时抵扣。'),
            const Text('创建订单后上传草稿照片，服务端核验后才计入材料；失败可重试或进入已有订单补充。'),
            if (assessment != null)
              DispatchPriceCard(quote: assessment.data.quote),
            if (evaluation != null) ...[
              if (evaluation.source == 'SIMULATED_DEMO')
                const Text('模拟评估 · 以下为演示样例，不代表真实可飞'),
              Text('环境评估预计飞行：${evaluation.flightMinutes} 分钟（计价距离以上方价格为准）'),
              Text(
                '高差：${evaluation.altitudeDifferenceMeters} m · 地形：${evaluation.terrain}',
              ),
              Text(
                '空域：${evaluation.airspace == 'PROHIBITED'
                    ? '禁飞，不能下单'
                    : evaluation.airspace == 'CAUTION'
                    ? '需注意'
                    : '可飞'}',
              ),
              Text(
                '数据来源：${evaluation.source} · 有效至 ${assessment!.data.expiresAt}',
              ),
              for (final warning in evaluation.warnings ?? <String>[])
                Text(warning),
            ],
            if (_message != null)
              Text(
                _message!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('信息真实、无违禁品'),
              value: _accepted,
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _accepted = value ?? false),
            ),
            OutlinedButton(
              onPressed: _busy ? null : () => _run(submit: false),
              child: Text(_busy ? '处理中…' : '检查并评估运单'),
            ),
            FilledButton(
              onPressed: _busy || !_accepted || assessment?.allowed != true
                  ? null
                  : () => _run(submit: true),
              child: const Text('确认运单，前往模拟支付'),
            ),
            TextButton(
              onPressed: _busy ? null : () => context.push('/dispatch/orders'),
              child: const Text('查看我的派单运单'),
            ),
            if (previousOrder.isNotEmpty) ...[
              TextButton(
                onPressed: _busy
                    ? null
                    : () => context.push(
                        '/dispatch/orders/${Uri.encodeComponent(previousOrder)}',
                      ),
                child: const Text('查看这份运单已创建的订单'),
              ),
              TextButton(
                onPressed: _busy ? null : _newAttempt,
                child: const Text('使用相同信息另建一单'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _newAttempt() async {
    final scope = ref.read(waybillDraftScopeProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('另建一单'),
        content: const Text('原订单会保留。确认使用相同信息创建另一笔订单？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('返回'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认另建'),
          ),
        ],
      ),
    );
    if (confirmed != true ||
        !mounted ||
        scope != ref.read(waybillDraftScopeProvider)) {
      return;
    }
    final notifier = ref.read(waybillDraftProvider.notifier);
    for (final key in [
      'submission.requestKey',
      'submission.fingerprint',
      'submission.orderId',
    ]) {
      notifier.update(key, '');
    }
    setState(() {
      _assessment = null;
      _accepted = false;
      _message = null;
    });
  }
}
