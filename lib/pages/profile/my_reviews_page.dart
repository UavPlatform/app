// 我的评价（GET /review/my）：用户发出的订单评价列表，带加载/空/错误态。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/review_provider.dart';
import '../../theme/app_colors.dart';
import '../orders/widgets/review_section.dart';

class MyReviewsPage extends ConsumerWidget {
  const MyReviewsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myReviewsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('我的评价')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myReviewsProvider.future),
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 160),
              const Center(
                child: Text('评价加载失败',
                    style: TextStyle(color: AppColors.onSurfaceVariant)),
              ),
              const SizedBox(height: 12),
              Center(
                child: OutlinedButton(
                  onPressed: () => ref.invalidate(myReviewsProvider),
                  child: const Text('重试'),
                ),
              ),
            ],
          ),
          data: (reviews) => reviews.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 160),
                    Icon(Icons.star_outline, size: 64, color: AppColors.outline),
                    SizedBox(height: 12),
                    Center(
                      child: Text('还没有评价过订单',
                          style: TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant)),
                    ),
                    SizedBox(height: 6),
                    Center(
                      child: Text('订单确认完成后，可在订单详情里评价飞手',
                          style: TextStyle(fontSize: 13, color: AppColors.outline)),
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: reviews.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ReviewCard(review: reviews[i], showOrderNum: true),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
