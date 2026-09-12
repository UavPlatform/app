// 系统消息卡片（t33：任务状态通知渲染，Q9=A）。
// 按 t23 载荷契约：msgType=1（NOTICE）/2（ORDER）、fromUserId=0、
// payload.name 标识事件、payload.text 为人类文案兜底。

import 'package:flutter/material.dart';

import '../models/message_vo.dart';
import '../theme/app_colors.dart';

/// 判定是否为系统消息（NOTICE/ORDER 或 fromUserId=0）。
bool isSystemMessage(MessageVo message) {
  return message.fromUserId == 0 ||
      message.msgType == 1 ||
      message.msgType == 2;
}

/// 系统消息卡片：样式区别于普通文本消息气泡，
/// 按 payload.name 渲染事件图标与标题，payload.text 兜底展示内容。
class SystemMessageCard extends StatelessWidget {
  final MessageVo message;

  const SystemMessageCard({super.key, required this.message});

  static const Map<String, List<Object>> _eventMeta = {
    'ORDER_PAID': [Icons.payments_outlined, '支付成功'],
    'TASK_ACCEPTED': [Icons.assignment_turned_in_outlined, '任务已被接单'],
    'TASK_CANCELLED': [Icons.assignment_return_outlined, '接单已取消'],
    'TASK_COMPLETED': [Icons.task_alt, '任务已完成'],
    'ORDER_WAITING_CONFIRM': [Icons.hourglass_top_outlined, '订单待验收'],
    'ORDER_CONFIRMED': [Icons.verified_outlined, '订单已确认完成'],
  };

  String get _eventLabel {
    final name = message.payloadName;
    if (name != null && _eventMeta.containsKey(name)) {
      return _eventMeta[name]![1] as String;
    }
    return message.msgType == 2 ? '订单动态' : '系统通知';
  }

  IconData get _eventIcon {
    final name = message.payloadName;
    if (name != null && _eventMeta.containsKey(name)) {
      return _eventMeta[name]![0] as IconData;
    }
    return Icons.notifications_active_outlined;
  }

  String get _formattedTime {
    if (message.timestamp <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(message.timestamp);
    final minute = dt.minute.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    return '${dt.month}-${dt.day} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: AppColors.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(_eventIcon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _eventLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (message.content.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      message.content,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (_formattedTime.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formattedTime,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
