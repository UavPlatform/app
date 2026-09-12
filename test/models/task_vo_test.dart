// TaskVo 模型契约测试（t15 taskTime 字段对齐）。

import 'package:flutter_test/flutter_test.dart';
import 'package:uav_pilot_app/models/task_vo.dart';

void main() {
  Map<String, dynamic> baseJson({String? taskTime}) {
    return {
      'id': 1,
      'taskNum': 'T20260911-001',
      'taskName': '航拍任务',
      'userId': 7,
      'taskType': 'AERIAL_PHOTO',
      'taskStatus': 'IDLE',
      'taskTime': taskTime,
      'createTime': '2026-09-11T20:00:00',
      'updateTime': '2026-09-11T20:00:00',
    };
  }

  group('TaskVo.deviceId/liveState（t41 设备映射契约）', () {
    test('有值：解析设备与直播态', () {
      final vo = TaskVo.fromJson(baseJson(
        taskTime: '2026-09-15 14:30:00',
      )..addAll({
        'deviceId': 'UAV-001',
        'liveState': 'RUNNING',
      }));
      expect(vo.deviceId, 'UAV-001');
      expect(vo.liveState, 'RUNNING');
    });

    test('null 值容忍', () {
      final vo = TaskVo.fromJson(baseJson(
        taskTime: '2026-09-15 14:30:00',
      )..addAll({
        'deviceId': null,
        'liveState': null,
      }));
      expect(vo.deviceId, isNull);
      expect(vo.liveState, isNull);
    });

    test('字段缺失不崩（宽容解析）', () {
      final vo = TaskVo.fromJson(baseJson(taskTime: '2026-09-15 14:30:00'));
      expect(vo.deviceId, isNull);
      expect(vo.liveState, isNull);
    });
  });

  group('TaskVo.taskTime（t15 契约对齐）', () {
    test('解析后端返回的 taskTime（"yyyy-MM-dd HH:mm:ss"）', () {
      final vo = TaskVo.fromJson(baseJson(taskTime: '2026-09-15 14:30:00'));
      expect(vo.taskTime, '2026-09-15 14:30:00');
      expect(vo.formattedTaskTime, '2026-09-15 14:30');
    });

    test('taskTime 为 null 时容忍（可选字段）', () {
      final vo = TaskVo.fromJson(baseJson());
      expect(vo.taskTime, isNull);
      expect(vo.formattedTaskTime, '');
    });

    test('兼容 ISO "T" 分隔格式', () {
      final vo = TaskVo.fromJson(baseJson(taskTime: '2026-09-15T14:30:00'));
      expect(vo.formattedTaskTime, '2026-09-15 14:30');
    });

    test('短格式原样展示，不越界截断', () {
      final vo = TaskVo.fromJson(baseJson(taskTime: '2026-09-15 14:30'));
      expect(vo.formattedTaskTime, '2026-09-15 14:30');
    });

    test('既有字段解析不受新增字段影响', () {
      final vo = TaskVo.fromJson({
        ...baseJson(taskTime: '2026-09-15 14:30:00'),
        'totalAmount': 120,
        'riderName': '飞手甲',
      });
      expect(vo.taskName, '航拍任务');
      expect(vo.totalAmount, 120.0);
      expect(vo.riderName, '飞手甲');
      expect(vo.taskTypeName, '航拍');
      expect(vo.isIdle, true);
    });
  });
}
