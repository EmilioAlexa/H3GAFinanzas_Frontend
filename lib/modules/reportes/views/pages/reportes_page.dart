import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/demo/demo_mode_banner.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/responsive/window_size_class.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_data_column.dart';
import '../../../../core/widgets/app_metric_card.dart';
import '../../../../core/widgets/app_notice.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_responsive_collection.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../controllers/reportes_controller.dart';
import '../../fixtures/reportes_demo_fixtures.dart';
import '../../models/report_data_model.dart';
import '../../models/report_filters_model.dart';
import '../../models/report_point_model.dart';
import '../../models/report_row_model.dart';
import '../../models/report_type_model.dart';

class ReportesPage extends ConsumerWidget {
  const ReportesPage({this.reportType, super.key});

  final ReportType? reportType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(reportesRepositoryProvider);
    if (!repository.demoMode) {
      return const AppStatePanel(
        icon: Icons.link_off_outlined,
        title: 'Reportes sin conectar',
        message:
            'La integración con los cinco endpoints GET /finanzas/reportes se realizará en B10.',
      );
    }
    final filters = ref.watch(reportesControllerProvider);
    if (reportType == null) {
      return _ReportOverview(filters: filters, reports: repository.listDemo());
    }
    final report = repository.findDemo(reportType!);
    if (report == null) {
      return const AppStatePanel(
        icon: Icons.search_off_outlined,
        title: 'Reporte no disponible',
        message: 'Vuelve al inicio de reportes.',
      );
    }
    return _ReportDetail(report: report, filters: filters);
  }
}

class _ReportOverview extends ConsumerWidget {
  const _ReportOverview({required this.filters, required this.reports});

  final ReportFiltersModel filters;
  final List<ReportDataModel> reports;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final income = ReportesDemoFixtures.reports[ReportType.ingresos]!;
    final imss = ReportesDemoFixtures.reports[ReportType.imss]!;
    final commissions =
        ReportesDemoFixtures.reports[ReportType.comisionesDestino]!;
    final variation = _variation(income.total, income.comparisonTotal!);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const AppPageHeader(
          eyebrow: 'Análisis financiero',
          title: 'Reportes',
          description:
              'Información calculada para consulta y toma de decisiones.',
        ),
        const DemoModeBanner(),
        const SizedBox(height: AppTheme.space3),
        const AppNotice(
          type: AppNoticeType.warning,
          text:
              'Cifras de demostración. Los filtros son ilustrativos y no representan datos financieros reales.',
        ),
        const SizedBox(height: AppTheme.space4),
        _ReportFilters(reportType: null, filters: filters),
        const SizedBox(height: AppTheme.space4),
        LayoutBuilder(builder: (context, constraints) {
          final cards = [
            AppMetricCard(
              label:
                  'Ingresos validados · ${filters.granularity.toLowerCase()}',
              value: _compactMoney(income.total),
              detail: 'Últimas 8 semanas (demo)',
              icon: Icons.show_chart_outlined,
            ),
            AppMetricCard(
              label: 'Variación',
              value:
                  '${variation >= Decimal.zero ? '+' : ''}${variation.toStringAsFixed(1)}%',
              detail: 'vs. periodo anterior (demo)',
              icon: Icons.trending_up,
              tone: AppMetricTone.info,
            ),
            AppMetricCard(
              label: 'Pagos al IMSS (muestra)',
              value: MoneyFormatter.format(imss.total),
              detail: 'M10, M40 y M40 Retroactiva',
              icon: Icons.access_time,
              tone: AppMetricTone.warning,
            ),
            AppMetricCard(
              label: 'Comisiones a personas',
              value: MoneyFormatter.format(_personalCommissions(commissions)),
              detail: 'Solo muestra ficticia',
              icon: Icons.work_outline,
              tone: AppMetricTone.accent,
            ),
          ];
          if (Responsive.isCompact(constraints.maxWidth)) {
            return Column(children: [
              for (final card in cards) ...[
                card,
                const SizedBox(height: AppTheme.space3),
              ],
            ]);
          }
          return Wrap(
            spacing: AppTheme.space3,
            runSpacing: AppTheme.space3,
            children: [
              for (final card in cards)
                SizedBox(
                  width: (constraints.maxWidth - AppTheme.space3) / 2,
                  child: card,
                ),
            ],
          );
        }),
        const SizedBox(height: AppTheme.space4),
        LayoutBuilder(builder: (context, constraints) {
          final chart = _panel(
            context,
            title: 'Ingresos validados por periodo',
            subtitle: '${filters.granularity} · pagos validados · muestra',
            child: _incomeChart(
              context,
              income,
              filters.compare,
              filters.granularity,
            ),
          );
          final service = _panel(
            context,
            title: 'Distribución por servicio',
            subtitle: 'Ingresos de la muestra',
            child: _serviceChart(context, income),
          );
          if (!Responsive.isExpanded(constraints.maxWidth)) {
            return Column(children: [
              chart,
              const SizedBox(height: AppTheme.space4),
              service,
            ]);
          }
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 3, child: chart),
            const SizedBox(width: AppTheme.space4),
            Expanded(flex: 2, child: service),
          ]);
        }),
        const SizedBox(height: AppTheme.space4),
        _commissionStrip(context, commissions),
        const SizedBox(height: AppTheme.space4),
        _reportLinks(context, reports),
      ]),
    );
  }
}

