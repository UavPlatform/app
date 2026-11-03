import 'package:flutter/material.dart';

/// The same status accent is used by map pins, cards and tracking nodes.
class DispatchPalette {
  static Color status(BuildContext context, String? stage) {
    final color = switch (stage) {
      'AWAITING_DEPOSIT' => const Color(0xFFFF6B00),
      'WAITING_ACCEPTANCE' => const Color(0xFFFF6B00),
      'PILOT_PREPARING' => const Color(0xFF1D6FE9),
      'PILOT_ARRIVED' => const Color(0xFF1D6FE9),
      'IN_TRANSIT' => const Color(0xFF1D6FE9),
      'DELIVERY_CONFIRMATION' => const Color(0xFFFF6B00),
      'COMPLETED' => const Color(0xFF00B578),
      _ => const Color(0xFF888888),
    };
    return Theme.of(context).brightness == Brightness.dark
        ? Color.lerp(color, Colors.white, .42)!
        : color;
  }
}
