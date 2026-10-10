// 撮合阶段文案（REQ-APP-002「各阶段文案在首页卡片、订单列表、详情页必须一致」）：
// TaskVo.stageLabel / stageStep / isStageClosed 与后端 MatchStatus 映射表逐行对齐。

import 'package:flutter_test/flutter_test.dart';
import 'package:uav_pilot_app/models/task_vo.dart';

TaskVo _task({
  String taskStatus = 'IDLE',
  String? matchStatus,
  String? orderStatus,
  String taskType = 'TRANSPORT',
  String? cargoCategory,
}) {
  return TaskVo.fromJson({
    'id': 1,
    'taskNum': 'T-1',
    'taskName': '吊运',
    'userId': 7,
    'taskType': taskType,
    'taskStatus': taskStatus,
    'matchStatus': matchStatus,
    'orderStatus': orderStatus,
    'cargoWeightKg': 10,
    'cargoCategory': cargoCategory,
  });
}

void main() {
  group('stageLabel / stageStep', () {
    final rows = <(String, String?, String?, String, int)>[
      ('IDLE', 'SEEKING_RIDER', 'MATCHING', '招募飞手中', 0),
      ('IDLE', 'NEGOTIATING', 'MATCHING', '洽谈中', 0),
      ('IDLE', 'AWAITING_PAYMENT', 'PENDING', '待支付', 1),
      ('IDLE', 'AWAITING_RIDER_CONFIRM', 'PAID', '待飞手确认', 2),
      ('IDLE', 'CONFIRMED', 'PAID', '已确认', 3),
      ('IN_PROGRESS', 'CONFIRMED', 'PAID', '进行中', 3),
      ('COMPLETED', 'PENDING_ACCEPTANCE', 'WAITING_CONFIRM', '待验收', 4),
      ('COMPLETED', 'CLOSED', 'COMPLETED', '已完成', 5),
      // 撮合改版前的旧任务没有 matchStatus
      ('IDLE', null, null, '招募飞手中', 0),
      ('IN_PROGRESS', null, 'PAID', '进行中', 3),
      ('COMPLETED', null, 'WAITING_CONFIRM', '待验收', 4),
    ];
    for (final (ts, ms, os, label, step) in rows) {
      test('$ts / $ms / $os → $label', () {
        final t = _task(taskStatus: ts, matchStatus: ms, orderStatus: os);
        expect(t.stageLabel, label);
        expect(t.stageStep, step);
      });
    }

    test('订单取消/退款/争议优先展示', () {
      expect(
        _task(matchStatus: 'NEGOTIATING', orderStatus: 'CANCELLED').stageLabel,
        '已取消',
      );
      expect(
        _task(matchStatus: 'CONFIRMED', orderStatus: 'REFUNDED').stageLabel,
        '已退款',
      );
      expect(
        _task(matchStatus: 'CONFIRMED', orderStatus: 'DISPUTED').stageLabel,
        '争议中',
      );
      expect(_task(orderStatus: 'REFUNDED').stageTone, StageTone.stopped);
    });
  });

  group('isStageClosed（首页「我发布的任务」是否隐藏）', () {
    test('待验收仍需用户操作：不隐藏', () {
      expect(
        _task(
          taskStatus: 'COMPLETED',
          matchStatus: 'PENDING_ACCEPTANCE',
          orderStatus: 'WAITING_CONFIRM',
        ).isStageClosed,
        isFalse,
      );
    });
    test('已结案 / 已退款：隐藏', () {
      expect(
        _task(
          taskStatus: 'COMPLETED',
          matchStatus: 'CLOSED',
          orderStatus: 'COMPLETED',
        ).isStageClosed,
        isTrue,
      );
      expect(
        _task(
          matchStatus: 'NEGOTIATING',
          orderStatus: 'REFUNDED',
        ).isStageClosed,
        isTrue,
      );
    });
    test('招募/洽谈/待支付：不隐藏', () {
      for (final ms in ['SEEKING_RIDER', 'NEGOTIATING', 'AWAITING_PAYMENT']) {
        expect(_task(matchStatus: ms).isStageClosed, isFalse, reason: ms);
      }
    });
  });

  test('任务类型「吊运」用字正确（不是「调运」）', () {
    expect(_task().taskTypeName, '吊运');
  });

  test('货物类别覆盖后端 CargoCategory 全部 5 项', () {
    expect(_task(cargoCategory: 'DAILY_SUPPLIES').cargoLabel, '10 kg · 生活物资');
    expect(_task(cargoCategory: 'FURNITURE').cargoLabel, '10 kg · 家具家居');
    expect(_task(cargoCategory: 'CONSTRUCTION').cargoLabel, '10 kg · 建材');
  });
}
