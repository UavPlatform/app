import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';

class AddressListPage extends StatelessWidget {
  const AddressListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('地址管理'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: AppColors.outline),
            SizedBox(height: 16),
            Text('暂无收货地址', style: TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant)),
            SizedBox(height: 8),
            Text('地址管理功能开发中...', style: TextStyle(fontSize: 14, color: AppColors.outline)),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () => context.push('/address/edit'),
          child: const Text('新增收货地址'),
        ),
      ),
    );
  }

}
