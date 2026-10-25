import 'package:flutter/material.dart';

class AppColors {
  // 主色调 - 深海蓝（品牌主色：稳重 · 安全 · 专业）
  static const Color primary = Color(0xFF205DCD);
  static const Color primaryLight = Color(0xFFE3EFFF);
  static const Color primaryDark = Color(0xFF153E88);

  // 强调色 - 工程橙（CTA / 选中态 / 强调：力量 · 行动）
  static const Color accent = Color(0xFFF57C00);
  static const Color accentLight = Color(0xFFFFE0B2);
  static const Color accentDark = Color(0xFFE65100);

  // 表面色
  static const Color surface = Color(0xFFFFFEFB);
  static const Color surfaceVariant = Color(0xFFE7EEF6);

  // 文字色
  static const Color onSurface = Color(0xFF1A1C1E);
  static const Color onSurfaceVariant = Color(0xFF44474F);

  // 边框色
  static const Color outline = Color(0xFF74777F);
  static const Color outlineVariant = Color(0xFFC4C6D0);

  // 状态色
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFE65100);
  static const Color error = Color(0xFFBA1A1A);

  // 背景色
  static const Color background = Color(0xFFF5F5F5);
  static const Color cardBackground = Colors.white;

  // 订单状态色
  static const Color statusPending = Color(0xFFFFF3E0);
  static const Color statusPendingText = Color(0xFFE65100);
  static const Color statusInProgress = Color(0xFFE8F5E9);
  static const Color statusInProgressText = Color(0xFF2E7D32);
  static const Color statusCompleted = Color(0xFFECEFF1);
  static const Color statusCompletedText = Color(0xFF546E7A);
  static const Color statusCancelled = Color(0xFFFFEBEE);
  static const Color statusCancelledText = Color(0xFFC62828);

  // ==================== 派生色 / 语义别名 ====================
  static const Color bgWhite = Colors.white;
  static const Color bgPage = Color(0xFFF6F4EF);
  static const Color bgCard = Color(0xFFFFFEFB);
  static const Color bgInput = Color(0xFFF3F4F7);
  static const Color navBg = Color(0xFFFFFEFB);
  static const Color navActive = primary;
  static const Color navInactive = Color(0xFF999999);
  static const Color textPrimary = onSurface;
  static const Color divider = Color(0xFFEEEEEE);
  static const Color border = Color(0xFFE5E1D9);

  // 别名
  static const Color textSecondary = onSurfaceVariant;
  static const Color textHint = outline;
  static const Color badge = error;
  static const Color tagBlue = primary;
  static const Color tagBlueBg = primaryLight;
  static const Color danger = error;
}
