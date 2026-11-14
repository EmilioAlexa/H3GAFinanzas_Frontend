import 'package:flutter/material.dart';

class AppDataColumn<T> {
  const AppDataColumn({
    required this.label,
    required this.value,
    this.showOnMedium = true,
    this.numeric = false,
    this.flex = 1,
  });

  final String label;
  final Widget Function(T row) value;
  final bool showOnMedium;
  final bool numeric;
  final int flex;
}
