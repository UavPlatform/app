import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/waybill_draft.dart';
import '../../providers/waybill_draft_provider.dart';
import 'waybill_review.dart';
import 'waybill_summary.dart';
import 'waybill_edit_sheet.dart';
import 'waybill_edit_group.dart';
import 'waybill_form_theme.dart';
import 'waybill_location_picker.dart';
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
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(waybillDraftProvider.notifier).resumeLatest();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _edit(WaybillEditGroup group) async {
    if (group.id.endsWith('.location')) {
      final initial = ref.read(waybillDraftProvider);
      final scope = ref.read(waybillDraftScopeProvider);
      final picked = await pickWaybillLocation(context, group.prefix!);
      if (!mounted ||
          picked == null ||
          scope != ref.read(waybillDraftScopeProvider)) {
        return;
      }
      final current = ref.read(waybillDraftProvider);
      if (current.formRevision != initial.formRevision ||
          group.keys.any(
            (key) => current.draft.value(key) != initial.draft.value(key),
          )) {
        return;
      }
      var draft = current.draft;
      for (final entry in picked.entries) {
        draft = draft.change(entry.key, entry.value);
      }
      ref.read(waybillDraftProvider.notifier).replace(draft);
      setState(() => _errors = {});
      return;
    }
    final saved = await editWaybillGroup(
      context,
      group,
      initialErrors: _errors,
    );
    if (mounted && saved == true) setState(() => _errors = {});
  }

  void _move(int step) {
    ref.read(waybillDraftProvider.notifier).move(step);
    setState(() => _errors = {});
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  WaybillDraft _sharedContact(WaybillDraft draft) {
    // A submitted draft must retain its original payload for idempotent retries.
    return draft.value('submission.requestKey').isEmpty
        ? WaybillEditGroup.withSharedContact(draft)
        : draft;
  }

  void _next() {
    final draft = _sharedContact(ref.read(waybillDraftProvider).draft);
    final errors = <String, String>{};
    for (var i = 0; i < 4; i++) {
      final sectionErrors = draft.errorsFor(i);
      errors.addAll(sectionErrors);
    }
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      final first = WaybillEditGroup.all
          .where((group) => group.keys.any(errors.containsKey))
          .firstOrNull;
      if (first != null) {
        if (first.id.endsWith('.location')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(first.errors(draft).values.first)),
          );
        }
        _edit(first);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errors.values.first)));
      }
      return;
    }
    ref.read(waybillDraftProvider.notifier).replace(draft.atStep(4));
    setState(() => _errors = {});
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _save() async {
    final notifier = ref.read(waybillDraftProvider.notifier);
    final current = ref.read(waybillDraftProvider).draft;
    final draft = _sharedContact(current);
    if (!identical(draft, current)) notifier.replace(draft);
    final ok = await notifier.save();
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
    final draft = _sharedContact(state.draft);
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
              child: step == 4
                  ? DispatchCheckoutCard(
                      key: ValueKey(
                        '$scope/${state.activeId}/${state.formRevision}',
                      ),
                      draft: draft,
                      compact: true,
                      review: WaybillReview(draft: draft),
                      scrollController: _scroll,
                    )
                  : SingleChildScrollView(
                      controller: _scroll,
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          KeyedSubtree(
                            key: ValueKey('$scope/$step/${state.formRevision}'),
                            child: WaybillSummary(
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
            ? null
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
