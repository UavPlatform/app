import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uav_pilot_app/services/waybill_photo_store.dart';

class SelectedImage extends ImagePicker {
  SelectedImage(this.file);
  final XFile? file;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async => file;
}

void main() {
  late Directory temporary;
  setUp(
    () async =>
        temporary = await Directory.systemTemp.createTemp('waybill-test-'),
  );
  tearDown(() async => temporary.delete(recursive: true));

  test('draft photo survives deletion of the picker temporary file', () async {
    final selected = File('${temporary.path}/source.jpg');
    await selected.writeAsBytes([0xff, 0xd8, 0xff, 0xd9]);
    final store = WaybillPhotoStore(
      picker: SelectedImage(XFile(selected.path)),
      supportDirectory: () async => Directory('${temporary.path}/support'),
    );
    final saved = await store.pick(ImageSource.gallery, 'account-a');
    await selected.delete();
    expect(await File(saved!).readAsBytes(), [0xff, 0xd8, 0xff, 0xd9]);
    expect(saved, contains('waybill-drafts/account-a'));
    expect(saved, isNot(contains('account-b')));
  });

  test('canceling photo selection creates no draft file', () async {
    final store = WaybillPhotoStore(
      picker: SelectedImage(null),
      supportDirectory: () async => temporary,
    );
    expect(await store.pick(ImageSource.camera, 'account-a'), isNull);
    expect(await temporary.list().toList(), isEmpty);
  });

  test(
    'unsupported photo type is rejected before copying into draft storage',
    () async {
      final source = File('${temporary.path}/image.gif')
        ..writeAsBytesSync([1, 2, 3]);
      final support = Directory('${temporary.path}/support');
      final store = WaybillPhotoStore(
        picker: SelectedImage(XFile(source.path)),
        supportDirectory: () async => support,
      );
      await expectLater(
        store.pick(ImageSource.gallery, 'account-a'),
        throwsFormatException,
      );
      expect(await support.exists(), isFalse);
    },
  );
}
