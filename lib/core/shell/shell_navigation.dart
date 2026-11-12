import 'package:flutter/material.dart';

import '../../modules/auth/auth.dart';
import 'shell_item.dart';

const shellItems = <ShellItem>[
  ShellItem(
    label: 'Inicio',
    path: '/dashboard',
    icon: Icons.home_outlined,
    section: ShellSection.general,
  ),
  ShellItem(
    label: 'Clientes',
    path: '/clientes',
    icon: Icons.people_outline,
    section: ShellSection.general,
  ),
  ShellItem(
    label: 'Servicios',
    path: '/servicios',
    icon: Icons.business_center_outlined,
    section: ShellSection.general,
  ),
  ShellItem(
    label: 'Contratos',
    path: '/contratos',
    icon: Icons.description_outlined,
    section: ShellSection.general,
  ),
  ShellItem(
    label: 'Pagos',
    path: '/pagos',
    icon: Icons.credit_card_outlined,
    section: ShellSection.finanzas,
  ),
  ShellItem(
    label: 'Validación',
    path: '/validacion',
    icon: Icons.fact_check_outlined,
    section: ShellSection.finanzas,
    roles: {UserRole.administrador, UserRole.administradorFinanciero},
  ),
  ShellItem(
    label: 'Comisiones',
    path: '/comisiones',
    icon: Icons.bar_chart_outlined,
    section: ShellSection.finanzas,
  ),
  ShellItem(
    label: 'Cortes',
    path: '/cortes',
    icon: Icons.calendar_month_outlined,
    section: ShellSection.finanzas,
    roles: {UserRole.administrador, UserRole.administradorFinanciero},
  ),
  ShellItem(
    label: 'Prenómina',
    path: '/prenomina',
    icon: Icons.receipt_long_outlined,
    section: ShellSection.finanzas,
    roles: {UserRole.administrador, UserRole.administradorFinanciero},
  ),
  ShellItem(
    label: 'Reportes',
    path: '/reportes',
    icon: Icons.insert_chart_outlined,
    section: ShellSection.finanzas,
    roles: {UserRole.administrador, UserRole.administradorFinanciero},
  ),
  ShellItem(
    label: 'Usuarios y accesos',
    path: '/usuarios',
    icon: Icons.manage_accounts_outlined,
    section: ShellSection.administracion,
    roles: {UserRole.administrador},
  ),
];

List<ShellItem> visibleShellItems(UserRole role) =>
    shellItems.where((item) => item.isVisibleFor(role)).toList();

Set<UserRole> allowedRolesForRoute(String path) => switch (path) {
      '/validacion' || '/cortes' || '/prenomina' || '/reportes' => {
          UserRole.administrador,
          UserRole.administradorFinanciero,
        },
      '/usuarios' => {UserRole.administrador},
      _ => {},
    };
