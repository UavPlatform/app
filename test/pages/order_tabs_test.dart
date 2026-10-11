// 订单分栏归属（REQ-APP-002）：枚举 App 可能产生的每一个阶段标签（TaskVo.stageLabel 的全部
// matchStatus × orderStatus × taskStatus 组合 + OrderStatusCode.labelOf 的全部订单码与未知码），
// 断言每张卡片除「全部」外恰好落在一个预期分栏。
//
// 预期表是显式写死的：若有人改了阶段名（例如「进行中」→「执行中」），新名字不在预期表里，
// 测试直接失败，而不会让卡片悄悄掉进兜底栏「售后/其他」。

import 'package:flutter_test/flutter_test.dart';
import 'package:uav_pilot_app/api/order_api.dart';
import 'package:uav_pilot_app/models/task_vo.dart';
import 'package:uav_pilot_app/pages/orders/order_tabs.dart';

/// 阶段名 → 预期分栏（不含「全部」）。
const _expectedTab = <String, String>{
  '招募飞手中': '招募飞手中',
  '洽谈中': '洽谈中',
  '待支付': '待支付',
  '待飞手确认': '待飞手确认',
  '进行中': '进行中',
  '待验收': '待验收',
  '已完成': '已完成',
  '已取消': orderFallbackTab,
  '已退款': orderFallbackTab,
  '争议中': orderFallbackTab,
  '未知状态': orderFallbackTab,
};

TaskVo _task(String taskStatus, String? matchStatus, String? orderStatus) =>
    TaskVo.fromJson({
      'id': 1,
      'taskNum': 'T-1',
      'taskName': '吊运',
      'userId': 7,
      'taskType': 'TRANSPORT',
      'taskStatus': taskStatus,
      'matchStatus': matchStatus,
      'orderStatus': orderStatus,
    });

void main() {
  const taskStatuses = ['IDLE', 'IN_PROGRESS', 'COMPLETED'];
  const matchStatuses = <String?>[
    null,
    'SEEKING_RIDER',
    'NEGOTIATING',
    'AWAITING_PAYMENT',
    'AWAITING_RIDER_CONFIRM',
    'CONFIRMED',
    'PENDING_ACCEPTANCE',
    'CLOSED',
  ];
  const orderStatuses = <String?>[
    null,
    'MATCHING',
    'PENDING',
    'PAID',
    'WAITING_CONFIRM',
    'COMPLETED',
    'CANCELLED',
    'REFUNDED',
    'DISPUTED',
  ];
  const orderCodes = [
    OrderStatusCode.pending,
    OrderStatusCode.paid,
    OrderStatusCode.cancelled,
    OrderStatusCode.refunded,
    OrderStatusCode.completed,
    OrderStatusCode.waitingConfirm,
    OrderStatusCode.disputed,
    OrderStatusCode.matching,
    99, // 未知订单码
  ];

  // 收集 App 实际会产生的全部阶段标签及其来源
  final sources = <String, List<String>>{};
  for (final ts in taskStatuses) {
    for (final ms in matchStatuses) {
      for (final os in orderStatuses) {
        final label = _task(ts, ms, os).stageLabel;
        sources.putIfAbsent(label, () => []).add('task $ts/$ms/$os');
      }
    }
  }
  for (final code in orderCodes) {
    sources
        .putIfAbsent(OrderStatusCode.labelOf(code), () => [])
        .add('orderCode $code');
  }

  test('枚举出的每个阶段标签都在预期表中（改名必须同步更新分栏与本表）', () {
    final unknown = sources.keys.where((l) => !_expectedTab.containsKey(l));
    expect(
      unknown,
      isEmpty,
      reason: '出现未登记的阶段标签：${unknown.map((l) => '$l ← ${sources[l]!.first}')}',
    );
  });

  test('预期表里的每个阶段都确实会由 App 产生（防止表里留下死条目）', () {
    final unused = _expectedTab.keys.where((l) => !sources.containsKey(l));
    expect(unused, isEmpty);
  });

  for (final label in _expectedTab.keys) {
    test('「$label」除「全部」外恰好落在「${_expectedTab[label]}」', () {
      expect(orderTabsFor(label), [_expectedTab[label]]);
    });
  }

  test('除兜底栏外，每个具体分栏都接收同名阶段', () {
    for (final (name, labels) in orderTabs) {
      if (labels == null || name == orderFallbackTab) continue;
      expect(labels, contains(name), reason: '分栏「$name」应接收同名阶段');
      expect(_expectedTab.values, contains(name));
    }
  });
}
