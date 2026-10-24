// 直播观看 API（t38，契约以 dev-backend 定稿为准）：
// - POST /live/get?deviceId=：拉流凭证（roomId=drone_<deviceId> 即 strRoomId、
//   userId/userSig 服务端从 JWT 生成不自报、liveState/ackConfirmed 判定运行态）；
//   副作用：ensureOpenRecord 开启观看记录——勿用于入口显隐轮询；
// - GET /webUav/status：设备快照列表（含 liveState），无副作用——入口显隐判定用；
// - POST /live/leave?deviceId=：结束「当前登录用户」在该设备的未关闭观看记录
//   （end_time=now，不动推流与直播状态，幂等）；异常退出（杀进程/断网）由
//   t12 停止链路 LIVE_STOPPED 统一补齐兜底。

import 'package:dio/dio.dart';

import '../models/result_model.dart';
import 'generated/openapi_models.dart';
import 'generated/openapi_paths.dart';
import 'http_client.dart';

/// 拉流凭证（后端 PullCredentialsVO）。
class LiveCredential {
  final String roomId;
  final String userId;
  final String userSig;
  final String? privateMapKey;
  final int sdkAppId;
  final String? wsUrl;
  final String liveState;
  final bool ackConfirmed;

  const LiveCredential({
    required this.roomId,
    required this.userId,
    required this.userSig,
    this.privateMapKey,
    required this.sdkAppId,
    this.wsUrl,
    required this.liveState,
    required this.ackConfirmed,
  });

  factory LiveCredential.fromJson(Map<String, dynamic> json) {
    final c = ApiPullCredentialsVO.fromJson(json);
    return LiveCredential(
      roomId: c.roomId ?? '',
      userId: c.userId ?? '',
      userSig: c.userSig ?? '',
      privateMapKey: c.privateMapKey,
      sdkAppId: c.sdkAppId ?? 0,
      wsUrl: c.wsUrl,
      liveState: c.liveState ?? 'IDLE',
      ackConfirmed: c.ackConfirmed == true,
    );
  }

  /// 凭证快照时刻直播真实运行中（ack 确认且状态 RUNNING）。
  bool get isRunning => liveState == 'RUNNING' && ackConfirmed;
}

class LiveApi {
  final HttpClient _client;

  LiveApi(this._client);

  /// 拉取观看凭证（进房参数以响应值为准，不自报身份）。
  /// 注意：此调用有副作用（开启观看记录），不要用于入口显隐轮询。
  Future<Result<LiveCredential>> pullCredentials(String deviceId) async {
    try {
      final response = await _client.dio.post(
        ApiPaths.liveGet,
        queryParameters: ApiPaths.liveGetQuery(deviceId: deviceId),
      );
      return Result.fromJson(
        response.data as Map<String, dynamic>,
        (data) => LiveCredential.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return Result(
          success: data['success'] == true,
          code: data['code'] as int?,
          errorCode: data['errorCode'] as String?,
          message: data['message'] as String? ?? '获取直播凭证失败',
        );
      }
      return Result(success: false, message: '获取直播凭证失败，请检查网络');
    }
  }

  /// 结束当前用户在该设备的观看记录（t38④ dev-backend 定稿：仅补 end_time，
  /// 不动推流与直播状态，幂等）。用户正常退出观看时调用；
  /// 请求失败静默处理（异常退出由 LIVE_STOPPED 兜底补齐）。
  Future<void> leaveLive(String deviceId) async {
    try {
      await _client.dio.post(
        ApiPaths.liveLeave,
        queryParameters: ApiPaths.liveLeaveQuery(deviceId: deviceId),
      );
    } catch (_) {
      // 静默：leave 失败不影响退出流程，兜底由 LIVE_STOPPED 补齐
    }
  }
}
