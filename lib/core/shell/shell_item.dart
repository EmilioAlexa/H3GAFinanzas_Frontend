import 'package:flutter/material.dart';

import '../../modules/auth/auth.dart';

enum ShellSection { general, seguimiento, finanzas, administracion }

class ShellItem {
  const ShellItem({
    required this.label,
    required this.path,
    required this.icon,
    required this.section,
    this.roles = const {},
  });

  final String label;
  final String path;
  final IconData icon;
  final ShellSection section;
  final Set<UserRole> roles;

  bool isVisibleFor(UserRole role) => roles.isEmpty || roles.contains(role);
}
