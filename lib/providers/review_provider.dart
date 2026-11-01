import '../utils/failure_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/generated/openapi_models.dart';
import '../api/review_api.dart';
import 'auth_provider.dart';
import 'paged_list.dart';

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

class MyReviewsNotifier extends OffsetPagedNotifier<ApiOrderReview> {
  MyReviewsNotifier(this._api) : super();
  final ReviewApi _api;

  @override
  String itemKey(ApiOrderReview item) =>
      item.id?.toString() ?? item.orderNum ?? '${item.hashCode}';

  @override
  Future<OffsetPage<ApiOrderReview>> fetchPage(int page) async {
    final result = await _api.myReviews(page: page);
    if (!result.success) {
      throw FailureNotice(
        resultFailureMessage(result, fallback: '评价暂时无法加载，请稍后刷新'),
      );
    }
    final data = result.data;
    final current = data?.currentPage ?? page;
    final total = data?.totalPages ?? 0;
    return (
      items: data?.reviews ?? const <ApiOrderReview>[],
      page: current,
      hasNext: current + 1 < total,
    );
  }
}

final myReviewsProvider = StateNotifierProvider.autoDispose<
  MyReviewsNotifier,
  PagedListState<ApiOrderReview>
>((ref) => MyReviewsNotifier(ref.watch(reviewApiProvider))..load());
