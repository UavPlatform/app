// 首页发单 taskTime 组装测试（t19：展示与提交同源，t15 契约格式）。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uav_pilot_app/api/generated/openapi_models.dart';
import 'package:uav_pilot_app/pages/home/home_page.dart';

void main() {
  group('buildTaskTimeString（t15 契约 "yyyy-MM-dd HH:mm:ss"）', () {
    test('日期时间各段补零，秒固定 :00', () {
      final result = buildTaskTimeString(
        DateTime(2026, 9, 15),
        const TimeOfDay(hour: 14, minute: 30),
      );
      expect(result, '2026-09-15 14:30:00');
    });

    test('单位数月/日/时补零', () {
      final result = buildTaskTimeString(
        DateTime(2026, 3, 5),
        const TimeOfDay(hour: 8, minute: 5),
      );
      expect(result, '2026-03-05 08:05:00');
    });

    test('日期或时间缺省返回 null（可选字段）', () {
      expect(buildTaskTimeString(null, const TimeOfDay(hour: 8, minute: 5)), isNull);
      expect(buildTaskTimeString(DateTime(2026, 9, 15), null), isNull);
    });
  });

  test('发单提交体（ApiTaskDto）携带相同 taskTime 字符串', () {
    final built = buildTaskTimeString(
      DateTime(2026, 9, 15),
      const TimeOfDay(hour: 14, minute: 30),
    );
    final request = ApiTaskDto(
      taskName: '建材吊运',
      type: kTransportTaskType,
      description: '山顶基站建材',
      waypoints: [
        ApiWaypointDto(orderIndex: 0, longitude: 112.9193, latitude: 27.8981),
      ],
      taskTime: built,
      cargoWeightKg: 12.5,
      cargoCategory: 'CONSTRUCTION',
    );
    expect(request.toJson()['taskTime'], '2026-09-15 14:30:00');
    expect(request.toJson()['type'], 'TRANSPORT');
    expect(request.toJson().containsKey('reward'), isFalse);
  });
}
