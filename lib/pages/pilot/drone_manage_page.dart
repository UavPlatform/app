import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/rider_account_provider.dart';

class DroneManagePage extends ConsumerStatefulWidget {
  const DroneManagePage({super.key});

  @override
  ConsumerState<DroneManagePage> createState() => _DroneManagePageState();
}

class _DroneManagePageState extends ConsumerState<DroneManagePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(droneListProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(droneListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('我的无人机')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBindDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Builder(
        builder: (context) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(droneListProvider.notifier).load(),
            child: state.drones.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.flight, size: 64,
                                  color: AppColors.outlineVariant.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              const Text('还没有绑定无人机',
                                  style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 16)),
                              const SizedBox(height: 8),
                              const Text('点击右下角按钮添加',
                                  style: TextStyle(color: AppColors.outline, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.drones.length,
                    itemBuilder: (context, index) {
                      final drone = state.drones[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.flight, color: AppColors.primary),
                          ),
                          title: Text('DJI ID: ${drone.djiId}',
                              style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text(
                            drone.createTime ?? '',
                            style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.error),
                            onPressed: () => _showUnbindDialog(context, drone.djiId),
                          ),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  Future<void> _showBindDialog(BuildContext context) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('绑定无人机'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '请输入 DJI 无人机 ID',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('绑定')),
        ],
      ),
    );

    if (ok != true || !context.mounted) {
      controller.dispose();
      return;
    }
    final djiId = controller.text.trim();
    if (djiId.isEmpty) {
      controller.dispose();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      controller.dispose();
      if (!context.mounted) return;
      final success = await ref.read(droneListProvider.notifier).bindDrone(djiId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? '绑定成功' : ref.read(droneListProvider).error ?? '绑定失败')),
      );
    });
  }

  Future<void> _showUnbindDialog(BuildContext context, String djiId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('解绑无人机'),
        content: Text('确定要解绑 $djiId 吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('解绑', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      final success = await ref.read(droneListProvider.notifier).unbindDrone(djiId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? '已解绑' : ref.read(droneListProvider).error ?? '解绑失败')),
      );
    });
  }
}
