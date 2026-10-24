import 'waybill_layout.dart';
import '../../widgets/flow_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/waybill_draft_provider.dart';
import 'photo_fields.dart';
import 'site_fields.dart';
import 'time_fields.dart';
import 'waybill_fields.dart';
import 'waybill_review.dart';

// REQ-SHIP-PUB-002. Assessment and payment remain validated by the server.
class WaybillPage extends ConsumerStatefulWidget {
  const WaybillPage({super.key});

  @override
  ConsumerState<WaybillPage> createState() => _WaybillPageState();
}

class _WaybillPageState extends ConsumerState<WaybillPage> {
  Map<String, String> _errors = {};
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _change(String key, String value) {
    ref.read(waybillDraftProvider.notifier).update(key, value);
    if (_errors.isNotEmpty) setState(() => _errors = {});
  }

  void _move(int step) {
    ref.read(waybillDraftProvider.notifier).move(step);
    setState(() => _errors = {});
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _next() {
    final draft = ref.read(waybillDraftProvider).draft;
    final errors = draft.errorsFor(draft.step);
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请检查本步标出的信息')));
      return;
    }
    _move(draft.step + 1);
  }

  Future<void> _save() async {
    final ok = await ref.read(waybillDraftProvider.notifier).save();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(ok ? '运单草稿已保存' : '草稿保存失败，请重试')));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(waybillDraftProvider.select((value) => value.formRevision), (
      previous,
      next,
    ) {
      if (previous != next && _errors.isNotEmpty) setState(() => _errors = {});
    });
    final state = ref.watch(waybillDraftProvider);
    final draft = state.draft;
    final step = draft.step;
    final scope = ref.watch(waybillDraftScopeProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('填写吊运运单'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1D2129),
        leading: IconButton(
          tooltip: step > 0 ? '上一步' : '返回',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (step > 0) {
              _move(step - 1);
            } else {
              context.go('/home');
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: state.saving ? null : _save,
            child: const Text('保存草稿'),
          ),
        ],
      ),
      body: Column(
        children: [
          WaybillStepIndicator(step: step),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                state.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: FlowList(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              spacing: 12,
              children: [
                WaybillGuide(
                  title: const [
                    '这次要运什么？',
                    '从哪里起吊？',
                    '送到哪里？',
                    '什么时候出发？',
                    '确认本次吊运',
                  ][step],
                  subtitle: const [
                    '填写货物信息，再选择起终点和出发时间。',
                    '精确选点，补充场地条件与现场联系人。',
                    '确认卸货位置和交付方式，让现场衔接更顺畅。',
                    '选择立即出发或预约时间。',
                    '核对运单、查看评估与报价，然后创建订单。',
                  ][step],
                ),
                KeyedSubtree(
                  key: ValueKey('$scope/$step/${state.formRevision}'),
                  child: switch (step) {
                    0 => Column(
                      spacing: 12,
                      children: [
                        CargoFields(
                          draft: draft,
                          onChanged: _change,
                          errors: _errors,
                        ),
                        PhotoFields(draft: draft, group: 'cargo'),
                      ],
                    ),
                    1 || 2 => Column(
                      spacing: 12,
                      children: [
                        SiteFields(
                          draft: draft,
                          prefix: step == 1 ? 'start' : 'end',
                          onChanged: _change,
                          errors: _errors,
                        ),
                        PhotoFields(
                          draft: draft,
                          group: step == 1 ? 'start' : 'end',
                        ),
                      ],
                    ),
                    3 => TimeFields(
                      draft: draft,
                      onChanged: _change,
                      errors: _errors,
                    ),
                    _ => WaybillReview(draft: draft),
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('waybill-next'),
                    onPressed: step == 4
                        ? (state.saving ? null : _save)
                        : _next,
                    child: Text(step == 4 ? '保存运单草稿' : '下一步'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
