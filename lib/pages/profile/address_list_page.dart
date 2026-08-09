import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/address_vo.dart';
import '../../providers/address_provider.dart';
import '../../theme/app_colors.dart';

class AddressListPage extends ConsumerStatefulWidget {
  const AddressListPage({super.key});

  @override
  ConsumerState<AddressListPage> createState() => _AddressListPageState();
}

class _AddressListPageState extends ConsumerState<AddressListPage> {
  Future<void> _deleteAddress(AddressVo address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确定要删除该地址吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.onSurfaceVariant),
            child: const Text('确定'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('取消'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await ref.read(addressProvider.notifier).deleteAddress(address.id);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('删除失败')),
      );
    }
  }

  void _copyAddress(AddressVo address) {
    Clipboard.setData(ClipboardData(text: address.copyText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板'), duration: Duration(seconds: 1)),
    );
  }

  Future<void> _editAddress(AddressVo? address) async {
    final saved = await context.push<bool>('/address/edit', extra: address);
    if (saved == true && mounted) {
      // provider 已更新，这里仅提示；列表由 watch 自动刷新
    }
  }

  Future<void> _setDefault(AddressVo address) async {
    final ok = await ref.read(addressProvider.notifier).setDefault(address.id);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('设置默认失败')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addressProvider);
    final sorted = [...state.addresses]
      ..sort((a, b) {
        if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
        return b.id.compareTo(a.id);
      });

    return Scaffold(
      appBar: AppBar(title: const Text('地址管理')),
      body: state.loading && sorted.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : sorted.isEmpty
              ? RefreshIndicator(
                  onRefresh: () => ref.read(addressProvider.notifier).refresh(),
                  child: LayoutBuilder(
                    builder: (context, constraints) => ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: constraints.maxHeight,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_off, size: 64, color: AppColors.outline),
                              SizedBox(height: 16),
                              Text('暂无收货地址', style: TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant)),
                              SizedBox(height: 8),
                              Text('点击下方按钮添加常用地址', style: TextStyle(fontSize: 14, color: AppColors.outline)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(addressProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: sorted.length,
                    itemBuilder: (context, index) => _buildCard(sorted[index]),
                  ),
                ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () => _editAddress(null),
          child: const Text('新增收货地址'),
        ),
      ),
    );
  }

  Widget _buildCard(AddressVo address) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 第一行: 联系人 + 手机号 + 标签
            Row(
              children: [
                Text(address.contactName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                Text(address.contactPhone, style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
                const Spacer(),
                if (address.label != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(address.label!, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // 第二行: 完整地址
            Text(
              address.fullRegion.isNotEmpty ? '${address.fullRegion}${address.detail}' : address.detail,
              style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // 第三行: 默认标记 + 操作按钮
            Row(
              children: [
                if (address.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('默认', style: TextStyle(fontSize: 11, color: AppColors.primary)),
                  ),
                const Spacer(),
                if (!address.isDefault) ...[
                  _actionButton('设默认', () => _setDefault(address)),
                  const SizedBox(width: 8),
                ],
                _actionButton('复制', () => _copyAddress(address)),
                const SizedBox(width: 8),
                _actionButton('编辑', () => _editAddress(address)),
                const SizedBox(width: 8),
                _actionButton('删除', () => _deleteAddress(address), color: Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String label, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Text(label, style: TextStyle(fontSize: 13, color: color ?? AppColors.onSurfaceVariant)),
    );
  }
}
