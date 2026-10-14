// 附件 API 契约测试（t44：t43 presigned PUT 直传 MinIO）。

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/attachment_api.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/services/token_storage.dart';

import '../test_support.dart';

void main() {
  AttachmentApi buildApi(HttpClient client) => AttachmentApi(client);

  Future<HttpClient> clientWith(
    Map<String, Object> prefsValues,
    StubAdapter adapter,
  ) async {
    SharedPreferences.setMockInitialValues(prefsValues);
    final prefs = await SharedPreferences.getInstance();
    return HttpClient(TokenStorage(prefs), adapter: adapter);
  }

  group('列表接口 GET /tasks/{taskNum}/attachments', () {
    test('解析附件列表（objectKey/fileName/downloadUrl）', () async {
      final client = await clientWith(
        {
          'jwt_token': makeJwt(userId: 7),
          'server_url': 'http://stub.local:8081',
        },
        StubAdapter((options) async {
          expect(options.uri.path, '/tasks/T1/attachments');
          return jsonResponse(200, {
            'success': true,
            'code': 200,
            'data': [
              {
                'objectKey': 'tasks/T1/a1.jpg',
                'fileName': '成片1.jpg',
                'contentType': 'image/jpeg',
                'sizeBytes': 204800,
                'uploadStatus': 'UPLOADED',
                'downloadUrl': 'https://minio.local/presigned-get-1',
              },
              {
                'objectKey': 'tasks/T1/a2.mp4',
                'fileName': '剪辑.mp4',
                'contentType': 'video/mp4',
                'sizeBytes': 104857600,
                'uploadStatus': 'UPLOADED',
                'downloadUrl': 'https://minio.local/presigned-get-2',
              },
            ],
          });
        }),
      );

      final result = await buildApi(client).listAttachments('T1');

      expect(result.success, true);
      expect(result.data, hasLength(2));
      expect(result.data![0].objectKey, 'tasks/T1/a1.jpg');
      expect(result.data![0].isImage, true);
      expect(result.data![0].sizeLabel, '200 KB');
      expect(result.data![1].isImage, false);
      expect(
        result.data![1].downloadUrl,
        'https://minio.local/presigned-get-2',
      );
    });

    test('失败响应透传 message（如无权查看）', () async {
      final client = await clientWith(
        {
          'jwt_token': makeJwt(userId: 7),
          'server_url': 'http://stub.local:8081',
        },
        StubAdapter((options) async {
          return jsonResponse(403, {'success': false, 'message': '无权查看该任务交付物'});
        }),
      );

      final result = await buildApi(client).listAttachments('T1');

      expect(result.success, false);
      expect(result.message, '无权查看该任务交付物');
    });
  });

  group('upload-url 与直传（t43 presigned PUT）', () {
    test('请求预签名凭证并解析（fileName/contentType/sizeBytes 参数）', () async {
      final adapter = StubAdapter((options) async {
        expect(options.uri.path, '/tasks/T1/attachments/upload-url');
        expect(options.uri.queryParameters['fileName'], '成片.mp4');
        expect(options.uri.queryParameters['contentType'], 'video/mp4');
        expect(options.uri.queryParameters['sizeBytes'], '104857600');
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': {
            'objectKey': 'tasks/T1/uuid-1',
            'uploadUrl': 'https://minio.local/presigned-put',
            'method': 'PUT',
            'expireSeconds': 900,
          },
        });
      });
      final client = await clientWith({
        'jwt_token': makeJwt(userId: 8, role: 1),
        'server_url': 'http://stub.local:8081',
      }, adapter);

      final result = await buildApi(client).requestUploadUrl(
        taskNum: 'T1',
        fileName: '成片.mp4',
        contentType: 'video/mp4',
        sizeBytes: 104857600,
      );

      expect(result.success, true);
      expect(result.data!.uploadUrl, 'https://minio.local/presigned-put');
      expect(result.data!.expireSeconds, 900);
    });

    test('直传 MinIO：PUT 至绝对地址', () async {
      final adapter = StubAdapter((options) async {
        expect(options.method, 'PUT');
        expect(options.uri.host, 'minio.local');
        expect(options.headers.containsKey('Authorization'), false);
        expect(options.headers['Content-Type'], 'image/png');
        return Future.value(
          ResponseBody.fromBytes(
            const [],
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          ),
        );
      });
      final client = await clientWith({
        'jwt_token': makeJwt(userId: 8, role: 1),
        'server_url': 'http://stub.local:8081',
      }, adapter);

      await buildApi(client).uploadToStorage(
        uploadUrl: 'https://minio.local/bucket/key?sig=1',
        bytes: Uint8List.fromList([1, 2, 3]),
        contentType: 'image/png',
      );
      // 无异常即成功
    });
  });

  test('待上传、状态缺失和零字节附件不能计入凭证', () async {
    final client = await clientWith(
      {},
      StubAdapter((options) async {
        return jsonResponse(200, {
          'success': true,
          'data': [
            {
              'objectKey': 'pending',
              'uploadStatus': 'PENDING',
              'sizeBytes': 3,
              'downloadUrl': 'https://s/p',
            },
            {
              'objectKey': 'legacy',
              'sizeBytes': 3,
              'downloadUrl': 'https://s/l',
            },
            {
              'objectKey': 'empty',
              'uploadStatus': 'UPLOADED',
              'sizeBytes': 0,
              'downloadUrl': 'https://s/e',
            },
            {
              'objectKey': 'valid',
              'uploadStatus': 'UPLOADED',
              'sizeBytes': 3,
              'downloadUrl': 'https://s/v',
            },
          ],
        });
      }),
    );
    final result = await buildApi(client).listAttachments('T1');
    expect(result.data!.map((a) => a.objectKey), ['valid']);
  });

  test('PUT 后确认失败不得视为上传成功', () async {
    final client = await clientWith(
      {},
      StubAdapter((options) async {
        return jsonResponse(200, {'success': false, 'message': '对象不存在'});
      }),
    );
    await expectLater(
      buildApi(client).confirmUpload('T1', 'key'),
      throwsStateError,
    );
  });

  test('确认结果必须属于当前对象', () async {
    final client = await clientWith(
      {},
      StubAdapter((options) async {
        return jsonResponse(200, {
          'success': true,
          'data': {'objectKey': 'another-key', 'uploadStatus': 'UPLOADED'},
        });
      }),
    );
    await expectLater(
      buildApi(client).confirmUpload('T1', 'key'),
      throwsStateError,
    );
  });

  group('上传限制校验（t43 类型/大小）', () {
    test('允许的类型与大小返回 null', () {
      expect(
        AttachmentUploadRules.validate(
          contentType: 'image/jpeg',
          sizeBytes: 20 * 1024 * 1024,
        ),
        isNull,
      );
      expect(
        AttachmentUploadRules.validate(
          contentType: 'video/quicktime',
          sizeBytes: 500 * 1024 * 1024,
        ),
        isNull,
      );
    });

    test('不支持类型给出明确文案', () {
      final message = AttachmentUploadRules.validate(
        contentType: 'application/pdf',
        sizeBytes: 1024,
      );
      expect(message, contains('仅支持'));
    });

    test('图片超 20MB / 视频超 500MB 给出超限文案', () {
      expect(
        AttachmentUploadRules.validate(
          contentType: 'image/png',
          sizeBytes: 21 * 1024 * 1024,
        ),
        contains('图片超过大小限制'),
      );
      expect(
        AttachmentUploadRules.validate(
          contentType: 'video/mp4',
          sizeBytes: 501 * 1024 * 1024,
        ),
        contains('视频超过大小限制'),
      );
    });
  });
}
