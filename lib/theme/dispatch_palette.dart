import 'package:flutter/material.dart';

/// The same status accent is used by map pins, cards and tracking nodes.
class DispatchPalette {
  static Color status(BuildContext context, String? stage) {
    final color = switch (stage) {
      'AWAITING_DEPOSIT' => const Color(0xFFAF590C),
      'WAITING_ACCEPTANCE' => const Color(0xFF7851A9),
      'PILOT_PREPARING' => const Color(0xFF3565A6),
      'PILOT_ARRIVED' => const Color(0xFF147D7A),
      'IN_TRANSIT' => const Color(0xFFD95B00),
      'DELIVERY_CONFIRMATION' => const Color(0xFF875298),
      'COMPLETED' => const Color(0xFF22825B),
      _ => const Color(0xFF64748B),
    };
    return Theme.of(context).brightness == Brightness.dark
        ? Color.lerp(color, Colors.white, .42)!
        : color;
  }
}
