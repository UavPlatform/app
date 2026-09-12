// 系统消息卡片渲染测试（t33：按 t23 载荷契约渲染，样式区别于普通消息）。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uav_pilot_app/models/message_vo.dart';
import 'package:uav_pilot_app/widgets/system_message_card.dart';

void main() {
  MessageVo systemMessage({
    required String name,
    String text = '您的任务有新的状态变更',
    int msgType = 2,
    int fromUserId = 0,
    int timestamp = 1789000100000,
  }) {
    return MessageVo.fromJson({
      'msgId': 'sys-1',
      'sessionId': 99,
      'msgType': msgType,
      'fromUserId': fromUserId,
      'toUserId': 7,
      'timestamp': timestamp,
      'isOffline': false,
      'payload': {
        'type': msgType == 2 ? 'ORDER' : 'NOTICE',
        'name': name,
        'text': text,
        'data': {'orderNum': 'ORD-1', 'taskId': 1},
      },
    });
  }

  group('事件映射渲染（t23 六类事件）', () {
    testWidgets('ORDER_PAID 渲染支付成功卡片', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SystemMessageCard(
              message: systemMessage(
                name: 'ORDER_PAID',
                text: '您的任务已支付成功，等待飞手接单',
                timestamp: DateTime(2026, 9, 12, 9, 48).millisecondsSinceEpoch,
              ),
            ),
          ),
        ),
      );

      expect(find.text('支付成功'), findsOneWidget);
      expect(find.text('您的任务已支付成功，等待飞手接单'), findsOneWidget);
      expect(find.text('9-12 09:48'), findsOneWidget, reason: "展示时间戳");
      expect(find.byIcon(Icons.payments_outlined), findsOneWidget);
    });

    testWidgets('TASK_ACCEPTED / TASK_CANCELLED / TASK_COMPLETED 事件标签',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                SystemMessageCard(
                    message: systemMessage(name: 'TASK_ACCEPTED')),
                SystemMessageCard(
                    message: systemMessage(name: 'TASK_CANCELLED')),
                SystemMessageCard(
                    message: systemMessage(name: 'TASK_COMPLETED')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('任务已被接单'), findsOneWidget);
      expect(find.text('接单已取消'), findsOneWidget);
      expect(find.text('任务已完成'), findsOneWidget);
    });

    testWidgets('ORDER_WAITING_CONFIRM / ORDER_CONFIRMED 事件标签',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                SystemMessageCard(
                    message: systemMessage(name: 'ORDER_WAITING_CONFIRM')),
                SystemMessageCard(
                    message: systemMessage(name: 'ORDER_CONFIRMED')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('订单待验收'), findsOneWidget);
      expect(find.text('订单已确认完成'), findsOneWidget);
    });
  });

  group('兜底与判定', () {
    testWidgets('未知事件名回退为通用系统通知样式（text 兜底展示）', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SystemMessageCard(
              message: systemMessage(name: 'FUTURE_EVENT', msgType: 1),
            ),
          ),
        ),
      );

      expect(find.text('系统通知'), findsOneWidget);
      expect(find.text('您的任务有新的状态变更'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_active_outlined), findsOneWidget);
    });

    testWidgets('空 text 时不渲染内容行', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SystemMessageCard(
              message: MessageVo.fromJson({
                'msgId': 'sys-2',
                'sessionId': 99,
                'msgType': 1,
                'fromUserId': 0,
                'timestamp': DateTime(2026, 9, 12, 9, 48).millisecondsSinceEpoch,
                'payload': {'type': 'NOTICE', 'name': 'ORDER_PAID'},
              }),
            ),
          ),
        ),
      );

      expect(find.text('支付成功'), findsOneWidget);
      expect(find.text('您的任务有新的状态变更'), findsNothing);
    });

    test('isSystemMessage 判定', () {
      expect(
        isSystemMessage(systemMessage(name: 'ORDER_PAID', msgType: 2)),
        true,
      );
      expect(
        isSystemMessage(
          MessageVo.fromJson({
            'msgId': 'c1',
            'sessionId': 55,
            'msgType': 0,
            'fromUserId': 8,
            'payload': {'text': 'hi'},
          }),
        ),
        false,
        reason: '普通 CHAT 消息不是系统消息',
      );
      expect(
        isSystemMessage(
          MessageVo.fromJson({
            'msgId': 'c2',
            'sessionId': 55,
            'msgType': 0,
            'fromUserId': 0,
            'payload': {'text': 'legacy'},
          }),
        ),
        true,
        reason: 'fromUserId=0 视为系统消息（兜底判定）',
      );
    });

    test('payload.name 解析（CHAT 消息无 name 时为 null）', () {
      final system = systemMessage(name: 'ORDER_PAID');
      expect(system.payloadName, 'ORDER_PAID');

      final chat = MessageVo.fromJson({
        'msgId': 'c3',
        'sessionId': 55,
        'msgType': 0,
        'fromUserId': 8,
        'payload': {'text': 'hi'},
      });
      expect(chat.payloadName, isNull);
    });
  });
}
