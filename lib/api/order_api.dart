// 订单与支付 API（t29：/order/list、/order/detail、/pay/{orderNum}，契约以 backend 为源）。

import 'package:dio/dio.dart';

import '../models/result_model.dart';
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
        return '未知状态';
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

  factory OrderVo.fromJson(Map<String, dynamic> json) {
    return OrderVo(
      orderNum: json['orderNum'] as String,
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      distance: (json['distance'] as num?)?.toDouble(),
      taskName: json['taskName'] as String?,
      orderStatus: (json['orderStatus'] as num?)?.toInt() ?? 0,
      deviceId: json['deviceId'] as String?,
      liveState: json['liveState'] as String?,
    );
  }

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
    return OrderListVo(
      orders: (json['orders'] as List<dynamic>? ?? const [])
          .map((e) => OrderVo.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
    );
  }
}

/// 支付结果（后端 PayResultVO：mock 态 prepayId 为 `mock-prepay-<orderNum>`）。
class PayResultVo {
  final String orderNum;
  final String? prepayId;
  final String? payUrl;

  const PayResultVo({
    required this.orderNum,
    this.prepayId,
    this.payUrl,
  });

  factory PayResultVo.fromJson(Map<String, dynamic> json) {
    return PayResultVo(
      orderNum: json['orderNum'] as String,
      prepayId: json['prepayId'] as String?,
      payUrl: json['payUrl'] as String?,
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
      '/order/list',
      queryParameters: {'page': page, 'size': size},
    );
    return Result.fromJson(
      response.data as Map<String, dynamic>,
      (data) => OrderListVo.fromJson(data as Map<String, dynamic>),
    );
  }

  /// 按订单号查询订单详情。
  Future<Result<OrderVo>> getOrderDetail(String orderNum) async {
    final response = await _client.dio.get(
      '/order/detail',
      queryParameters: {'orderNum': orderNum},
    );
    return Result.fromJson(
      response.data as Map<String, dynamic>,
      (data) => OrderVo.fromJson(data as Map<String, dynamic>),
    );
  }

  /// 发起支付（开发态走 t21 mock 通道，openid 可省略）。
  /// 后端业务失败以非 2xx 返回：此处捕获并映射为 Result 透传服务端 message。
  Future<Result<PayResultVo>> payOrder(String orderNum, {String? openid}) async {
    try {
      final response = await _client.dio.post(
        '/pay/$orderNum',
        queryParameters: openid != null ? {'openid': openid} : null,
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