class _ReportDetail extends ConsumerWidget {
  const _ReportDetail({required this.report, required this.filters});

  final ReportDataModel report;
  final ReportFiltersModel filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = _filteredRows(report, filters);
    final total = rows.fold(Decimal.zero, (sum, row) => sum + row.amount);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => context.go('/reportes'),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Reportes'),
          ),
        ),
        AppPageHeader(
          eyebrow: 'Análisis financiero · demostración',
          title: report.type.title,
          description: report.type.description,
        ),
        const DemoModeBanner(),
        const SizedBox(height: AppTheme.space3),
        const AppNotice(
          type: AppNoticeType.warning,
          text:
              'Los importes son ficticios. Al integrar B10, los resultados vendrán de pagos y comisiones del backend.',
        ),
        const SizedBox(height: AppTheme.space4),
        _ReportFilters(reportType: report.type, filters: filters),
        const SizedBox(height: AppTheme.space4),
        LayoutBuilder(builder: (context, constraints) {
          final metric = AppMetricCard(
            label: _totalLabel(report.type),
            value: MoneyFormatter.format(total),
            detail: '${rows.length} filas visibles · demo',
            icon: report.type.icon,
          );
          final variation = AppMetricCard(
            label: 'Variación',
            value: filters.compare && report.comparisonTotal != null
                ? '${_variation(report.total, report.comparisonTotal!).toStringAsFixed(1)}%'
                : 'Sin comparar',
            detail: 'Periodo anterior de igual duración',
            icon: Icons.compare_arrows,
            tone: AppMetricTone.info,
          );
          if (Responsive.isCompact(constraints.maxWidth)) {
            return Column(children: [
              metric,
              const SizedBox(height: AppTheme.space3),
              variation
            ]);
          }
          return Row(children: [
            Expanded(child: metric),
            const SizedBox(width: AppTheme.space3),
            Expanded(child: variation),
          ]);
        }),
        const SizedBox(height: AppTheme.space4),
        if (report.type == ReportType.ingresos)
          _panel(
            context,
            title: 'Ingresos validados por periodo',
            subtitle: 'Totales de muestra · solo pagos validados',
            child: _incomeChart(
              context,
              report,
              filters.compare,
              filters.granularity,
            ),
          )
        else if (report.type == ReportType.imss)
          _imssNotice(context)
        else if (report.type == ReportType.comisionesDestino)
          _commissionStrip(context, report),
        const SizedBox(height: AppTheme.space4),
        _detailTable(context, report.type, rows),
      ]),
    );
  }
}

class _ReportFilters extends ConsumerWidget {
  const _ReportFilters({required this.reportType, required this.filters});

