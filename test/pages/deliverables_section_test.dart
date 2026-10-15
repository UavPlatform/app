// 交付成果区块测试（t44：列表渲染/上传状态；t48：默认选择器弹窗与权限提示）。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:flutter/services.dart';
import 'package:uav_pilot_app/pages/orders/deliverables_section.dart';
import 'package:uav_pilot_app/services/attachment_file_source.dart';
import 'package:uav_pilot_app/providers/auth_provider.dart';
import 'package:uav_pilot_app/services/token_storage.dart';

import '../test_support.dart';

void main() {
  Future<List<Override>> buildOverrides({required StubAdapter adapter}) async {
    SharedPreferences.setMockInitialValues({
      'jwt_token': makeJwt(userId: 7),
      'server_url': 'http://stub.local:8081',
    });
    final prefs = await SharedPreferences.getInstance();
    return [
      sharedPreferencesProvider.overrideWithValue(prefs),
      httpClientProvider.overrideWithValue(
        HttpClient(TokenStorage(prefs), adapter: adapter),
      ),
    ];
  }

  StubAdapter emptyListAdapter() {
    return StubAdapter((options) async {
      if (options.uri.path == '/tasks/T20260912-001/attachments') {
        return jsonResponse(200, {'success': true, 'code': 200, 'data': []});
      }
      return jsonResponse(200, {'success': false, 'message': 'stub'});
    });
  }

  testWidgets('附件列表渲染：文件名/大小', (tester) async {
    final adapter = StubAdapter((options) async {
      if (options.uri.path == '/tasks/T20260912-001/attachments') {
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
              'downloadUrl': 'https://minio.local/get-1',
            },
            {
              'objectKey': 'tasks/T1/a2.mp4',
              'fileName': '剪辑.mp4',
              'contentType': 'video/mp4',
              'sizeBytes': 104857600,
              'uploadStatus': 'UPLOADED',
              'downloadUrl': 'https://minio.local/get-2',
            },
          ],
        });
      }
      return jsonResponse(200, {'success': false, 'message': 'stub'});
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(adapter: adapter),
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DeliverablesSection(taskNum: 'T20260912-001'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('成片1.jpg'), findsOneWidget);
    expect(find.text('剪辑.mp4'), findsOneWidget);
    expect(find.text('200 KB'), findsOneWidget);
    expect(find.text('100.0 MB'), findsOneWidget);
  });

  testWidgets('空态展示「暂无交付成果」与补充上传入口', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(adapter: emptyListAdapter()),
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DeliverablesSection(taskNum: 'T20260912-001'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('暂无交付成果'), findsOneWidget);
    expect(find.textContaining('补充上传'), findsOneWidget);
  });

  testWidgets('注入来源上传成功：PUT 后列表刷新并提示成功', (tester) async {
    var putCalled = false;
    var listCall = 0;
    List<Map<String, dynamic>> attachmentsFor(int call) {
      if (call == 1) return const [];
      return [
        {
          'objectKey': 'tasks/T1/new.png',
          'fileName': 'new.png',
          'contentType': 'image/png',
          'sizeBytes': 3,
          'uploadStatus': 'UPLOADED',
          'downloadUrl': 'https://minio.local/get-new',
        },
      ];
    }

    final adapter = StubAdapter((options) async {
      if (options.uri.path == '/tasks/T20260912-001/attachments') {
        listCall += 1;
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': attachmentsFor(listCall),
        });
      }
      if (options.uri.path == '/tasks/T20260912-001/attachments/upload-url') {
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': {
            'objectKey': 'tasks/T1/new.png',
            'uploadUrl': 'https://minio.local/put-new',
            'method': 'PUT',
            'expireSeconds': 900,
          },
        });
      }
      if (options.uri.path.endsWith('/confirm-upload')) {
        expect(putCalled, true);
        expect(options.headers['Authorization'], startsWith('Bearer '));
        return jsonResponse(200, {
          'success': true,
          'data': {'objectKey': 'tasks/T1/new.png', 'uploadStatus': 'UPLOADED'},
        });
      }
      if (options.uri.path == '/put-new') {
        expect(options.headers.containsKey('Authorization'), false);
        putCalled = true;
        return jsonResponse(200, {'success': true});
      }
      return jsonResponse(200, {'success': false, 'message': 'stub'});
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(adapter: adapter),
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DeliverablesSection(
                taskNum: 'T20260912-001',
                picker: () async => UploadCandidate(
                  fileName: 'new.png',
                  contentType: 'image/png',
                  bytes: Uint8List.fromList([1, 2, 3]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('暂无交付成果'), findsOneWidget);

    await tester.tap(find.textContaining('补充上传'));
    await tester.pumpAndSettle();

    expect(putCalled, true, reason: 'presigned PUT 直传发生');
    expect(find.text('上传成功'), findsOneWidget);
    expect(find.text('new.png'), findsOneWidget, reason: '列表刷新后可见新附件');
  });

  testWidgets('选择源抛异常（模拟权限拒绝）→ SnackBar 明确提示', (tester) async {
    final adapter = emptyListAdapter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(adapter: adapter),
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DeliverablesSection(
                taskNum: 'T20260912-001',
                picker: () async =>
                    throw PlatformException(code: 'photo_access_denied'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('补充上传'));
    await tester.pumpAndSettle();

    expect(
      find.text('未能获取文件，请检查相机/相册权限后重试'),
      findsOneWidget,
      reason: '选择源异常（权限拒绝）应有明确用户提示（t48 验收③）',
    );
  });

  group('默认选择器（t48 image_picker 接线）', () {
    testWidgets('补充上传弹出来源选择（拍照/相册图片/相册视频）', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: await buildOverrides(adapter: emptyListAdapter()),
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: DeliverablesSection(taskNum: 'T20260912-001'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('补充上传'));
      await tester.pumpAndSettle();

      expect(find.text('拍照上传'), findsOneWidget);
      expect(find.text('从相册选择图片'), findsOneWidget);
      expect(find.text('从相册选择视频'), findsOneWidget);
    });

    testWidgets('用户取消（点击遮罩关闭弹窗）→ 静默返回不报错', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: await buildOverrides(adapter: emptyListAdapter()),
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: DeliverablesSection(taskNum: 'T20260912-001'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('补充上传'));
      await tester.pumpAndSettle();
      expect(find.text('拍照上传'), findsOneWidget);

      // 点击遮罩（sheet 外）关闭 → 无候选、无提示
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(find.text('拍照上传'), findsNothing, reason: '弹窗已关闭');
      expect(find.text('未能获取文件，请检查相机/相册权限后重试'), findsNothing, reason: '取消不应报错');
    });
  });
}
