import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';

class RiderDetailPage extends ConsumerWidget {
  final int riderId;

  const RiderDetailPage({super.key, required this.riderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('飞手详情'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      body: const Center(
        child: Text('飞手详情页开发中...', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
      ),
    );
  }
}
