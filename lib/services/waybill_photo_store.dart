import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'attachment_upload_rules.dart';
import 'attachment_file_source.dart';

// These are local draft photos, never verified delivery/receipt attachments.
class WaybillPhotoStore {
  WaybillPhotoStore({
    ImagePicker? picker,
    Future<Directory> Function()? supportDirectory,
  }) : _picker = picker ?? ImagePicker(),
       _supportDirectory = supportDirectory ?? getApplicationSupportDirectory;

  final ImagePicker _picker;
  final Future<Directory> Function() _supportDirectory;

  Future<String?> pick(ImageSource source, String scope) async {
    final file = await _picker.pickImage(source: source, imageQuality: 90);
    if (file == null) return null;
    final type = attachmentContentTypeFor(file.name);
    if (!type.startsWith('image/')) throw const FormatException('请选择图片');
    final violation = AttachmentUploadRules.validate(
      contentType: type,
      sizeBytes: await file.length(),
    );
    if (violation != null) throw FormatException(violation);
    final root = await _supportDirectory();
    final directory = Directory('${root.path}/waybill-drafts/$scope');
    await directory.create(recursive: true);
    final extension = type == 'image/png'
        ? 'png'
        : type == 'image/webp'
        ? 'webp'
        : 'jpg';
    final target = '${directory.path}/${const Uuid().v4()}.$extension';
    await File(file.path).copy(target);
    return target;
  }
}
