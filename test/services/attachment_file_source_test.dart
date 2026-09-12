// 附件文件来源测试（t48：contentType 推导与候选构造）。

import 'package:flutter_test/flutter_test.dart';
import 'package:uav_pilot_app/services/attachment_file_source.dart';

void main() {
  group('attachmentContentTypeFor（t43 允许类型对齐）', () {
    test('图片扩展名映射', () {
      expect(attachmentContentTypeFor('a.jpg'), 'image/jpeg');
      expect(attachmentContentTypeFor('a.jpeg'), 'image/jpeg');
      expect(attachmentContentTypeFor('a.png'), 'image/png');
      expect(attachmentContentTypeFor('a.webp'), 'image/webp');
    });

    test('视频扩展名映射', () {
      expect(attachmentContentTypeFor('a.mp4'), 'video/mp4');
      expect(attachmentContentTypeFor('a.mov'), 'video/quicktime');
    });

    test('大小写不敏感', () {
      expect(attachmentContentTypeFor('A.JPG'), 'image/jpeg');
      expect(attachmentContentTypeFor('B.Mp4'), 'video/mp4');
    });

    test('未知扩展名回退二进制流（由规则校验拒绝）', () {
      expect(attachmentContentTypeFor('a.pdf'), 'application/octet-stream');
      expect(attachmentContentTypeFor('noext'), 'application/octet-stream');
    });
  });
}
