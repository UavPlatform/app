// 订单评价接口（/review/*）：用户确认完成（订单 COMPLETED）后对飞手打分评价，一单一评。

import 'package:dio/dio.dart';

import '../models/result_model.dart';
import 'http_client.dart';
import 'generated/openapi_models.dart';
import 'generated/openapi_paths.dart';

class ReviewApi {
  final HttpClient _client;

  ReviewApi(this._client);

  /// 查看某订单的评价；尚未评价时后端返回 404，这里归一为 `success + data == null`。
  Future<Result<ApiOrderReview?>> getReview(String orderNum) async {
    try {
      final response = await _client.dio.get(ApiPaths.reviewPath(orderNum));
      return Result.fromJson(
        response.data as Map<String, dynamic>,
        (data) => ApiOrderReview.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return Result(success: true, data: null);
      }
      return _failure(e, '评价加载失败');
    }
  }

  /// 提交评价（rating 1~5，content 可空）。后端校验订单归属与「已完成」状态，一单只能评一次。
  Future<Result<ApiSubmitReviewVO>> submit({
    required String orderNum,
    required int rating,
    String? content,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiPaths.reviewSubmit,
        queryParameters: ApiPaths.reviewSubmitQuery(
          orderNum: orderNum,
          rating: rating,
          content: (content == null || content.trim().isEmpty) ? null : content.trim(),
        )..removeWhere((_, v) => v == null),
      );
      return Result.fromJson(
        response.data as Map<String, dynamic>,
        (data) => ApiSubmitReviewVO.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _failure(e, '评价提交失败，请稍后重试');
    }
  }

  /// 我发出的评价（分页，按时间倒序）。
  Future<Result<ApiReviewListVO>> myReviews({int page = 0, int size = 20}) async {
    final response = await _client.dio.get(
      ApiPaths.reviewMy,
      queryParameters: ApiPaths.reviewMyQuery(page: page, size: size),
    );
    return Result.fromJson(
      response.data as Map<String, dynamic>,
      (data) => ApiReviewListVO.fromJson(data as Map<String, dynamic>),
    );
  }

  Result<T> _failure<T>(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return Result(
        success: false,
        code: data['code'] as int?,
        message: data['message'] as String? ?? fallback,
      );
    }
    return Result(success: false, message: fallback);
  }
}
