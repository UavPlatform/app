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
  Widget build(BuildContext context) {
    final materials = ref.watch(dispatchMaterialsProvider(widget.orderId));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Row(
              spacing: 8,
              children: [
                const Expanded(
                  child: Text(
                    '现场材料与交付凭证',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2329),
                    ),
                  ),
                ),
                if (materials.asData?.value.isEmpty == true)
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        '暂无已核验材料',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            materials.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, stack) => TextButton(
                onPressed: () =>
                    ref.invalidate(dispatchMaterialsProvider(widget.orderId)),
                child: Text('$error\n重试读取凭证'),
              ),
              data: (files) => Column(
                spacing: 10,
                children: [
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
              Row(
                spacing: 10,
                children: [
                  _uploadTile(
                    Icons.camera_alt_outlined,
                    '拍照上传',
                    _busy ? null : () => _upload(0),
                  ),
                  _uploadTile(
                    Icons.photo_library_outlined,
                    '上传照片',
                    _busy ? null : () => _upload(1),
                  ),
                  _uploadTile(
                    Icons.videocam_outlined,
                    '上传视频',
                    _busy ? null : () => _upload(2),
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
}

Widget _uploadTile(IconData icon, String label, VoidCallback? onPressed) =>
    Expanded(
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 64),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          foregroundColor: const Color(0xFF333333),
          backgroundColor: const Color(0xFFF7F8FA),
          disabledBackgroundColor: const Color(0xFFF7F8FA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Icon(
              icon,
              size: 22,
              color: onPressed == null
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF1D6FE9),
            ),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
