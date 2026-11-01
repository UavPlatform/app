import '../../utils/failure_message.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../models/waybill_draft.dart';
import '../../providers/waybill_draft_provider.dart';

class PhotoFields extends ConsumerStatefulWidget {
  const PhotoFields({super.key, required this.draft, required this.group});
  final WaybillDraft draft;
  final String group;

  @override
  ConsumerState<PhotoFields> createState() => _PhotoFieldsState();
}

class _PhotoFieldsState extends ConsumerState<PhotoFields> {
  bool _picking = false;

  Future<void> _pick(ImageSource source) async {
    final scope = ref.read(waybillDraftScopeProvider);
    if (scope == null) return;
    final notifier = ref.read(waybillDraftProvider.notifier);
    setState(() => _picking = true);
    try {
      final path = await ref
          .read(waybillPhotoStoreProvider)
          .pick(source, scope);
      if (!mounted ||
          path == null ||
          ref.read(waybillDraftScopeProvider) != scope) {
        return;
      }
      // Use an immutable key per photo so removals do not renumber the draft.
      notifier.update('${widget.group}.photo.${const Uuid().v4()}', path);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failureMessage(error, fallback: '照片未能保存，请检查可用空间后重试')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.draft.fields.entries.where(
      (entry) =>
          entry.key.startsWith('${widget.group}.photo.') &&
          entry.value.isNotEmpty,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('照片（选填）'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final photo in photos)
              SizedBox(
                width: 112,
                child: Column(
                  children: [
                    Image.file(
                      File(photo.value),
                      width: 112,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox(
                        height: 90,
                        child: Center(child: Text('照片不可用，请重选')),
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref
                          .read(waybillDraftProvider.notifier)
                          .update(photo.key, ''),
                      child: const Text('移除'),
                    ),
                  ],
                ),
              ),
          ],
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: _picking ? null : () => _pick(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('拍照'),
            ),
            OutlinedButton.icon(
              onPressed: _picking ? null : () => _pick(ImageSource.gallery),
              icon: const Icon(Icons.photo_outlined),
              label: Text(_picking ? '保存中…' : '选择照片'),
            ),
          ],
        ),
      ],
    );
  }
}
