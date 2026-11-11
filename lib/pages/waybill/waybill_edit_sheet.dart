import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/waybill_draft.dart';
import '../../providers/waybill_draft_provider.dart';
import 'waybill_edit_group.dart';
import 'waybill_fields.dart';
import 'waybill_form_theme.dart';
import 'site_fields.dart';
import 'time_fields.dart';
import 'photo_fields.dart';

Future<bool?> editWaybillGroup(
  BuildContext context,
  WaybillEditGroup group, {
  Map<String, String> initialErrors = const {},
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (context) => Theme(
    data: waybillFormTheme(Theme.of(context)),
    child: _EditSheet(group: group, initialErrors: initialErrors),
  ),
);

class _EditSheet extends ConsumerStatefulWidget {
  const _EditSheet({required this.group, required this.initialErrors});
  final WaybillEditGroup group;
  final Map<String, String> initialErrors;
  @override
  ConsumerState<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends ConsumerState<_EditSheet> {
  late final WaybillDraft _initial;
  late WaybillDraft _draft;
  late final String? _scope;
  late final int _revision;
  Map<String, String> _errors = {};
  bool _closing = false;
  void _close(bool saved) {
    if (!mounted || _closing) return;
    _closing = true;
    Navigator.pop(context, saved);
  }

  @override
  void initState() {
    super.initState();
    final state = ref.read(waybillDraftProvider);
    _draft = _initial = widget.group == WaybillEditGroup.contact
        ? WaybillEditGroup.withSharedContact(state.draft)
        : state.draft;
    _errors = Map.fromEntries(
      widget.initialErrors.entries.where(
        (entry) => widget.group.keys.contains(entry.key),
      ),
    );
    _scope = ref.read(waybillDraftScopeProvider);
    _revision = state.formRevision;
  }

  bool get _current =>
      ref.read(waybillDraftScopeProvider) == _scope &&
      ref.read(waybillDraftProvider).formRevision == _revision;
  void _change(String key, String value) {
    if (!_current) return;
    setState(() {
      _draft = _draft.change(key, value);
      _errors = Map.of(_errors)..remove(key);
    });
  }

  void _save() {
    if (!_current) {
      _close(false);
      return;
    }
    final errors = widget.group.errors(_draft);
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      return;
    }
    var latest = ref.read(waybillDraftProvider).draft;
    for (final key in widget.group.keys) {
      if (widget.group == WaybillEditGroup.contact ||
          _initial.value(key) != _draft.value(key)) {
        latest = latest.change(key, _draft.value(key));
      }
    }
    if (widget.group == WaybillEditGroup.contact) {
      latest = WaybillEditGroup.withSharedContact(latest);
    }
    ref.read(waybillDraftProvider.notifier).replace(latest);
    _close(true);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(waybillDraftScopeProvider, (previous, next) {
      if (previous != next) _close(false);
    });
    ref.listen(waybillDraftProvider.select((s) => s.formRevision), (
      previous,
      next,
    ) {
      if (previous != next) _close(false);
    });
    final group = widget.group;
    final media = MediaQuery.of(context);
    final height = (media.size.height - media.viewInsets.bottom - 16).clamp(
      0.0,
      media.size.height,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: height),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      group.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: () => _close(false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: group.photos != null
                    ? PhotoFields(
                        draft: ref.watch(waybillDraftProvider).draft,
                        group: group.photos!,
                      )
                    : group.prefix != null
                    ? SiteFields(
                        draft: _draft,
                        prefix: group.prefix!,
                        section: group.section,
                        onChanged: _change,
                        errors: _errors,
                      )
                    : group.id == 'time'
                    ? TimeFields(
                        draft: _draft,
                        onChanged: _change,
                        errors: _errors,
                      )
                    : CargoFields(
                        draft: _draft,
                        section: group.section,
                        onChanged: _change,
                        errors: _errors,
                      ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const ValueKey('waybill-editor-save'),
                    onPressed: group.photos != null
                        ? () => _close(true)
                        : _save,
                    child: Text(group.photos != null ? '完成' : '保存'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
