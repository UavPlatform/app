import '../models/result_model.dart';
import 'http_client.dart';

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
    int count(String field) {
      final value = json[field];
      if (value is! num || value < 0 || value.toInt() != value) {
        throw FormatException('Invalid trade count: $field');
      }
      return value.toInt();
    }

    return TradeStats(
      totalOrderCount: count('totalOrderCount'),
      completedTradeCount: count('completedTradeCount'),
      publishedTaskCount: count('publishedTaskCount'),
      boughtOrderCount: count('boughtOrderCount'),
      soldOrderCount: count('soldOrderCount'),
      pendingReviewCount: count('pendingReviewCount'),
    );
  }
}

class TradeApi {
  const TradeApi(this.client);
  final HttpClient client;
  Future<Result<TradeStats>> stats() async {
    final response = await client.dio.get('/order/stats');
    return Result.fromJson(
      response.data as Map<String, dynamic>,
      (data) => TradeStats.fromJson(data as Map<String, dynamic>),
    );
  }
}
