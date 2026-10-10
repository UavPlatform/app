// 飞手资料（GET/PATCH /rider/info）：查看脱敏实名信息与驾驶资质；编辑只提交改动字段，
// 资质整组提交（新增机型 + 修改等级）。

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/pages/pilot/pilot_info_page.dart';
import 'package:uav_pilot_app/providers/auth_provider.dart';
import 'package:uav_pilot_app/services/token_storage.dart';
import '../../test_support.dart';

Map<String, dynamic> info({List<Map<String, dynamic>>? quals, String location = '浙江湖州'}) => {
      'userId': 5,
      'userName': 'pilot_liming',
      'age': 34,
      'idNumberMasked': '330***********1234',
      'idExpiryDate': '2036-05-01',
      'idExpired': false,
      'location': location,
      'selfIntroduction': '6 年山区吊运经验',
      'qualifications': quals ??
          [
            {
              'id': 2,
              'aircraftModelId': 1,
              'modelCode': 'FC30',
              'modelName': 'DJI FlyCart 30',
              'licenseGrade': 'BVLOS',
              'licenseGradeLabel': '超视距',
            },
          ],
    };

void main() {
  testWidgets('查看资料 → 编辑所在地、添加 M350 资质 → 只提交改动字段并刷新', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Map<String, dynamic>? patched;
    final adapter = StubAdapter((options) async {
      final path = options.uri.path;
      if (path == '/rider/info' && options.method == 'PATCH') {
        patched = (options.data is String
            ? jsonDecode(options.data as String)
            : options.data) as Map<String, dynamic>;
        return jsonResponse(200, {'success': true, 'code': 200, 'data': info(location: '浙江杭州')});
      }
      if (path == '/rider/info') {
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': patched == null
              ? info()
              : info(location: '浙江杭州', quals: [
                  ...info()['qualifications'] as List<Map<String, dynamic>>,
                  {
                    'id': 3,
                    'aircraftModelId': 2,
                    'modelCode': 'M350RTK',
                    'modelName': 'DJI Matrice 350 RTK',
                    'licenseGrade': 'VLOS',
                    'licenseGradeLabel': '视距内',
                  },
                ]),
        });
      }
      if (path == '/api/aircraft-models') {
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': [
            {'id': 1, 'displayName': 'DJI FlyCart 30', 'modelCode': 'FC30', 'maxPayloadKg': 30},
            {'id': 2, 'displayName': 'DJI Matrice 350 RTK', 'modelCode': 'M350RTK', 'maxPayloadKg': 2.7},
          ],
        });
      }
      return jsonResponse(200, {'success': false, 'message': 'unexpected $path'});
    });

    SharedPreferences.setMockInitialValues({
      'jwt_token': makeJwt(userId: 5),
      'server_url': 'http://stub.local:8081',
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        httpClientProvider.overrideWithValue(HttpClient(TokenStorage(prefs), adapter: adapter)),
      ],
      child: const MaterialApp(home: PilotInfoPage()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('330***********1234'), findsOneWidget, reason: '身份证号只展示脱敏值');
    expect(find.text('DJI FlyCart 30'), findsOneWidget);
    expect(find.text('超视距'), findsOneWidget);
    expect(find.text('浙江湖州'), findsOneWidget);

    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, '所在地'), '浙江杭州');
    await tester.tap(find.text('添加'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DJI Matrice 350 RTK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(patched, isNotNull);
    expect(patched!['location'], '浙江杭州');
    expect(patched!.containsKey('idNumber'), isFalse, reason: '未改身份证号不提交');
    expect(patched!.containsKey('age'), isFalse, reason: '未改年龄不提交');
    expect(patched!['qualifications'], [
      {'aircraftModelId': 1, 'licenseGrade': 'BVLOS'},
      {'aircraftModelId': 2, 'licenseGrade': 'VLOS'},
    ]);

    // 返回资料页并刷新
    expect(find.text('浙江杭州'), findsOneWidget);
    expect(find.text('DJI Matrice 350 RTK'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });
}
