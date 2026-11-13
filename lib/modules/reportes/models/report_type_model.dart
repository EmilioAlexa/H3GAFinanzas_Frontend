import 'package:flutter/material.dart';

enum ReportType {
  ingresos('ingresos', 'Ingresos por periodo',
      'Semanal, mensual, anual y comparativos', Icons.show_chart_outlined),
  comisionesDestino('comisiones-destino', 'Comisiones por destino/beneficiario',
      'Destino, receptor, importe y dispersión', Icons.work_outline),
  comisionesTipoVenta('comisiones-tipo-venta', 'Comisiones por tipo de venta',
      'Comisiones agrupadas por tipo', Icons.description_outlined),
  imss('imss', 'Pagos al IMSS', 'Importes por contrato y estado',
      Icons.access_time),
  pagosMetodo('pagos-metodo', 'Pagos por método',
      'Transferencia, depósito y efectivo', Icons.credit_card_outlined);

  const ReportType(this.key, this.title, this.description, this.icon);

  final String key;
  final String title;
  final String description;
  final IconData icon;

  static ReportType? fromKey(String? key) {
    for (final type in values) {
      if (type.key == key) return type;
    }
    return null;
  }
}
