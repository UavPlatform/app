import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/waybill_draft_entry.dart';
import '../../providers/waybill_draft_provider.dart';

class DraftBoxPage extends ConsumerStatefulWidget {
  const DraftBoxPage({super.key});
  @override
  ConsumerState<DraftBoxPage> createState() => _DraftBoxPageState();
}

class _DraftBoxPageState extends ConsumerState<DraftBoxPage> {
  bool _busy = false;

  Future<void> _open([WaybillDraftEntry? entry]) async {
    if (_busy) return;
    final scope = ref.read(waybillDraftScopeProvider);
    if (scope == null) return;
    final notifier = ref.read(waybillDraftProvider.notifier);
    setState(() => _busy = true);
    final saved = entry == null
        ? await notifier.createDraft()
        : await notifier.openDraft(entry.id);
    if (!mounted || scope != ref.read(waybillDraftScopeProvider)) return;
    setState(() => _busy = false);
    if (saved) {
      context.push('/waybill/new');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(waybillDraftProvider).error ?? '草稿暂时无法打开，请重试'),
        ),
      );
    }
  }

  Future<void> _delete(WaybillDraftEntry entry) async {
    if (_busy) return;
    final scope = ref.read(waybillDraftScopeProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除草稿'),
        content: Text('删除“${entry.title}”？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (!mounted ||
        confirmed != true ||
        scope != ref.read(waybillDraftScopeProvider)) {
      return;
    }
    setState(() => _busy = true);
    final saved = await ref
        .read(waybillDraftProvider.notifier)
        .deleteDraft(entry.id);
    if (!mounted || scope != ref.read(waybillDraftScopeProvider)) return;
    setState(() => _busy = false);
    if (!saved) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('草稿删除未保存，请重试')));
    }
  }

  String _time(int value) {
    final date = DateTime.fromMillisecondsSinceEpoch(value).toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)} ${two(date.hour)}:${two(date.minute)}';
  }

  String _route(WaybillDraftEntry entry) {
    String endpoint(String prefix, String fallback) {
      final place = entry.draft.value('$prefix.place').trim();
      if (place.isNotEmpty) return place;
      final site = entry.draft.value('$prefix.site').trim();
      return site.isEmpty ? fallback : site;
    }

    return "${endpoint('start', '待选起点')} → ${endpoint('end', '待选终点')}";
  }

  List<String> _missingSections(WaybillDraftEntry entry) {
    final sections = ['货物信息', '起点信息', '终点信息', '出发时间'];
    return [
      for (var i = 0; i < sections.length; i++)
        if (entry.draft.errorsFor(i).isNotEmpty) sections[i],
    ];
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(waybillDraftScopeProvider, (previous, next) {
      if (previous != next && _busy) setState(() => _busy = false);
    });
    final state = ref.watch(waybillDraftProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('草稿箱'),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _busy ? null : () => _open(),
            child: const Text('新建运单'),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              '草稿保存在本机，创建订单时自动继续最近编辑的一份。',
              style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
            ),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(state.error!),
            ),
          Expanded(
            child: state.entries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.drafts_outlined,
                          size: 52,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(height: 12),
                        const Text('暂无草稿'),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _busy ? null : () => _open(),
                          child: const Text('新建运单'),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.entries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final entry = state.entries[index];
                      final missing = _missingSections(entry);
                      return Material(
                        key: ValueKey('draft-${entry.id}'),
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.fromLTRB(
                            16,
                            8,
                            8,
                            8,
                          ),
                          leading: const Icon(
                            Icons.description_outlined,
                            color: Color(0xFF1D6FE9),
                          ),
                          title: Row(
                            spacing: 8,
                            children: [
                              Expanded(
                                child: Text(
                                  _route(entry),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                missing.isEmpty
                                    ? '已填齐'
                                    : '待补充 ${missing.length} 组',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                          subtitle: Text(
                            [...missing, _time(entry.updatedAt)].join(' · '),
                          ),
                          onTap: _busy ? null : () => _open(entry),
                          trailing: IconButton(
                            tooltip: '删除草稿',
                            onPressed: _busy ? null : () => _delete(entry),
                            icon: const Icon(Icons.delete_outline, size: 20),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
