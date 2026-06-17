import 'package:flutter/material.dart';

class ServiceType {
  final String id;
  final String name;
  final IconData icon;
  final String description;
  final double? avgPrice;
  final String? priceUnit;

  ServiceType({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    this.avgPrice,
    this.priceUnit,
  });
}