  final ReportType? reportType;
  final ReportFiltersModel filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(reportesControllerProvider.notifier);
    final showSaleType = reportType == ReportType.comisionesTipoVenta;
    final showMethod = reportType == ReportType.pagosMetodo;
    return Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(
          spacing: AppTheme.space3,
          runSpacing: AppTheme.space3,
          children: [
            _dateFilter(context,
                label: 'Desde',
                value: filters.from,
                onChanged: controller.setFrom),
            _dateFilter(context,
                label: 'Hasta', value: filters.to, onChanged: controller.setTo),
            SizedBox(
              width: 210,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: filters.granularity,
                decoration:
                    const InputDecoration(labelText: 'Periodo', isDense: true),
                items: const ['Semanal', 'Mensual', 'Anual']
                    .map((item) =>
                        DropdownMenuItem(value: item, child: Text(item)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) controller.setGranularity(value);
                },
              ),
            ),
            if (showSaleType)
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: filters.saleType,
                  decoration: const InputDecoration(
                      labelText: 'Tipo de venta', isDense: true),
                  items: const [
                    'Todos los tipos',
                    'Cambaceo',
                    'Marketing',
                    'Referidor',
                    'Bróker',
                    'Sin tipo de venta registrado',
                  ]
                      .map((item) =>
                          DropdownMenuItem(value: item, child: Text(item)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) controller.setSaleType(value);
                  },
                ),
              ),
            if (showMethod)
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: filters.paymentMethod,
                  decoration: const InputDecoration(
                      labelText: 'Método de pago', isDense: true),
                  items: const [
                    'Todos los métodos',
                    'Transferencia',
                    'Depósito',
                    'Efectivo'
                  ]
                      .map((item) =>
                          DropdownMenuItem(value: item, child: Text(item)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) controller.setPaymentMethod(value);
                  },
                ),
              ),
          ],
        ),
        const SizedBox(height: AppTheme.space2),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppTheme.space3,
          runSpacing: AppTheme.space2,
          children: [
            SizedBox(
              width: 210,
              child: Material(
                color: AppTheme.surface,
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Comparar periodo anterior'),
                  value: filters.compare,
                  onChanged: controller.setCompare,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                controller.apply();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Filtros aplicados a la vista demo.')),
                );
              },
              icon: const Icon(Icons.tune),
              label: const Text('Aplicar filtros'),
            ),
          ],
        ),
        if (filters.applied) ...[
          const SizedBox(height: AppTheme.space2),
          const AppNotice(
            type: AppNoticeType.success,
            text:
                'Filtros aplicados. Las cifras visibles siguen siendo fixtures de demostración.',
          ),
        ],
        if (reportType == null)
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.space2),
            child: Text(
              'El filtro Servicio del prototipo no se muestra: ningún endpoint de reportes lo admite.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.muted),
            ),
          ),
      ]),
    );
  }

  Widget _dateFilter(
    BuildContext context, {
    required String label,
    required DateTime value,
    required ValueChanged<DateTime> onChanged,
  }) =>
      SizedBox(
        width: 190,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(190, 54),
            alignment: Alignment.centerLeft,
          ),
          onPressed: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: value,
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
              helpText: 'Selecciona fecha $label',
            );
            if (date != null) onChanged(date);
          },
          icon: const Icon(Icons.calendar_month_outlined),
          label: Text('$label: ${MoneyFormatter.formatDate(value)}'),
        ),
      );
}

