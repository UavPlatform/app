// 我的评价（GET /review/my）：用户发出的订单评价列表，带加载/空/错误态。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/review_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/infinite_list.dart';
import '../orders/widgets/review_section.dart';

class MyReviewsPage extends ConsumerWidget {
  const MyReviewsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myReviewsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('我的评价')),
      body: state.isInitialLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 160),
                    Center(
                      child: Text(
                        (state.error ?? '').trim().isEmpty
                            ? '评价暂时无法加载，请稍后刷新'
                            : state.error!,
                        style: TextStyle(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: OutlinedButton(
                        onPressed: () => ref
                            .read(myReviewsProvider.notifier)
                            .load(refresh: true),
                        child: const Text('重试'),
                      ),
                    ),
                  ],
                )
              : InfiniteList(
                  onRefresh: () =>
                      ref.read(myReviewsProvider.notifier).load(refresh: true),
                  onLoadMore: () =>
                      ref.read(myReviewsProvider.notifier).load(),
                  hasMore: state.hasNext,
                  loadingMore: state.loading && state.items.isNotEmpty,
                  itemCount: state.items.length,
                  empty: const Column(
                    children: [
                      SizedBox(height: 160),
                      Icon(
                        Icons.star_outline,
                        size: 64,
                        color: AppColors.outline,
                      ),
                      SizedBox(height: 12),
                      Center(
                        child: Text(
                          '还没有评价过订单',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      SizedBox(height: 6),
                      Center(
                        child: Text(
                          '订单确认完成后，可在订单详情里评价飞手',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.outline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  itemBuilder: (_, i) => Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ReviewCard(
                        review: state.items[i],
                        showOrderNum: true,
                      ),
                    ),
                  ),
                ),
    );
  }
}
