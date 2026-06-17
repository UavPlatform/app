import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/service_type_model.dart';
import '../models/pilot_model.dart';
import '../models/order_model.dart';
import '../models/address_model.dart';
import '../models/message_model.dart';

class MockDataService {
  // 当前用户
  static User get currentUser => User(
    id: 'user_001',
    phone: '138****8888',
    nickname: '飞翼用户',
    balance: 5000.0,
    createdAt: DateTime(2024, 1, 1),
  );

  // 服务类型列表（4个）
  static List<ServiceType> get serviceTypes => [
    ServiceType(
      id: 'aerial_photo',
      name: '航拍摄影',
      icon: Icons.videocam,
      description: '活动跟拍/婚礼航拍/宣传片',
      avgPrice: 500,
      priceUnit: '元/次',
    ),
    ServiceType(
      id: 'survey',
      name: '测绘建模',
      icon: Icons.map,
      description: '地形测绘/3D建模',
      avgPrice: 1500,
      priceUnit: '元/平方公里',
    ),
    ServiceType(
      id: 'logistics',
      name: '物流吊运',
      icon: Icons.local_shipping,
      description: '物资吊运/设备转运',
      avgPrice: 800,
      priceUnit: '元/次',
    ),
    ServiceType(
      id: 'monitoring',
      name: '环境监测',
      icon: Icons.eco,
      description: '空气质量/水质监测',
      avgPrice: 600,
      priceUnit: '元/次',
    ),
  ];

  // 飞手列表
  static List<PilotInfo> get pilots => [
    PilotInfo(
      id: 'pilot_001',
      nickname: '张师傅',
      rating: 4.9,
      completedOrders: 326,
      serviceTypes: ['航拍摄影'],
      isVerified: true,
      introduction: '专注航拍5年，服务超过300位客户',
    ),
    PilotInfo(
      id: 'pilot_002',
      nickname: '李师傅',
      rating: 4.8,
      completedOrders: 215,
      serviceTypes: ['环境监测', '测绘建模'],
      isVerified: true,
      introduction: '环境监测专家，持证上岗',
    ),
    PilotInfo(
      id: 'pilot_003',
      nickname: '王师傅',
      rating: 4.7,
      completedOrders: 189,
      serviceTypes: ['测绘建模'],
      isVerified: true,
      introduction: '测绘行业10年经验',
    ),
    PilotInfo(
      id: 'pilot_004',
      nickname: '赵师傅',
      rating: 4.6,
      completedOrders: 156,
      serviceTypes: ['物流吊运'],
      isVerified: true,
      introduction: '物流吊运专家，安全高效',
    ),
    PilotInfo(
      id: 'pilot_005',
      nickname: '刘师傅',
      rating: 4.5,
      completedOrders: 98,
      serviceTypes: ['航拍摄影', '环境监测'],
      isVerified: false,
      introduction: '新手飞手，价格优惠',
    ),
  ];