Widget _detailTable(
    BuildContext context, ReportType type, List<ReportRowModel> rows) {
  final columns = switch (type) {
    ReportType.comisionesDestino => <AppDataColumn<ReportRowModel>>[
        AppDataColumn(label: 'Destino', value: (row) => Text(row.title)),
        AppDataColumn(
            label: 'Beneficiario', value: (row) => Text(row.subtitle ?? '—')),
        AppDataColumn(
            label: 'Movimientos',
            numeric: true,
            value: (row) => Text('${row.count ?? 0}')),
        AppDataColumn(
            label: 'Importe',
            numeric: true,
            value: (row) => Text(MoneyFormatter.format(row.amount))),
        AppDataColumn(
            label: '% del total',
            numeric: true,
            showOnMedium: false,
            value: (row) => Text('${row.percentage ?? Decimal.zero}%')),
        AppDataColumn(
            label: 'Estado',
            showOnMedium: false,
            value: (row) => _statusBadge(row.status ?? 'Referencial')),
      ],
    ReportType.comisionesTipoVenta => <AppDataColumn<ReportRowModel>>[
        AppDataColumn(label: 'Tipo de venta', value: (row) => Text(row.title)),
        AppDataColumn(
            label: 'Ventas',
            numeric: true,
            value: (row) => Text('${row.count ?? 0}')),
        AppDataColumn(
            label: '% promedio asesor',
            numeric: true,
            showOnMedium: false,
            value: (row) =>
                Text(row.average == null ? '—' : '${row.average}%')),
        AppDataColumn(
            label: 'Comisiones',
            numeric: true,
            value: (row) => Text(MoneyFormatter.format(row.amount))),
      ],
    ReportType.imss => <AppDataColumn<ReportRowModel>>[
        AppDataColumn(
            label: 'Contrato / pago',
            value: (row) =>
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(row.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(row.subtitle ?? '',
                      style: Theme.of(context).textTheme.bodySmall)
                ])),
        AppDataColumn(
            label: 'Servicio', value: (row) => Text(row.service ?? '—')),
        AppDataColumn(
            label: 'Porcentaje',
            numeric: true,
            showOnMedium: false,
            value: (row) => Text('${row.percentage ?? Decimal.zero}%')),
        AppDataColumn(
            label: 'Importe',
            numeric: true,
            value: (row) => Text(MoneyFormatter.format(row.amount))),
        AppDataColumn(
            label: 'Estado',
            value: (row) => _statusBadge(row.status ?? 'Otro estado')),
      ],
    ReportType.pagosMetodo => <AppDataColumn<ReportRowModel>>[
        AppDataColumn(label: 'Método', value: (row) => Text(row.title)),
        AppDataColumn(
            label: 'Pagos',
            numeric: true,
            value: (row) => Text('${row.count ?? 0}')),
        AppDataColumn(
            label: 'Monto',
            numeric: true,
            value: (row) => Text(MoneyFormatter.format(row.amount))),
        AppDataColumn(
            label: '% del total',
            numeric: true,
            showOnMedium: false,
            value: (row) => Text('${row.percentage ?? Decimal.zero}%')),
      ],
    ReportType.ingresos => <AppDataColumn<ReportRowModel>>[
        AppDataColumn(label: 'Periodo', value: (row) => Text(row.title)),
        AppDataColumn(
            label: 'Importe',
            numeric: true,
            value: (row) => Text(MoneyFormatter.format(row.amount))),
        AppDataColumn(
            label: '% del total',
            numeric: true,
            value: (row) => Text('${row.percentage ?? Decimal.zero}%')),
      ],
  };
  return _panel(
    context,
    title: _tableTitle(type),
    subtitle: _tableSubtitle(type),
    child: AppResponsiveCollection<ReportRowModel>(
      rows: rows,
      columns: columns,
      compactCardBuilder: (context, row) => _rowCard(context, type, row),
      emptyTitle: 'Sin resultados demo',
      emptyMessage: 'No hay registros para los filtros seleccionados.',
    ),
  );
}

Widget _rowCard(BuildContext context, ReportType type, ReportRowModel row) =>
    Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.line),
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(row.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        if (row.subtitle != null) Text(row.subtitle!),
        if (row.service != null) Text(row.service!),
        if (row.count != null) Text('${_countLabel(type)}: ${row.count}'),
        const SizedBox(height: AppTheme.space2),
        Row(children: [
          Expanded(
              child: Text(MoneyFormatter.format(row.amount),
                  style: const TextStyle(fontWeight: FontWeight.w700))),
          if (row.percentage != null) Text('${row.percentage}%'),
        ]),
        if (row.average != null) Text('Promedio asesor: ${row.average}%'),
        if (row.status != null) ...[
          const SizedBox(height: AppTheme.space2),
          _statusBadge(row.status!),
        ],
      ]),
    );

Widget _incomeChart(BuildContext context, ReportDataModel report, bool compare,
    String granularity) {
  final points = _pointsForGranularity(report.points, granularity);
  final maxAmount = points
          .map((point) => point.amount.toDouble())
          .fold<double>(0, (a, b) => a > b ? a : b) *
      1.2;
  return Semantics(
    label:
        'Ingresos de muestra por periodo: ${points.map((point) => '${point.label}, ${MoneyFormatter.format(point.amount)}').join('; ')}',
    child: SizedBox(
      height: 240,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          minY: 0,
          maxY: maxAmount,
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: points.length > 5 ? 2 : 1,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: AppTheme.space2),
                    child: Text(points[index].label,
                        style: Theme.of(context).textTheme.labelSmall),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i].amount.toDouble())
              ],
              isCurved: true,
              color: AppTheme.primary,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                  show: true, color: AppTheme.secondary.withValues(alpha: .16)),
            ),
            if (compare && report.comparisonTotal != null)
              LineChartBarData(
                spots: [
                  for (var i = 0; i < points.length; i++)
                    FlSpot(
                        i.toDouble(),
                        (report.comparisonTotal!.toDouble() / points.length) *
                            (0.86 + (i % 3) * .04))
                ],
                isCurved: true,
                color: AppTheme.infoBase,
                barWidth: 2,
                dashArray: [5, 4],
                dotData: const FlDotData(show: false),
              ),
          ],
          lineTouchData: const LineTouchData(enabled: false),
        ),
      ),
    ),
  );
}

