import '../../utils/failure_message.dart';
import '../../widgets/flow_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/dispatch_material_provider.dart';
import '../../providers/waybill_draft_provider.dart';

class DispatchMaterialPanel extends ConsumerStatefulWidget {
  const DispatchMaterialPanel({
    super.key,
    required this.orderId,
    this.purpose,
    this.onSelected,
    this.expanded = false,
    this.initialSelected = const [],
  });
  final String orderId;
  final bool expanded;
  final List<String> initialSelected;
  final String? purpose;
  final ValueChanged<List<String>>? onSelected;
  @override
  ConsumerState<DispatchMaterialPanel> createState() =>
      _DispatchMaterialPanelState();
}

class _DispatchMaterialPanelState extends ConsumerState<DispatchMaterialPanel> {
  bool _busy = false;
  String? _error;
  final Set<String> _selected = {};
  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.initialSelected);
  }

  Future<void> _upload(int source) async {
    if (_busy || widget.purpose == null) return;
    final scope = ref.read(waybillDraftScopeProvider);
    bool current() => mounted && scope == ref.read(waybillDraftScopeProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final picker = ref.read(dispatchMaterialSourceProvider);
      final file = await (source == 0
          ? picker.pickFromCamera()
          : source == 1
          ? picker.pickFromGallery()
          : picker.pickGalleryVideo());
      if (!current() || file == null) return;
      await ref
          .read(dispatchMaterialApiProvider)
          .upload(widget.orderId, widget.purpose!, file);
      if (current()) ref.invalidate(dispatchMaterialsProvider(widget.orderId));
    } catch (error) {
      if (current()) {
        setState(
          () => _error = failureMessage(error, fallback: '材料上传未完成，请检查文件后重试'),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(String url) async {
    try {
      final ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!ok && mounted) setState(() => _error = '无法打开凭证，请重试');
    } catch (_) {
      if (mounted) setState(() => _error = '无法打开凭证，请重试');
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          const Text('现场材料与交付凭证'),
          if (widget.onSelected != null) const Text('选择本次使用的凭证'),
          ref
              .watch(dispatchMaterialsProvider(widget.orderId))
              .when(
                loading: () => const LinearProgressIndicator(),
                error: (error, stack) => TextButton(
                  onPressed: () =>
                      ref.invalidate(dispatchMaterialsProvider(widget.orderId)),
                  child: Text('$error\n重试读取凭证'),
                ),
                data: (files) => Column(
                  spacing: 10,
                  children: [
                    if (files.isEmpty) const Text('暂无已核验材料'),
                    for (final file in widget.expanded ? files : files.take(3))
                      ListTile(
                        leading:
                            widget.onSelected != null &&
                                file.data.purpose == widget.purpose
                            ? Checkbox(
                                value: _selected.contains(file.id),
                                onChanged: _busy
                                    ? null
                                    : (value) {
                                        setState(() {
                                          if (value == true) {
                                            _selected.add(file.id);
                                          } else {
                                            _selected.remove(file.id);
                                          }
                                        });
                                        widget.onSelected!(_selected.toList());
                                      },
                              )
                            : const Icon(Icons.verified_outlined),
                        title: Text(
                          file.data.fileName ?? '凭证',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          const {
                                'CARGO': '货物',
                                'START_SITE': '起点',
                                'END_SITE': '终点',
                                'PILOT_DELIVERY': '飞手送达凭证',
                                'SHIPPER_RECEIPT': '收货凭证',
                              }[file.data.purpose] ??
                              '材料',
                        ),
                        trailing: IconButton(
                          tooltip: '查看凭证',
                          icon: const Icon(Icons.open_in_new),
                          onPressed: () => _open(file.data.downloadUrl!),
                        ),
                      ),
                    if (!widget.expanded && files.length > 3)
                      FlowDetailsLink(
                        title: '查看全部材料',
                        summary:
                            '共 ${files.length} 份 · 已选择 ${_selected.length} 份',
                        icon: Icons.folder_open_outlined,
                        builder: (_) {
                          final scope = ref.read(waybillDraftScopeProvider);
                          return FlowDetailPage(
                            title: '现场材料与交付凭证',
                            scope: scope,
                            builder: (_) => FlowList(
                              children: [
                                DispatchMaterialPanel(
                                  orderId: widget.orderId,
                                  purpose: widget.purpose,
                                  expanded: true,
                                  initialSelected: _selected.toList(),
                                  onSelected: widget.onSelected == null
                                      ? null
                                      : (ids) {
                                          if (!mounted ||
                                              scope !=
                                                  ref.read(
                                                    waybillDraftScopeProvider,
                                                  )) {
                                            return;
                                          }
                                          setState(() {
                                            _selected
                                              ..clear()
                                              ..addAll(ids);
                                          });
                                          widget.onSelected!(ids);
                                        },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
          if (widget.purpose != null)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                TextButton(
                  onPressed: _busy ? null : () => _upload(0),
                  child: const Text('拍照上传'),
                ),
                TextButton(
                  onPressed: _busy ? null : () => _upload(1),
                  child: const Text('上传照片'),
                ),
                TextButton(
                  onPressed: _busy ? null : () => _upload(2),
                  child: const Text('上传视频'),
                ),
              ],
            ),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    ),
  );
}
