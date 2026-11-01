import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/waybill_draft_provider.dart';
import 'waybill_review.dart';
import 'waybill_summary.dart';
import 'waybill_edit_sheet.dart';
import 'waybill_edit_group.dart';
import 'waybill_form_theme.dart';
import 'dispatch_checkout_card.dart';

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

  Future<void> _edit(WaybillEditGroup group) async {
    final saved = await editWaybillGroup(context, group);
    if (mounted && saved == true) setState(() => _errors = {});
  }

  void _move(int step) {
    ref.read(waybillDraftProvider.notifier).move(step);
    setState(() => _errors = {});
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _next() {
    final draft = ref.read(waybillDraftProvider).draft;
    final errors = <String, String>{};
    for (var i = 0; i < 4; i++) {
      final sectionErrors = draft.errorsFor(i);
      errors.addAll(sectionErrors);
    }
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      _edit(
        WaybillEditGroup.all.firstWhere(
          (group) => group.keys.any(errors.containsKey),
        ),
      );
      return;
    }
    _move(4);
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
    final step = draft.step == 4 ? 4 : 0;
    final scope = ref.watch(waybillDraftScopeProvider);
    return Theme(
      data: waybillFormTheme(Theme.of(context)),
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF111111),
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111111),
          ),
          title: Text(step == 4 ? '确认运单' : '填写运单'),
          leading: IconButton(
            tooltip: step > 0 ? '上一步' : '返回',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              if (step > 0) {
                _move(0);
              } else {
                context.go('/home');
              }
            },
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2B65D9),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              onPressed: state.saving ? null : _save,
              child: const Text('保存草稿'),
            ),
          ],
        ),
        body: Column(
          children: [
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  state.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scroll,
                padding: step == 4
                    ? const EdgeInsets.fromLTRB(16, 8, 16, 12)
                    : const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    KeyedSubtree(
                      key: ValueKey('$scope/$step/${state.formRevision}'),
                      child: step == 4
                          ? WaybillReview(draft: draft)
                          : WaybillSummary(
                              draft: draft,
                              errors: _errors,
                              onEdit: _edit,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: step == 4
            ? DispatchCheckoutCard(draft: draft, compact: true)
            : DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFEEEEEE), width: 0.5),
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
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 46),
                              maximumSize: const Size(double.infinity, 46),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            key: const ValueKey('waybill-next'),
                            onPressed: step == 4
                                ? (state.saving ? null : _save)
                                : _next,
                            child: Text(step == 4 ? '保存运单草稿' : '确认运单'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
