import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/dispatch_provider.dart';
import '../../providers/waybill_draft_provider.dart';

class AccountDraftActions extends ConsumerStatefulWidget {
  const AccountDraftActions({super.key});
  @override
  ConsumerState<AccountDraftActions> createState() =>
      _AccountDraftActionsState();
}

class _AccountDraftActionsState extends ConsumerState<AccountDraftActions> {
  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<bool> _confirm(String text, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('账号草稿'),
          content: Text(text),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _action(String action) async {
    final scope = ref.read(waybillDraftScopeProvider);
    final account = ref.read(accountDraftProvider.notifier);
    if (!await account.load() ||
        !mounted ||
        ref.read(waybillDraftScopeProvider) != scope) {
      if (mounted && ref.read(waybillDraftScopeProvider) == scope) {
        _message(ref.read(accountDraftProvider).error ?? '无法读取账号草稿');
      }
      return;
    }
    final remote = ref.read(accountDraftProvider).draft;
    if (action == 'restore') {
      if (remote == null) {
        _message('账号中还没有运单草稿');
        return;
      }
      if (!await _confirm('用账号草稿替换本机已填写内容？照片仅保存在原设备，不会随账号草稿恢复。', '恢复草稿')) {
        return;
      }
      if (!mounted || ref.read(waybillDraftScopeProvider) != scope) return;
      final local = ref.read(waybillDraftProvider.notifier);
      local.restore(remote.draft);
      final saved = await local.save();
      if (mounted && ref.read(waybillDraftScopeProvider) == scope) {
        _message(saved ? '账号草稿已恢复' : '已恢复，但本机保存失败，请重试');
      }
    } else {
      if (remote != null &&
          !await _confirm('账号已有草稿，确认用本机填写内容更新？照片只保存在本机。', '确认更新')) {
        return;
      }
      if (!mounted || ref.read(waybillDraftScopeProvider) != scope) return;
      final ok = await account.save(
        ref.read(waybillDraftProvider).draft,
        replaceExisting: remote != null,
      );
      if (mounted && ref.read(waybillDraftScopeProvider) == scope) {
        _message(
          ok
              ? '已保存到账号，照片仍只保存在本机'
              : ref.read(accountDraftProvider).error ?? '保存未完成',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: '账号草稿',
    enabled: !ref.watch(accountDraftProvider).busy,
    onSelected: _action,
    itemBuilder: (_) => const [
      PopupMenuItem(value: 'save', child: Text('保存到账号')),
      PopupMenuItem(value: 'restore', child: Text('恢复账号草稿')),
    ],
  );
}
