import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shared by direct route selection and the legacy site editor.
Future<Map<String, String>?> pickWaybillLocation(
  BuildContext context,
  String prefix,
) async {
  final result = await context.push<String>(
    prefix == 'start' ? '/map/pick?point=start' : '/map/pick',
  );
  if (!context.mounted || result == null) return null;
  final parts = result.split(';');
  final coordinates = parts.first.split(',');
  if (coordinates.length != 2) return null;
  final lat = double.tryParse(coordinates[0]);
  final lng = double.tryParse(coordinates[1]);
  if (lat == null ||
      lng == null ||
      !lat.isFinite ||
      !lng.isFinite ||
      lat < -90 ||
      lat > 90 ||
      lng < -180 ||
      lng > 180) {
    return null;
  }
  return {
    '$prefix.lat': coordinates[0].trim(),
    '$prefix.lng': coordinates[1].trim(),
    '$prefix.place': parts.length > 1 ? parts[1] : '',
    '$prefix.placeAddress': parts.length > 2 ? parts.sublist(2).join(';') : '',
  };
}
