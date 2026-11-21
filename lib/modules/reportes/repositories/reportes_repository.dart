import 'package:decimal/decimal.dart';

import '../../../core/network/finanzas_api.dart';
import '../fixtures/reportes_demo_fixtures.dart';
import '../models/report_data_model.dart';
import '../models/report_filters_model.dart';
import '../models/report_point_model.dart';
import '../models/report_row_model.dart';
import '../models/report_type_model.dart';

class ReportesRepository {
  const ReportesRepository({required this.demoMode, this.api});

  final bool demoMode;
  final FinanzasApi? api;

  Future<ReportDataModel> load(
      ReportType type, ReportFiltersModel filters) async {
    if (demoMode) return findDemo(type)!;
    final response = await api!.dio
        .get<dynamic>('/finanzas/reportes/${type.key}', queryParameters: {
      'fecha_desde': filters.from.toIso8601String().substring(0, 10),
      'fecha_hasta': filters.to.toIso8601String().substring(0, 10),
      'granularidad': filters.granularity.toLowerCase(),
      'comparar': filters.compare,
      if (filters.service != 'Todos los servicios') 'servicio': filters.service,
      if (filters.saleType != 'Todos los tipos') 'tipo_venta': filters.saleType,
      if (!filters.paymentMethod.startsWith('Todos'))
        'metodo_pago': filters.paymentMethod,
    });
    final body = apiMap(response.data);
    final summary = apiMap(body['resumen']);
    final comparison = apiMap(body['comparacion']);
    Decimal money(Object? value) =>
        Decimal.parse(apiText(value).isEmpty ? '0' : apiText(value));
    final rows = (body['datos'] as List).map(apiMap).toList();
    return ReportDataModel(
      type: type,
      serverCalculated: true,
      total: money(summary['total']),
      personalTotal: money(summary['total_personas']),
      variation: comparison['variacion_porcentual'] == null
          ? null
          : money(comparison['variacion_porcentual']),
      comparisonTotal: comparison['total_anterior'] == null
          ? null
          : money(comparison['total_anterior']),
      rows: [
        for (final r in rows)
          ReportRowModel(
            title: apiText(r['destino'] ??
                r['tipo_venta'] ??
                r['metodo_pago'] ??
                r['contrato'] ??
                r['periodo']),
            subtitle: apiText(r['beneficiario'] ?? r['periodo']),
            service: r['servicio']?.toString(),
            amount: money(r['monto_comision'] ?? r['monto']),
            count: (r['cantidad_pagos'] as num?)?.toInt(),
            percentage: r['porcentaje_del_total'] == null
                ? null
                : money(r['porcentaje_del_total']),
            status: r['estado_comision']?.toString(),
          )
      ],
      points: type == ReportType.ingresos
          ? [
              for (final r in rows)
                ReportPointModel(
                    label: apiText(r['periodo']), amount: money(r['monto']))
            ]
          : [],
      serviceBreakdown: [
        for (final r in (body['por_servicio'] as List? ?? []).map(apiMap))
          ReportRowModel(
              title: apiText(r['servicio']),
              amount: money(r['monto']),
              percentage: money(r['porcentaje']))
      ],
    );
  }

  List<ReportDataModel> listDemo() =>
      List.unmodifiable(ReportesDemoFixtures.reports.values);

  ReportDataModel? findDemo(ReportType type) =>
      ReportesDemoFixtures.reports[type];
}
