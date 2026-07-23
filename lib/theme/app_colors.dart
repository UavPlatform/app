import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ---- 主色 (蓝) ----
  static const Color primary = Color(0xFF2B6FF2);
  static const Color primaryLight = Color(0xFFEBF2FF);
  static const Color primaryDark = Color(0xFF1A4FBF);

  // ---- 背景 ----
  static const Color bgPage = Color(0xFFF5F6FA);
  static const Color bgWhite = Colors.white;
  static const Color bgCard = Colors.white;
  static const Color bgCardTinted = Color(0xFFF8F9FC);
  static const Color bgInput = Color(0xFFF3F4F7);

  // ---- 文字 ----
  static const Color textPrimary = Color(0xFF1A1C1E);
  static const Color textSecondary = Color(0xFF6F7378);
  static const Color textHint = Color(0xFFA1A5AA);

  // ---- 分割 / 边框 ----
  static const Color divider = Color(0xFFEEEEEE);
  static const Color dividerStrong = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFE5E6EB);

  // ---- 状态色 ----
  static const Color success = Color(0xFF1BAC4B);
  static const Color successBg = Color(0xFFE9F8EE);
  static const Color warning = Color(0xFFFF8F00);
  static const Color warningBg = Color(0xFFFFF5E6);
  static const Color danger = Color(0xFFF04343);
  static const Color dangerBg = Color(0xFFFFEDED);

  // ---- 标签 / 角标 ----
  static const Color badge = Color(0xFFF04343);
  static const Color tagBlue = Color(0xFF2B6FF2);
  static const Color tagBlueBg = Color(0xFFEBF2FF);
  static const Color tagOrange = Color(0xFFFF7A00);
  static const Color tagOrangeBg = Color(0xFFFFF1E6);
  static const Color tagGreen = Color(0xFF1BAC4B);
  static const Color tagGreenBg = Color(0xFFE9F8EE);

  // ---- 入口图标色 (四个服务) ----
  static const Color entryAerial = Color(0xFF4C8BF5);
  static const Color entryAerialBg = Color(0xFFEDF4FF);
  static const Color entrySurvey = Color(0xFF34B37C);
  static const Color entrySurveyBg = Color(0xFFEDF9F4);
  static const Color entryLogistics = Color(0xFFFF8C3D);
  static const Color entryLogisticsBg = Color(0xFFFFF3EB);
  static const Color entryMonitor = Color(0xFF6C5CE7);
  static const Color entryMonitorBg = Color(0xFFF2F0FF);

  // ---- 导航栏 ----
  static const Color navBg = Colors.white;
  static const Color navActive = Color(0xFF2B6FF2);
  static const Color navInactive = Color(0xFF999999);

  // ---- 兼容旧引用 ----
  static const Color onSurface = textPrimary;
  static const Color onSurfaceVariant = textSecondary;
  static const Color outline = textHint;
  static const Color outlineVariant = dividerStrong;
  static const Color surfaceVariant = bgInput;
  static const Color surface = bgCardTinted;
  static const Color background = bgPage;
  static const Color cardBackground = bgWhite;
  static const Color error = danger;
  static const Color statusPending = tagOrangeBg;
  static const Color statusPendingText = tagOrange;
  static const Color statusInProgress = tagBlueBg;
  static const Color statusInProgressText = tagBlue;
  static const Color statusCompleted = bgInput;
  static const Color statusCompletedText = textSecondary;
  static const Color statusCancelled = dangerBg;
  static const Color statusCancelledText = danger;
}
