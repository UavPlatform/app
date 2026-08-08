import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/feed_api.dart';
import '../api/upload_api.dart';
import '../models/feed_vo.dart';
import 'auth_provider.dart';

final feedApiProvider = Provider<FeedApi>((ref) => FeedApi(ref.watch(httpClientProvider)));

// ---- 列表 ----
class FeedListState {
  final List<FeedVo> feeds;
  final bool loading;
  final int page;
  final int totalPages;
  final String? error;
  const FeedListState({this.feeds = const [], this.loading = true, this.page = 0, this.totalPages = 0, this.error});
}

class FeedListNotifier extends StateNotifier<FeedListState> {
  final FeedApi _api;
  FeedListNotifier(this._api) : super(const FeedListState()) { Future.microtask(() => load()); }

  Future<void> load({int page = 0}) async {
    state = FeedListState(feeds: state.feeds, loading: true, page: state.page, totalPages: state.totalPages);
    try {
      final r = await _api.list(page: page);
      if (!r.success || r.data == null) { state = FeedListState(loading: false, error: r.message ?? '加载失败'); return; }
      state = FeedListState(feeds: page == 0 ? r.data!.feeds : [...state.feeds, ...r.data!.feeds], loading: false, page: r.data!.currentPage, totalPages: r.data!.totalPages);
    } catch (e) {
      state = FeedListState(loading: false, error: '加载失败: $e');
    }
  }

  Future<void> refresh() => load(page: 0);
  void updateFeed(FeedVo f) { state = FeedListState(feeds: state.feeds.map((x) => x.id == f.id ? f : x).toList(), loading: false, page: state.page, totalPages: state.totalPages); }
  void removeFeed(int id) { state = FeedListState(feeds: state.feeds.where((x) => x.id != id).toList(), loading: false, page: state.page, totalPages: state.totalPages); }
}

final feedListProvider = StateNotifierProvider<FeedListNotifier, FeedListState>((ref) => FeedListNotifier(ref.watch(feedApiProvider)));

// ---- 详情 ----
class FeedDetailState { final FeedVo? feed; final bool loading; final String? error; const FeedDetailState({this.feed, this.loading = true, this.error}); }

class FeedDetailNotifier extends StateNotifier<FeedDetailState> {
  final FeedApi _api; final int _id;
  FeedDetailNotifier(this._api, this._id) : super(const FeedDetailState()) { Future.microtask(() => load()); }
  Future<void> load() async {
    state = const FeedDetailState(loading: true);
    try { final r = await _api.detail(_id); state = FeedDetailState(feed: r.data, loading: false, error: r.success ? null : r.message); } catch (e) { state = FeedDetailState(loading: false, error: '$e'); }
  }
  Future<bool> toggleLike() async {
    try { final r = await _api.like(_id); if (r.success && r.data != null) { state = FeedDetailState(feed: r.data, loading: false); return true; } return false; } catch (_) { return false; }
  }
}

final feedDetailProvider = StateNotifierProvider.family<FeedDetailNotifier, FeedDetailState, int>((ref, id) => FeedDetailNotifier(ref.watch(feedApiProvider), id));

// ---- 评论 ----
class FeedCommentListState { final List<FeedCommentVo> comments; final bool loading; final String? error; const FeedCommentListState({this.comments = const [], this.loading = true, this.error}); }

class FeedCommentListNotifier extends StateNotifier<FeedCommentListState> {
  final FeedApi _api; final int _feedId;
  FeedCommentListNotifier(this._api, this._feedId) : super(const FeedCommentListState()) { Future.microtask(() => load()); }
  Future<void> load() async {
    state = const FeedCommentListState(loading: true);
    try { final r = await _api.comments(_feedId); state = FeedCommentListState(comments: r.data?.comments ?? [], loading: false, error: r.success ? null : r.message); } catch (e) { state = FeedCommentListState(loading: false, error: '$e'); }
  }
  Future<bool> post(String content) async {
    try { final r = await _api.postComment(_feedId, content: content); if (r.success && r.data != null) { state = FeedCommentListState(comments: [r.data!, ...state.comments], loading: false); return true; } return false; } catch (_) { return false; }
  }
  Future<bool> delete(int commentId) async {
    try { final r = await _api.deleteComment(_feedId, commentId); if (r.success) { state = FeedCommentListState(comments: state.comments.where((c) => c.id != commentId).toList(), loading: false); return true; } return false; } catch (_) { return false; }
  }
}

final feedCommentListProvider = StateNotifierProvider.family<FeedCommentListNotifier, FeedCommentListState, int>((ref, feedId) => FeedCommentListNotifier(ref.watch(feedApiProvider), feedId));

// ---- 发布 ----
class FeedPublishState {
  final bool busy;
  final bool uploading;
  final List<int> mediaIds;
  final int? editingId;
  final String? error;
  const FeedPublishState({this.busy = false, this.uploading = false, this.mediaIds = const [], this.editingId, this.error});
}

class FeedPublishNotifier extends StateNotifier<FeedPublishState> {
  final FeedApi _feedApi;
  final UploadApi _uploadApi;

  FeedPublishNotifier(this._feedApi, this._uploadApi) : super(const FeedPublishState());

  void initEdit(FeedVo f) => state = FeedPublishState(mediaIds: f.media.map((m) => m.id).toList(), editingId: f.id);
  void addMediaId(int id) => state = FeedPublishState(mediaIds: [...state.mediaIds, id], editingId: state.editingId);
  void removeMedia(int i) { final l = [...state.mediaIds]; l.removeAt(i); state = FeedPublishState(mediaIds: l, editingId: state.editingId); }
  void setError(String? e) => state = FeedPublishState(mediaIds: state.mediaIds, editingId: state.editingId, error: e);

  Future<int?> uploadMedia(String name, List<int> bytes, String? mime) async {
    state = FeedPublishState(mediaIds: state.mediaIds, uploading: true, editingId: state.editingId);
    try {
      final s = await _uploadApi.sign(fileName: name, fileSize: bytes.length, mimeType: mime);
      if (!s.success || s.data == null) { setError('签名失败'); return null; }
      final ok = await _uploadApi.uploadToOss(s.data!.preSignedUrl, bytes, mime ?? 'application/octet-stream');
      if (!ok) { setError('上传OSS失败'); return null; }
      final c = await _uploadApi.confirm(s.data!.fileId);
      if (!c.success) { setError('确认失败'); return null; }
      addMediaId(c.data?.id ?? s.data!.fileId);
      return state.mediaIds.last;
    } catch (e) { setError('上传失败: $e'); return null; }
  }

  Future<bool> submit(String content) async {
    state = FeedPublishState(mediaIds: state.mediaIds, busy: true, editingId: state.editingId);
    try {
      final mids = state.mediaIds.isEmpty ? null : state.mediaIds;
      final r = state.editingId != null ? await _feedApi.update(state.editingId!, content: content, mediaIds: mids) : await _feedApi.publish(content: content, mediaIds: mids);
      if (r.success) { state = const FeedPublishState(); return true; }
      setError(r.message); return false;
    } catch (e) { setError('提交失败: $e'); return false; }
  }
}

final feedPublishProvider = StateNotifierProvider<FeedPublishNotifier, FeedPublishState>((ref) {
  return FeedPublishNotifier(ref.watch(feedApiProvider), UploadApi(ref.watch(httpClientProvider)));
});
