import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 任务发布草稿（本地 SharedPreferences 存储）
///
/// 自动保存：表单变化防抖 500ms 写入；提交成功后清除。
/// 恢复：进入发布页检测到草稿时提示恢复（可一键放弃）。
class TaskDraft {
  /// 服务类型名（与发布页 _serviceTypes 的 name 匹配）
  final String? serviceTypeName;

  /// yyyy-MM-dd
  final String? date;

  /// HH:mm
  final String? time;

  /// 航点串（'lat,lng;lat,lng...'）
  final String? waypointsStr;

  final String? description;
  final String? weight;
  final String? price;

  const TaskDraft({
    this.serviceTypeName,
    this.date,
    this.time,
    this.waypointsStr,
    this.description,
    this.weight,
    this.price,
  });

  bool get isEmpty =>
      (serviceTypeName ?? '').isEmpty &&
      (date ?? '').isEmpty &&
      (time ?? '').isEmpty &&
      (waypointsStr ?? '').isEmpty &&
      (description ?? '').trim().isEmpty &&
      (weight ?? '').isEmpty &&
      (price ?? '').isEmpty;

  factory TaskDraft.fromJson(Map<String, dynamic> json) {
    return TaskDraft(
      serviceTypeName: json['serviceTypeName'] as String?,
      date: json['date'] as String?,
      time: json['time'] as String?,
      waypointsStr: json['waypointsStr'] as String?,
      description: json['description'] as String?,
      weight: json['weight'] as String?,
      price: json['price'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serviceTypeName': serviceTypeName,
      'date': date,
      'time': time,
      'waypointsStr': waypointsStr,
      'description': description,
      'weight': weight,
      'price': price,
    };
  }
}

class TaskDraftService {
  static const _key = 'publish_task_draft';

  Future<TaskDraft?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return null;
      return TaskDraft.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(TaskDraft draft) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(draft.toJson()));
    } catch (_) {
      // 草稿写失败不影响主流程
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {
      // 忽略
    }
  }
}
