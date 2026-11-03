import 'package:flutter/material.dart';

class AppColors {
  // 主色调 - 深海蓝（品牌主色：稳重 · 安全 · 专业）
  static const Color primary = Color(0xFF1D6FE9);
  static const Color primaryLight = Color(0xFFE8F3FF);
  static const Color primaryDark = Color(0xFF153E88);

  // 强调色 - 工程橙（CTA / 选中态 / 强调：力量 · 行动）
  static const Color accent = Color(0xFFFF6B00);
  static const Color accentLight = Color(0xFFFFF0E6);
  static const Color accentDark = Color(0xFFFF6B00);

  // 表面色
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF7F8FA);

  // 文字色
  static const Color onSurface = Color(0xFF111111);
  static const Color onSurfaceVariant = Color(0xFF666666);

  // 边框色
  static const Color outline = Color(0xFF999999);
  static const Color outlineVariant = Color(0xFFCCCCCC);

  // 状态色
  static const Color success = Color(0xFF00B578);
  static const Color warning = Color(0xFFFF6B00);
  static const Color error = Color(0xFFEF4444);

  // 背景色
  static const Color background = Color(0xFFF3F4F6);
  static const Color cardBackground = Colors.white;

  // 订单状态色
  static const Color statusPending = Color(0xFFFFF0E6);
  static const Color statusPendingText = Color(0xFFFF6B00);
  static const Color statusInProgress = Color(0xFFE8F3FF);
  static const Color statusInProgressText = primary;
  static const Color statusCompleted = Color(0xFFE6F8F0);
  static const Color statusCompletedText = Color(0xFF00B578);
  static const Color statusCancelled = Color(0xFFFEF2F2);
  static const Color statusCancelledText = Color(0xFFEF4444);

  // ==================== 派生色 / 语义别名 ====================
  static const Color bgWhite = Colors.white;
  static const Color bgPage = Color(0xFFF3F4F6);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgInput = Color(0xFFF7F8FA);
  static const Color navBg = Color(0xFFFFFFFF);
  static const Color navActive = primary;
  static const Color navInactive = Color(0xFF999999);
  static const Color textPrimary = onSurface;
  static const Color divider = Color(0xFFF0F2F5);
  static const Color border = Color(0xFFF0F2F5);

  // 别名
  static const Color textSecondary = onSurfaceVariant;
  static const Color textHint = outline;
  static const Color badge = error;
  static const Color tagBlue = primary;
  static const Color tagBlueBg = primaryLight;
  static const Color danger = error;
}
