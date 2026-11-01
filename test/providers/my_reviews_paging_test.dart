import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/generated/openapi_models.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/api/review_api.dart';
import 'package:uav_pilot_app/models/result_model.dart';
import 'package:uav_pilot_app/providers/review_provider.dart';
import 'package:uav_pilot_app/services/token_storage.dart';

class _FakeReviewApi extends ReviewApi {
  _FakeReviewApi(super.client);
  final calls = <int>[];
  @override
  Future<Result<ApiReviewListVO>> myReviews({
    int page = 0,
    int size = 20,
  }) async {
    calls.add(page);
    final all = List.generate(
      25,
      (i) => ApiOrderReview(id: i, orderNum: 'O$i', rating: 5),
    );
    final start = page * size;
    final slice = all.skip(start).take(size).toList();
    return Result(
      success: true,
      data: ApiReviewListVO(
        reviews: slice,
        currentPage: page,
        totalPages: 2,
        totalElements: all.length,
      ),
    );
  }
}

void main() {
  test('my reviews uses currentPage/totalPages for hasNext', () async {
    SharedPreferences.setMockInitialValues({});
    final client = HttpClient(TokenStorage(await SharedPreferences.getInstance()));
    final api = _FakeReviewApi(client);
    final notifier = MyReviewsNotifier(api);
    addTearDown(() {
      notifier.dispose();
      client.dio.close();
    });
    await notifier.load();
    expect(notifier.state.items, hasLength(20));
    expect(notifier.state.hasNext, isTrue);
    await notifier.load();
    expect(notifier.state.items, hasLength(25));
    expect(notifier.state.hasNext, isFalse);
    expect(api.calls, [0, 1]);
  });
}
