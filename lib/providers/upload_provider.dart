import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/upload_api.dart';
import '../models/upload_vo.dart';
import 'auth_provider.dart';

final uploadApiProvider = Provider<UploadApi>(
  (ref) => UploadApi(ref.watch(httpClientProvider)),
);

class UploadState {
  final List<UploadVo> files;
  final bool loading;
  final bool uploading;
  final String? error;

  const UploadState({
    this.files = const [],
    this.loading = true,
    this.uploading = false,
    this.error,
  });

  UploadState copyWith({
    List<UploadVo>? files,
    bool? loading,
    bool? uploading,
    String? error,
  }) {
    return UploadState(
      files: files ?? this.files,
      loading: loading ?? this.loading,
      uploading: uploading ?? this.uploading,
      error: error,
    );
  }
}

class UploadNotifier extends StateNotifier<UploadState> {
  final UploadApi _api;

  UploadNotifier(this._api) : super(const UploadState()) {
    loadFiles();
  }

  Future<void> loadFiles() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final result = await _api.list();
      if (!result.success || result.data == null) {
        state = state.copyWith(loading: false, error: result.message ?? '加载失败');
        return;
      }
      state = state.copyWith(loading: false, files: result.data!.files);
    } catch (e) {
      state = state.copyWith(loading: false, error: '加载失败: $e');
    }
  }

  Future<bool> upload({
    required String fileName,
    required List<int> bytes,
    String? mimeType,
    String? orderNum,
  }) async {
    state = state.copyWith(uploading: true, error: null);
    try {
      // 推断 mimeType（签名和 PUT 必须一致）
      final mt = mimeType ?? _mimeFromName(fileName);

      // 1. get pre-signed URL
      final signResult = await _api.sign(
        fileName: fileName,
        fileSize: bytes.length,
        mimeType: mt,
        orderNum: orderNum,
      );
      if (!signResult.success || signResult.data == null) {
        state = state.copyWith(uploading: false, error: signResult.message ?? '获取上传凭证失败');
        return false;
      }

      // 2. PUT to OSS
      final ok = await _api.uploadToOss(
        signResult.data!.preSignedUrl,
        bytes,
        mt ?? 'application/octet-stream',
      );
      if (!ok) {
        state = state.copyWith(uploading: false, error: '文件上传到OSS失败');
        return false;
      }

      // 3. confirm
      final confirmResult = await _api.confirm(signResult.data!.fileId);
      if (!confirmResult.success) {
        state = state.copyWith(uploading: false, error: confirmResult.message ?? '确认上传失败');
        return false;
      }

      await loadFiles();
      state = state.copyWith(uploading: false);
      return true;
    } catch (e) {
      state = state.copyWith(uploading: false, error: '上传失败: $e');
      return false;
    }
  }

  String? _mimeFromName(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      default:
        return null;
    }
  }

  Future<bool> deleteFile(int id) async {
    try {
      final result = await _api.delete(id);
      if (!result.success) {
        state = state.copyWith(error: result.message ?? '删除失败');
        return false;
      }
      state = state.copyWith(
        files: state.files.where((f) => f.id != id).toList(),
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: '删除失败: $e');
      return false;
    }
  }
}

final uploadProvider = StateNotifierProvider<UploadNotifier, UploadState>(
  (ref) => UploadNotifier(ref.watch(uploadApiProvider)),
);
