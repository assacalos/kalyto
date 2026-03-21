import 'package:flutter/material.dart';

/// Un élément de la file "Urgence & Validations" du dashboard patron.
@immutable
class PatronValidationItem {
  final String entityType;
  final String entityId;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  const PatronValidationItem({
    required this.entityType,
    required this.entityId,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });
}
