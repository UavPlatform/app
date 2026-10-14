import '../models/result_model.dart';
import 'generated/openapi_paths.dart';
import 'http_client.dart';
import 'generated/openapi_models.dart';
import 'order_api.dart';

class TradeStats {
  final int totalOrderCount;
  final int completedTradeCount;
  final int publishedTaskCount;
  final int boughtOrderCount;
  final int soldOrderCount;
  final int pendingReviewCount;

  const TradeStats({
    required this.totalOrderCount,
    required this.completedTradeCount,
    required this.publishedTaskCount,
    required this.boughtOrderCount,
    required this.soldOrderCount,
    required this.pendingReviewCount,
  });

  factory TradeStats.fromJson(Map<String, dynamic> json) {
    final contract = ApiTradeStatsVO.fromJson(json);
    int count(String field, int? value) {
      if (value == null || value < 0) {
        throw FormatException('Invalid trade count: $field');
      }
      return value.toInt();
    }

    return TradeStats(
      totalOrderCount: count('totalOrderCount', contract.totalOrderCount),
      completedTradeCount: count(
        'completedTradeCount',
        contract.completedTradeCount,
      ),
      publishedTaskCount: count(
        'publishedTaskCount',
        contract.publishedTaskCount,
      ),
      boughtOrderCount: count('boughtOrderCount', contract.boughtOrderCount),
      soldOrderCount: count('soldOrderCount', contract.soldOrderCount),
      pendingReviewCount: count(
        'pendingReviewCount',
        contract.pendingReviewCount,
      ),
    );
  }
}

class TradeApi {
  const TradeApi(this.client);
  final HttpClient client;
  Future<Result<TradeStats>> stats() async {
    final response = await client.dio.get(ApiPaths.orderStats);
    return Result.fromJson(
      response.data as Map<String, dynamic>,
      (data) => TradeStats.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<Result<OrderListVo>> sold({int page = 0, int size = 20}) => _list(
    ApiPaths.orderSold,
    ApiPaths.orderSoldQuery(page: page, size: size),
  );

  Future<Result<OrderListVo>> pendingReview({int page = 0, int size = 20}) =>
      _list(
        ApiPaths.orderPendingReview,
        ApiPaths.orderPendingReviewQuery(page: page, size: size),
      );

  Future<Result<OrderListVo>> _list(
    String path,
    Map<String, dynamic> query,
  ) async {
    final response = await client.dio.get(path, queryParameters: query);
    return Result.fromJson(
      response.data as Map<String, dynamic>,
      (data) => OrderListVo.fromJson(data as Map<String, dynamic>),
    );
  }
}
