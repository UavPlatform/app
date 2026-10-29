import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/dispatch_order.dart';
import '../../providers/dispatch_nearby_provider.dart';

class DispatchNearbyStatus extends ConsumerWidget {
  const DispatchNearbyStatus({super.key, required this.order});
  final DispatchOrder order;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (order.id, order.data.assignmentVersion ?? 0);
    return ref
        .watch(dispatchNearbyStatusProvider(key))
        .when(
          loading: () => const Text('正在查询附近派单进度…'),
          error: (error, _) => TextButton(
            onPressed: () => ref.invalidate(dispatchNearbyStatusProvider(key)),
            child: const Text('附近派单进度暂不可用，点击重试'),
          ),
          data: (value) => value.state != 'WAITING_ACCEPTANCE'
              ? const Text('订单状态已变化，正在更新进度…')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('匹配范围 · 起点 ${value.radiusKm} 公里内'),
                    Text('已通知 ${value.notifiedPilotCount} 位附近飞手（站内）'),
                    if (value.reminderSent == true)
                      const Text('暂未接单，可继续等待或取消订单。')
                    else if (value.reminderAt != null)
                      Text(
                        '${value.reminderAt!.replaceFirst('T', ' ')} 提醒你查看进度，不自动取消或扩大范围。',
                      ),
                  ],
                ),
        );
  }
}
