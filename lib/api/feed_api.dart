import 'http_client.dart';
import '../models/result_model.dart';
import '../models/feed_vo.dart';

class FeedApi {
  final HttpClient _client;
  FeedApi(this._client);

  Result<FeedVo> _parseFeed(Map<String, dynamic> data) {
    if (data['code'] == 200 && data['data'] != null) {
      return Result(success: true, code: 200, message: data['message'] as String?, data: FeedVo.fromJson(data['data']));
    }
    return Result(success: false, code: data['code'], message: data['message'] as String?);
  }

  Future<Result<FeedVo>> publish({required String content, List<int>? mediaIds}) async {
    final body = <String, dynamic>{'content': content};
    if (mediaIds != null && mediaIds.isNotEmpty) body['mediaIds'] = mediaIds;
    final r = await _client.dio.post('/rider/feed', data: body);
    return _parseFeed(r.data);
  }

  Future<Result<FeedVo>> detail(int id) async {
    final r = await _client.dio.get('/rider/feed/$id');
    return _parseFeed(r.data);
  }

  Future<Result<FeedVo>> update(int id, {String? content, List<int>? mediaIds}) async {
    final body = <String, dynamic>{};
    if (content != null && content.isNotEmpty) body['content'] = content;
    if (mediaIds != null) body['mediaIds'] = mediaIds;
    final r = await _client.dio.put('/rider/feed/$id', data: body);
    return _parseFeed(r.data);
  }

  Future<Result<void>> deleteFeed(int id) async {
    final r = await _client.dio.delete('/rider/feed/$id');
    final d = r.data as Map<String, dynamic>;
    return Result(success: d['code'] == 200, code: d['code'], message: d['message'] as String?);
  }

  Future<Result<FeedPageVo>> list({int page = 0, int size = 20, String sort = 'latest', int? userId}) async {
    final q = <String, dynamic>{'page': page, 'size': size, 'sort': sort};
    if (userId != null) q['userId'] = userId;
    final r = await _client.dio.get('/rider/feed', queryParameters: q);
    final d = r.data as Map<String, dynamic>;
    if (d['code'] == 200 && d['data'] != null) {
      return Result(success: true, code: 200, message: d['message'] as String?, data: FeedPageVo.fromJson(d['data']));
    }
    return Result(success: false, code: d['code'], message: d['message'] as String?);
  }

  Future<Result<FeedVo>> like(int id) async {
    final r = await _client.dio.post('/rider/feed/$id/like');
    return _parseFeed(r.data);
  }

  Future<Result<FeedCommentPageVo>> comments(int feedId, {int page = 0, int size = 20}) async {
    final r = await _client.dio.get('/rider/feed/$feedId/comments', queryParameters: {'page': page, 'size': size});
    final d = r.data as Map<String, dynamic>;
    if (d['code'] == 200 && d['data'] != null) {
      return Result(success: true, code: 200, message: d['message'] as String?, data: FeedCommentPageVo.fromJson(d['data']));
    }
    return Result(success: false, code: d['code'], message: d['message'] as String?);
  }

  Future<Result<FeedCommentVo>> postComment(int feedId, {required String content, int? parentId}) async {
    final body = <String, dynamic>{'content': content};
    if (parentId != null) body['parentId'] = parentId;
    final r = await _client.dio.post('/rider/feed/$feedId/comments', data: body);
    final d = r.data as Map<String, dynamic>;
    if (d['code'] == 200 && d['data'] != null) {
      return Result(success: true, code: 200, message: d['message'] as String?, data: FeedCommentVo.fromJson(d['data']));
    }
    return Result(success: false, code: d['code'], message: d['message'] as String?);
  }

  Future<Result<void>> deleteComment(int feedId, int commentId) async {
    final r = await _client.dio.delete('/rider/feed/$feedId/comments/$commentId');
    final d = r.data as Map<String, dynamic>;
    return Result(success: d['code'] == 200, code: d['code'], message: d['message'] as String?);
  }
}