  // 订单列表
  static List<Order> get orders => [
    Order(
      id: 'order_001',
      userId: 'user_001',
      serviceTypeId: 'aerial_photo',
      serviceTypeName: '航拍摄影',
      title: '婚礼现场航拍',
      description: '需要4K画质，拍摄时长约2小时，需要后期剪辑',
      location: '湖南省湘潭市雨湖区步步高广场',
      taskDate: DateTime.now().add(const Duration(days: 3)),
      budgetMin: 500,
      budgetMax: 1000,
      status: OrderStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Order(
      id: 'order_002',
      userId: 'user_001',
      serviceTypeId: 'survey',
      serviceTypeName: '测绘建模',
      title: '农田地形测绘',
      description: '约100亩农田地形测绘，生成3D模型',
      location: '湖南省湘潭市雨湖区姜畲镇',
      taskDate: DateTime.now().add(const Duration(days: 1)),
      budgetMin: 2000,
      budgetMax: 3000,
      status: OrderStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    Order(
      id: 'order_003',
      userId: 'user_001',
      serviceTypeId: 'logistics',
      serviceTypeName: '物流吊运',
      title: '建材吊运',
      description: '将建材从仓库吊运至5楼楼顶，约2吨',
      location: '湖南省湘潭市雨湖区建设路工地',
      taskDate: DateTime.now().subtract(const Duration(days: 1)),
      budgetMin: 800,
      budgetMax: 1200,
      finalPrice: 950,
      status: OrderStatus.inProgress,
      pilotId: 'pilot_004',
      pilotName: '赵师傅',
      pilotRating: 4.6,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Order(
      id: 'order_004',
      userId: 'user_001',
      serviceTypeId: 'aerial_photo',
      serviceTypeName: '航拍摄影',
      title: '楼盘宣传航拍',
      description: '新楼盘宣传片素材拍摄，需要全景和特写',
      location: '湖南省湘潭市雨湖区万达广场',
      taskDate: DateTime.now().subtract(const Duration(days: 3)),
      budgetMin: 1500,
      budgetMax: 2500,
      finalPrice: 2000,
      status: OrderStatus.inProgress,
      pilotId: 'pilot_001',
      pilotName: '张师傅',
      pilotRating: 4.9,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    Order(
      id: 'order_005',
      userId: 'user_001',
      serviceTypeId: 'monitoring',
      serviceTypeName: '环境监测',
      title: '河道水质监测',
      description: '湘江湘潭段水质监测，采样点5个',
      location: '湖南省湘潭市雨湖区湘江风光带',
      taskDate: DateTime.now().subtract(const Duration(days: 5)),
      budgetMin: 600,
      budgetMax: 1000,
      finalPrice: 800,
      status: OrderStatus.reviewing,
      pilotId: 'pilot_002',
      pilotName: '李师傅',
      pilotRating: 4.8,
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
    Order(
      id: 'order_006',
      userId: 'user_001',
      serviceTypeId: 'survey',
      serviceTypeName: '测绘建模',
      title: '学校操场测绘',
      description: '学校操场及周边地形测绘',
      location: '湖南省湘潭市雨湖区湘潭大学',
      taskDate: DateTime.now().subtract(const Duration(days: 10)),
      budgetMin: 1200,
      budgetMax: 1800,
      finalPrice: 1500,
      status: OrderStatus.completed,
      pilotId: 'pilot_003',
      pilotName: '王师傅',
      pilotRating: 4.7,
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
    ),
  ];

  // 地址列表
  static List<Address> get addresses => [
    Address(
      id: 'addr_001',
      label: '家',
      name: '张三',
      phone: '138****8888',
      province: '湖南省',
      city: '湘潭市',
      district: '雨湖区',
      detail: '建设路88号XX小区3号楼2单元501',
      isDefault: true,
    ),
    Address(
      id: 'addr_002',
      label: '公司',
      name: '张三',
      phone: '138****8888',
      province: '湖南省',
      city: '湘潭市',
      district: '雨湖区',
      detail: '步步高广场A座15层',
    ),
  ];

  // 消息列表
  static List<Message> get messages => [
    Message(
      id: 'msg_001',
      senderName: '系统通知',
      content: '您的任务"婚礼现场航拍"已发布成功，等待飞手接单',
      type: MessageType.system,
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    Message(
      id: 'msg_002',
      senderName: '张师傅',
      content: '您好，我已经到达拍摄现场，准备开始工作',
      type: MessageType.chat,
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
      orderId: 'order_004',
    ),
    Message(
      id: 'msg_003',
      senderName: '系统通知',
      content: '您的订单"建材吊运"已被赵师傅接单',
      type: MessageType.system,
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    Message(
      id: 'msg_004',
      senderName: '李师傅',
      content: '监测报告已生成，请查看',
      type: MessageType.chat,
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      orderId: 'order_005',
    ),
    Message(
      id: 'msg_005',
      senderName: '系统通知',
      content: '您的账号已通过实名认证',
      type: MessageType.system,
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
}
