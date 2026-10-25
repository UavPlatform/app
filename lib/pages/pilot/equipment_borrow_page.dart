import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/generated/openapi_models.dart';
import '../../providers/equipment_provider.dart';
import '../../providers/waybill_draft_provider.dart';
import 'equipment_borrow_action.dart';

class EquipmentBorrowPage extends ConsumerWidget {
  const EquipmentBorrowPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(waybillDraftScopeProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('设备借用与归还'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '设备目录'),
              Tab(text: '我的借还'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _EquipmentList(key: ValueKey('catalog:$scope'), history: false),
            _EquipmentList(key: ValueKey('history:$scope'), history: true),
          ],
        ),
      ),
    );
  }
}

class _EquipmentList extends ConsumerStatefulWidget {
  const _EquipmentList({super.key, required this.history});
  final bool history;
  @override
  ConsumerState<_EquipmentList> createState() => _EquipmentListState();
}

class _EquipmentListState extends ConsumerState<_EquipmentList> {
  int _page = 0;
  Widget _drone(ApiProviderDroneVO drone) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        '${drone.modelName ?? ''} · ${drone.serialNumber}',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      Text('机场：${drone.airportName ?? '未知'}'),
      Text('机场坐标：${drone.latitude}, ${drone.longitude}'),
    ],
  );
  Widget _card(ApiProviderDroneVO drone, {ApiDroneBorrowVO? loan}) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _drone(drone),
          if (loan != null) ...[
            Text('借用时间：${loan.borrowedAt}'),
            Text(
              loan.returnedAt == null ? '状态：借用中' : '归还时间：${loan.returnedAt}',
            ),
            if (loan.returnedAt == null)
              EquipmentBorrowAction(
                key: ValueKey(loan.borrowId),
                droneId: drone.droneId!,
                borrowId: loan.borrowId,
              ),
          ] else ...[
            Text(
              !drone.enabled!
                  ? '状态：已停用'
                  : drone.borrowedByMe!
                  ? '状态：本人借用中'
                  : drone.borrowed!
                  ? '状态：已借出，不可借'
                  : '状态：可借用',
            ),
            if (drone.borrowedByMe!)
              EquipmentBorrowAction(
                key: ValueKey(drone.currentBorrowId),
                droneId: drone.droneId!,
                borrowId: drone.currentBorrowId,
              )
            else if (drone.enabled! && !drone.borrowed!)
              EquipmentBorrowAction(
                key: ValueKey(drone.droneId),
                droneId: drone.droneId!,
              ),
          ],
        ],
      ),
    ),
  );
  Widget _body(List<Widget> children, bool next) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(16),
    children: [
      const Text('借还登记不收费、不收押金、不关联订单。请先在现场完成设备交接；实际连机与飞行在 djifly 操作。'),
      if (children.isEmpty)
        Padding(
          padding: const EdgeInsets.all(32),
          child: Text(widget.history ? '暂无本人借还记录' : '暂无可展示设备，请联系机场管理员完成登记'),
        ),
      ...children,
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: _page == 0 ? null : () => setState(() => _page--),
            child: const Text('上一页'),
          ),
          Text('第 ${_page + 1} 页'),
          TextButton(
            onPressed: next ? () => setState(() => _page++) : null,
            child: const Text('下一页'),
          ),
        ],
      ),
    ],
  );
  @override
  Widget build(BuildContext context) {
    Future<void> refresh() async {
      ref.invalidate(equipmentCatalogProvider);
      ref.invalidate(equipmentBorrowsProvider);
      try {
        if (widget.history) {
          await ref.read(equipmentBorrowsProvider(_page).future);
        } else {
          await ref.read(equipmentCatalogProvider(_page).future);
        }
      } catch (_) {
        /* The provider renders the error and retry action. */
      }
    }

    Widget error(Object e) => ListView(
      children: [TextButton(onPressed: refresh, child: Text('$e\n重新查询'))],
    );
    return RefreshIndicator(
      onRefresh: refresh,
      child: widget.history
          ? ref
                .watch(equipmentBorrowsProvider(_page))
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => error(e),
                  data: (page) => _body([
                    for (final loan in page.items!)
                      _card(loan.drone!, loan: loan),
                  ], page.hasNext!),
                )
          : ref
                .watch(equipmentCatalogProvider(_page))
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => error(e),
                  data: (page) => _body([
                    for (final drone in page.items!) _card(drone),
                  ], page.hasNext!),
                ),
    );
  }
}
