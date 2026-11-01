import '../utils/failure_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/generated/openapi_models.dart';
import '../api/review_api.dart';
import 'auth_provider.dart';

final reviewApiProvider = Provider<ReviewApi>(
  (ref) => ReviewApi(ref.watch(httpClientProvider)),
);

/// 单个订单的评价（null = 尚未评价）。失败时抛出服务端文案，交由 UI 展示重试。
final orderReviewProvider = FutureProvider.autoDispose
    .family<ApiOrderReview?, String>((ref, orderNum) async {
      final result = await ref.watch(reviewApiProvider).getReview(orderNum);
      if (!result.success) {
        throw FailureNotice(
          resultFailureMessage(result, fallback: '评价暂时无法加载，请稍后刷新'),
        );
      }
      return result.data;
    });

/// 我发出的评价列表（首页 20 条，足够演示与日常使用；分页另议）。
final myReviewsProvider = FutureProvider.autoDispose<List<ApiOrderReview>>((
  ref,
) async {
  final result = await ref.watch(reviewApiProvider).myReviews();
  if (!result.success) {
    throw FailureNotice(
      resultFailureMessage(result, fallback: '评价暂时无法加载，请稍后刷新'),
    );
  }
  return result.data?.reviews ?? const <ApiOrderReview>[];
});
