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
                    Text('附近范围：起点周边 ${value.radiusKm} 公里'),
                    Text('本轮已向 ${value.notifiedPilotCount} 位飞手生成站内派单通知'),
                    const Text('站内通知不代表已读或手机系统推送。全部订单大厅仍可接单。'),
                    if (value.reminderSent == true)
                      const Text('已提醒：暂未接单，范围保持不变。你可以继续等待或取消运单。')
                    else if (value.reminderAt != null)
                      Text(
                        '仍无人接单时，将于 ${value.reminderAt!.replaceFirst('T', ' ')} 提醒；不自动扩大范围或取消。',
                      ),
                  ],
                ),
        );
  }
}