Widget _serviceChart(BuildContext context, ReportDataModel report) {
  const colors = [
    AppTheme.primary,
    AppTheme.secondary,
    AppTheme.infoBase,
    AppTheme.gold
  ];
  final sections = [
    for (var i = 0; i < report.serviceBreakdown.length; i++)
      PieChartSectionData(
        value: report.serviceBreakdown[i].amount.toDouble(),
        color: colors[i % colors.length],
        radius: 42,
        showTitle: false,
      ),
  ];
  return Column(children: [
    SizedBox(
      height: 170,
      child: PieChart(PieChartData(
          sections: sections, centerSpaceRadius: 42, sectionsSpace: 2)),
    ),
    for (var i = 0; i < report.serviceBreakdown.length; i++)
      Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space1),
        child: Row(children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: colors[i % colors.length],
                  borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: AppTheme.space2),
          Expanded(child: Text(report.serviceBreakdown[i].title)),
          Text('${report.serviceBreakdown[i].percentage}%'),
        ]),
      ),
  ]);
}

Widget _commissionStrip(BuildContext context, ReportDataModel report) => _panel(
      context,
      title: 'Distribución por destino',
      subtitle:
          '${report.rows.length} destinos · ${MoneyFormatter.format(report.total)} · muestra demo',
      child: LayoutBuilder(builder: (context, constraints) {
        final size = Responsive.classify(constraints.maxWidth);
        final columns = switch (size) {
          WindowSizeClass.compacto => 2,
          WindowSizeClass.medio => 3,
          WindowSizeClass.expandido => 5,
        };
        final width =
            (constraints.maxWidth - (columns - 1) * AppTheme.space2) / columns;
        return Wrap(
          spacing: AppTheme.space2,
          runSpacing: AppTheme.space2,
          children: [
            for (final row in report.rows)
              SizedBox(
                width: width,
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.space3),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSecondary,
                    borderRadius: BorderRadius.circular(AppTheme.radiusField),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(row.title,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(color: AppTheme.muted)),
                        const SizedBox(height: AppTheme.space2),
                        Text(MoneyFormatter.format(row.amount),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        Text('${row.percentage}% del total',
                            style: Theme.of(context).textTheme.bodySmall),
                      ]),
                ),
              ),
          ],
        );
      }),
    );

Widget _reportLinks(BuildContext context, List<ReportDataModel> reports) =>
    LayoutBuilder(builder: (context, constraints) {
      final columns = Responsive.usesDenseLayout(constraints.maxWidth) ? 1 : 2;
      final width = columns == 1
          ? constraints.maxWidth
          : (constraints.maxWidth - AppTheme.space3) / 2;
      return Wrap(
        spacing: AppTheme.space3,
        runSpacing: AppTheme.space3,
        children: [
          for (final report in reports)
            SizedBox(
              width: width,
              child: Material(
                color: AppTheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  side: const BorderSide(color: AppTheme.line),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  onTap: () => context.go('/reportes/${report.type.key}'),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.space4),
                    child: Row(children: [
                      Icon(report.type.icon, color: AppTheme.primary),
                      const SizedBox(width: AppTheme.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(report.type.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            Text(report.type.description),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ]),
                  ),
                ),
              ),
            ),
        ],
      );
    });

Widget _imssNotice(BuildContext context) => const AppNotice(
      type: AppNoticeType.info,
      text:
          'Este reporte incluye únicamente comisiones IMSS de contratos M10, M40 y M40 Retroactiva; distingue dispersadas, pendientes y otros estados.',
    );

Widget _panel(BuildContext context,
        {required String title,
        required String subtitle,
        required Widget child}) =>
    Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.line),
        boxShadow: AppTheme.elevation,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppTheme.space1),
        Text(subtitle,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.muted)),
        const SizedBox(height: AppTheme.space4),
        child,
      ]),
    );

