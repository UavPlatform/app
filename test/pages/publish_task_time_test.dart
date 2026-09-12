// 发布向导 taskTime 组装测试（t19：确认步展示与提交同源，t15 契约格式）。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uav_pilot_app/models/create_task_request.dart';
import 'package:uav_pilot_app/pages/publish/publish_page.dart';

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

  test('CreateTaskRequest 提交体携带相同 taskTime 字符串', () {
    final built = buildTaskTimeString(
      DateTime(2026, 9, 15),
      const TimeOfDay(hour: 14, minute: 30),
    );
    final request = CreateTaskRequest(
      taskName: '航拍摄影',
      type: 'AERIAL_PHOTO',
      description: '活动跟拍',
      waypoints: [
        WaypointRequest(orderIndex: 0, longitude: 112.9193, latitude: 27.8981),
      ],
      reward: 300,
      taskTime: built,
    );
    expect(request.toJson()['taskTime'], '2026-09-15 14:30:00');
  });
}
