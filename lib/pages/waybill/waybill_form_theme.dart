import 'package:flutter/material.dart';

// REQ-SHIP-PUB-002: restrained controls for the waybill form only.
ThemeData waybillFormTheme(ThemeData theme) {
  final colors = theme.colorScheme;
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(4));
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: color, width: width),
      );
  return theme.copyWith(
    inputDecorationTheme: theme.inputDecorationTheme.copyWith(
      filled: false,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: border(colors.outline),
      enabledBorder: border(colors.outlineVariant),
      focusedBorder: border(colors.primary, 1.5),
      errorBorder: border(colors.error),
      focusedErrorBorder: border(colors.error, 1.5),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: theme.outlinedButtonTheme.style?.copyWith(
        shape: WidgetStatePropertyAll(shape),
        backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: theme.filledButtonTheme.style?.copyWith(
        shape: WidgetStatePropertyAll(shape),
      ),
    ),
    chipTheme: theme.chipTheme.copyWith(
      shape: shape,
      backgroundColor: colors.surface,
      selectedColor: colors.primary.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    ),
  );
}
