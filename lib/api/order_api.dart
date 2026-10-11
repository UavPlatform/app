// 订单与支付 API（t29：/order/list、/order/detail、/pay/{orderNum}，契约以 backend 为源）。

import 'package:dio/dio.dart';

import '../models/result_model.dart';
import 'generated/openapi_models.dart';
import 'generated/openapi_paths.dart';
import 'http_client.dart';

/// 订单状态码（后端 OrderStatus 枚举 code，t29 契约）。
class OrderStatusCode {
  static const int pending = 0;
  static const int paid = 1;
  static const int cancelled = 2;
  static const int refunded = 3;
  static const int completed = 4;
  static const int waitingConfirm = 5;

  /// 状态中文标签（WAITING_CONFIRM 按验收口径展示为「待验收」）。
  static String labelOf(int code) {
    switch (code) {
      case pending:
        return '待支付';
      case paid:
        return '已支付';
      case cancelled:
        return '已取消';
      case refunded:
        return '已退款';
      case completed:
        return '已完成';
      case waitingConfirm:
        return '待验收';
      default:
        return '状态待确认';
    }
  }
}

/// 订单视图对象（后端 OrderVO：orderNum/totalAmount/distance/taskName/orderStatus）。
class OrderVo {
  final String orderNum;
  final double? totalAmount;
  final double? distance;
  final String? taskName;
  final int orderStatus;

  /// 任务关联的作业设备与直播态（t41 富化字段，宽容可空）
  final String? deviceId;
  final String? liveState;

  const OrderVo({
    required this.orderNum,
    this.totalAmount,
    this.distance,
    this.taskName,
    required this.orderStatus,
    this.deviceId,
    this.liveState,
  });

  /// 字段直取契约类（ApiOrderVO）：契约重命名/删除字段时此处编译失败。
  factory OrderVo.fromApi(ApiOrderVO c) {
    return OrderVo(
      orderNum: c.orderNum as String,
      totalAmount: c.totalAmount,
      distance: c.distance,
      taskName: c.taskName,
      orderStatus: c.orderStatus ?? -1,
      deviceId: c.deviceId,
      liveState: c.liveState,
    );
  }

  factory OrderVo.fromJson(Map<String, dynamic> json) =>
      OrderVo.fromApi(ApiOrderVO.fromJson(json));

  bool get isPending => orderStatus == OrderStatusCode.pending;
  String get statusLabel => OrderStatusCode.labelOf(orderStatus);
}

/// 订单分页对象（后端 OrderListVO）。
class OrderListVo {
  final List<OrderVo> orders;
  final int currentPage;
  final int totalPages;
  final int totalElements;

  const OrderListVo({
    required this.orders,
    required this.currentPage,
    required this.totalPages,
    required this.totalElements,
  });

  factory OrderListVo.fromJson(Map<String, dynamic> json) {
    final c = ApiOrderListVO.fromJson(json);
    return OrderListVo(
      orders: (c.orders ?? const <ApiOrderVO>[]).map(OrderVo.fromApi).toList(),
      currentPage: c.currentPage ?? 0,
      totalPages: c.totalPages ?? 0,
      totalElements: c.totalElements ?? 0,
    );
  }
}

/// 支付结果（后端 PayResultVO：mock 态 prepayId 为 `mock-prepay-<orderNum>`）。
class PayResultVo {
  final String orderNum;
  final String? prepayId;
  final String? payUrl;

  const PayResultVo({required this.orderNum, this.prepayId, this.payUrl});

  factory PayResultVo.fromJson(Map<String, dynamic> json) {
    final c = ApiPayResultVO.fromJson(json);
    return PayResultVo(
      orderNum: c.orderNum as String,
      prepayId: c.prepayId,
      payUrl: c.payUrl,
    );
  }
}

/// 订单/支付接口（JWT）。
class OrderApi {
  final HttpClient _client;

  OrderApi(this._client);

  /// 当前用户订单列表，按创建时间倒序。
  Future<Result<OrderListVo>> listOrders({int page = 0, int size = 20}) async {
    final response = await _client.dio.get(
      ApiPaths.orderList,
      queryParameters: ApiPaths.orderListQuery(page: page, size: size),
    );
    return Result.fromJson(
      response.data as Map<String, dynamic>,
      (data) => OrderListVo.fromJson(data as Map<String, dynamic>),
    );
  }

  /// 按订单号查询订单详情。
  Future<Result<OrderVo>> getOrderDetail(String orderNum) async {
    final response = await _client.dio.get(
      ApiPaths.orderDetail,
      queryParameters: ApiPaths.orderDetailQuery(orderNum: orderNum),
    );
    return Result.fromJson(
      response.data as Map<String, dynamic>,
      (data) => OrderVo.fromJson(data as Map<String, dynamic>),
    );
  }

  /// 发起支付（开发态走 t21 mock 通道，openid 可省略）。
  /// 后端业务失败以非 2xx 返回：此处捕获并映射为 Result 透传服务端 message。
  Future<Result<PayResultVo>> payOrder(
    String orderNum, {
    String? openid,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiPaths.payPath(orderNum),
        queryParameters: openid != null
            ? ApiPaths.payQuery(openid: openid)
            : null,
        options: Options(contentType: 'application/json'),
      );
      return Result.fromJson(
        response.data as Map<String, dynamic>,
        (data) => PayResultVo.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return Result(
          success: data['success'] == true,
          code: data['code'] as int?,
          message: data['message'] as String? ?? '支付失败，请稍后重试',
        );
      }
      return Result(success: false, message: '支付失败，请稍后重试');
    }
  }
}