AppBadge _statusBadge(String status) => AppBadge(
      label: status,
      tone: switch (status) {
        'Dispersada' => AppBadgeTone.success,
        'Pendiente de dispersión' => AppBadgeTone.warning,
        'Referencial' => AppBadgeTone.info,
        _ => AppBadgeTone.neutral,
      },
    );

List<ReportRowModel> _filteredRows(
    ReportDataModel report, ReportFiltersModel filters) {
  if (report.type == ReportType.comisionesTipoVenta &&
      filters.saleType != 'Todos los tipos') {
    return report.rows.where((row) => row.title == filters.saleType).toList();
  }
  if (report.type == ReportType.pagosMetodo &&
      filters.paymentMethod != 'Todos los métodos') {
    return report.rows
        .where((row) => row.title == filters.paymentMethod)
        .toList();
  }
  if (report.type == ReportType.ingresos) {
    return [
      for (final point
          in _pointsForGranularity(report.points, filters.granularity))
        ReportRowModel(title: point.label, amount: point.amount),
    ];
  }
  return report.rows;
}

String _totalLabel(ReportType type) => switch (type) {
      ReportType.ingresos => 'Ingresos validados',
      ReportType.comisionesDestino ||
      ReportType.comisionesTipoVenta =>
        'Comisiones',
      ReportType.imss => 'Importe reportado al IMSS',
      ReportType.pagosMetodo => 'Pagos validados',
    };

String _tableTitle(ReportType type) => switch (type) {
      ReportType.ingresos => 'Ingresos validados por periodo',
      ReportType.comisionesDestino => 'Comisiones por destino y beneficiario',
      ReportType.comisionesTipoVenta => 'Comisiones por tipo de venta',
      ReportType.imss => 'Pagos al IMSS por contrato',
      ReportType.pagosMetodo => 'Pagos por método',
    };

String _tableSubtitle(ReportType type) => switch (type) {
      ReportType.ingresos =>
        'Ingresos agrupados según la granularidad seleccionada.',
      ReportType.comisionesDestino =>
        'El estado de dispersión se conserva por movimiento.',
      ReportType.comisionesTipoVenta =>
        'Otros contratos se agrupan como sin tipo registrado.',
      ReportType.imss => 'Solo M10, M40 y M40 Retroactiva.',
      ReportType.pagosMetodo =>
        'Solo pagos validados; pagos programados no se incluyen.',
    };

String _countLabel(ReportType type) =>
    type == ReportType.comisionesTipoVenta ? 'Ventas' : 'Pagos';

List<ReportPointModel> _pointsForGranularity(
  List<ReportPointModel> weeklyPoints,
  String granularity,
) {
  if (granularity == 'Semanal' || weeklyPoints.length < 2) return weeklyPoints;
  if (granularity == 'Anual') {
    final total = weeklyPoints.fold(
      Decimal.zero,
      (sum, point) => sum + point.amount,
    );
    return [ReportPointModel(label: '2025', amount: total)];
  }
  final monthly = <String, Decimal>{};
  for (final point in weeklyPoints) {
    final month = point.label.endsWith('abr') ? 'Abril' : 'Mayo';
    monthly.update(
      month,
      (amount) => amount + point.amount,
      ifAbsent: () => point.amount,
    );
  }
  return [
    for (final entry in monthly.entries)
      ReportPointModel(label: entry.key, amount: entry.value),
  ];
}

Decimal _personalCommissions(ReportDataModel report) => report.rows
    .where((row) => !{'IMSS', 'Empresa'}.contains(row.title))
    .fold(Decimal.zero, (sum, row) => sum + row.amount);

Decimal _variation(Decimal current, Decimal previous) {
  if (previous == Decimal.zero) return Decimal.zero;
  return ((current - previous) * Decimal.fromInt(100) / previous).toDecimal(
    scaleOnInfinitePrecision: 1,
    toBigInt: (value) => value.round(),
  );
}

String _compactMoney(Decimal amount) {
  if (amount >= Decimal.parse('1000000')) {
    final millions = (amount / Decimal.parse('1000000'))
        .toDecimal(scaleOnInfinitePrecision: 2);
    return '\$${millions.toStringAsFixed(2)}M';
  }
  return MoneyFormatter.format(amount);
}
