import 'dart:io';
import '../api/dispatch_material_api.dart';
import '../models/waybill_draft.dart';
import 'attachment_file_source.dart';

// Local upload receipts belong to one order and immutable draft photo key.
Future<void> uploadDispatchDraftMaterials({
  required WaybillDraft draft,
  required String orderId,
  required DispatchMaterialApi api,
  required bool Function() current,
  required String Function(String) saved,
  required Future<void> Function(String, String) persist,
}) async {
  for (final entry in draft.fields.entries) {
    final group = entry.key.split('.photo.');
    if (group.length != 2 || entry.value.isEmpty) continue;
    final purpose = const {
      'cargo': 'CARGO',
      'start': 'START_SITE',
      'end': 'END_SITE',
    }[group.first];
    if (purpose == null) continue;
    final marker = 'submission.material.$orderId.${entry.key}';
    if (!current()) return;
    if (saved(marker).isNotEmpty) continue;
    final file = File(entry.value);
    if (!await file.exists()) throw StateError('草稿照片已丢失，请移除后重新选择照片');
    if (!current()) return;
    final name = file.uri.pathSegments.last;
    final candidate = UploadCandidate(
      fileName: name,
      contentType: attachmentContentTypeFor(name),
      bytes: await file.readAsBytes(),
    );
    if (!current()) return;
    final material = await api.upload(orderId, purpose, candidate);
    if (!current()) return;
    await persist(marker, material.id);
  }
}
