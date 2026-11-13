import 'dart:convert';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/platform/file_platform_factory.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/responsive/window_size_class.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_metric_card.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../../auth/auth.dart';
import '../../controllers/dashboard_controller.dart';
import '../../models/dashboard_model.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return auth.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const AppStatePanel(
        icon: Icons.person_off_outlined,
        title: 'No se pudo cargar la sesión',
        message: 'Vuelve a iniciar sesión para consultar el Dashboard.',
      ),
      data: (session) {
        if (session == null) {
          return const AppStatePanel(
            icon: Icons.lock_outline,
            title: 'Inicia sesión para continuar',
            message: 'El Dashboard requiere una sesión activa.',
          );
        }

        final state = ref.watch(dashboardControllerProvider(session.role));
        return state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => AppStatePanel(
            icon: Icons.cloud_off_outlined,
            title: 'No se pudo cargar el Dashboard',
            message: 'Inténtalo de nuevo.',
            action: AppButton(
              label: 'Reintentar',
              variant: AppButtonVariant.secondary,
              expand: false,
              onPressed: () => ref
                  .read(dashboardControllerProvider(session.role).notifier)
                  .load(),
            ),
          ),
          data: (model) => model == null
              ? const AppStatePanel(
                  icon: Icons.dashboard_customize_outlined,
                  title: 'Dashboard sin conectar',
                  message:
                      'La API no tiene un endpoint agregado para esta vista. '
                      'Las métricas reales se integrarán al conectar reportes, '
                      'pagos programados y contratos.',
                )
              : _dashboardContent(context, session, model),
        );
      },
    );
  }

  Widget _dashboardContent(
    BuildContext context,
    AuthSessionModel session,
    DashboardModel model,
  ) {
    final date = DateFormat('EEEE, d MMMM', 'es_MX').format(DateTime.now());
    final firstName = session.name.trim().split(RegExp(r'\s+')).first;
    final roleName = switch (session.role) {
      UserRole.administrador => 'Administrador',
      UserRole.administradorFinanciero => 'Administrador financiero',
      UserRole.asesor => 'Asesor',
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Responsive.of(context);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.space6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppPageHeader(
                eyebrow: date,
                title: 'Buen día, $firstName',
                description: model.isAdvisor
                    ? 'Resumen de tus clientes y operaciones asignadas.'
                    : 'Este es el estado financiero y operativo de hoy.',
                actions: [
                  if (!model.isAdvisor)
                    OutlinedButton.icon(
                      onPressed: () => _exportDashboard(context, model),
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Exportar'),
                    ),
                  ElevatedButton.icon(
                      onPressed: () => context.go('/pagos'),
                      icon: const Icon(Icons.add),
                      label: const Text('Registrar pago')),
                ],
              ),
              _roleNotice(roleName),
              const SizedBox(height: AppTheme.space4),
              _metrics(
                context,
                constraints.maxWidth - AppTheme.space6 * 2,
                model.metrics,
              ),
              const SizedBox(height: AppTheme.space5),
              if (model.isAdvisor)
                _advisorSections(context, model, size)
              else
                _managementSections(context, model, size),
            ],
          ),
        );
      },
    );
  }

  Widget _roleNotice(String role) => Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space4,
          vertical: AppTheme.space3,
        ),
        decoration: BoxDecoration(
          color: AppTheme.accentSoft,
          border: Border.all(color: AppTheme.line),
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child: Row(
          children: [
            const Icon(Icons.people_outline, color: AppTheme.primary),
            const SizedBox(width: AppTheme.space2),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: 'Navegando como ',
                  children: [
                    TextSpan(
                      text: role,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _metrics(
    BuildContext context,
    double width,
    List<DashboardMetric> metrics,
  ) {
    final columns =
        Responsive.dashboardMetricColumns(MediaQuery.sizeOf(context).width);
    final gap = AppTheme.space3;
    final itemWidth = (width - gap * (columns - 1)) / columns;
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final metric in metrics)
          SizedBox(
            width: itemWidth,
            child: AppMetricCard(
              label: metric.label,
              value: metric.value,
              detail: metric.detail,
              icon: _metricIcon(metric.icon),
              tone: _metricTone(metric.tone),
            ),
          ),
      ],
    );
  }

  Future<void> _exportDashboard(
    BuildContext context,
    DashboardModel model,
  ) async {
    final shouldExport = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Exportar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: 'CSV',
              decoration: const InputDecoration(labelText: 'Formato'),
              items: const [
                DropdownMenuItem(value: 'CSV', child: Text('CSV')),
              ],
              onChanged: (_) {},
            ),
            const SizedBox(height: AppTheme.space3),
            TextFormField(
              initialValue: model.periodLabel,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Periodo'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Preparar exportación'),
          ),
        ],
      ),
    );
    if (shouldExport != true || !context.mounted) return;

    final csv = _dashboardCsv(model);
    await createFilePlatform().downloadFile(
      'resumen-financiero.csv',
      Uint8List.fromList(utf8.encode('\uFEFF$csv')),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resumen descargado')),
    );
  }

  String _dashboardCsv(DashboardModel model) {
    String quote(String value) => '"${value.replaceAll('"', '""')}"';
    final rows = <List<String>>[
      ['Resumen financiero', model.periodLabel],
      ['Indicador', 'Valor', 'Detalle'],
      for (final metric in model.metrics)
        [metric.label, metric.value, metric.detail],
      if (model.totalValidated != null) ...[
        ['Ingresos validados', MoneyFormatter.format(model.totalValidated!)],
        ['Servicio', 'Importe', 'Porcentaje'],
        for (final service in model.serviceBreakdown)
          [
            service.label,
            MoneyFormatter.format(service.amount),
            '${service.percentage.toString()}%',
          ],
      ],
    ];
    return rows.map((row) => row.map(quote).join(',')).join('\r\n');
  }

  IconData _metricIcon(DashboardMetricIcon icon) => switch (icon) {
        DashboardMetricIcon.chart => Icons.bar_chart,
        DashboardMetricIcon.clock => Icons.schedule_outlined,
        DashboardMetricIcon.check => Icons.task_alt_outlined,
        DashboardMetricIcon.document => Icons.description_outlined,
        DashboardMetricIcon.briefcase => Icons.business_center_outlined,
        DashboardMetricIcon.people => Icons.people_outline,
        DashboardMetricIcon.warning => Icons.warning_amber_outlined,
      };

  AppMetricTone _metricTone(DashboardMetricTone tone) => switch (tone) {
        DashboardMetricTone.positive => AppMetricTone.secondary,
        DashboardMetricTone.info => AppMetricTone.info,
        DashboardMetricTone.warning => AppMetricTone.warning,
        DashboardMetricTone.soft => AppMetricTone.secondary,
        DashboardMetricTone.navy => AppMetricTone.accent,
      };

  Widget _managementSections(
    BuildContext context,
    DashboardModel model,
    WindowSizeClass size,
  ) =>
      Column(
        children: [
          _responsivePair(
            context,
            size,
            _incomePanel(context, model),
            _attentionPanel(context, model),
            firstFlex: 3,
            secondFlex: 2,
          ),
          const SizedBox(height: AppTheme.space5),
          _responsivePair(
            context,
            size,
            _collectionsPanel(context, model.collections),
            _activityPanel(context, model.recentActivity),
            firstFlex: 3,
            secondFlex: 2,
          ),
        ],
      );

  Widget _advisorSections(
    BuildContext context,
    DashboardModel model,
    WindowSizeClass size,
  ) =>
      _responsivePair(
        context,
        size,
        _taskPanel(
          context,
          title: 'Mis clientes prioritarios',
          description: 'Operaciones que requieren seguimiento',
          tasks: model.advisorPriorities,
        ),
        _taskPanel(
          context,
          title: 'Mi agenda',
          description: 'Acciones pendientes',
          tasks: model.advisorAgenda,
          badge: '6 pendientes',
        ),
        firstFlex: 3,
        secondFlex: 2,
      );

  Widget _responsivePair(
    BuildContext context,
    WindowSizeClass size,
    Widget first,
    Widget second, {
    required int firstFlex,
    required int secondFlex,
  }) {
    if (size != WindowSizeClass.expandido) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          first,
          const SizedBox(height: AppTheme.space5),
          second,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: firstFlex, child: first),
        const SizedBox(width: AppTheme.space5),
        Expanded(flex: secondFlex, child: second),
      ],
    );
  }

  Widget _incomePanel(BuildContext context, DashboardModel model) => _panel(
        context,
        title: 'Ingresos por servicio',
        description: model.periodLabel,
        action: TextButton.icon(
          onPressed: () => context.go('/reportes'),
          icon: const Icon(Icons.arrow_forward, size: 18),
          label: const Text('Ver reporte'),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total validado'),
                      const SizedBox(height: AppTheme.space1),
                      Text(
                        MoneyFormatter.format(model.totalValidated!),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                if (model.periodChange != null)
                  _changeBadge(model.periodChange!),
              ],
            ),
            const SizedBox(height: AppTheme.space3),
            Semantics(
              label: _chartDescription(model.weeklyIncome),
              child: SizedBox(
                height: 180,
                child: BarChart(_incomeChartData(model.weeklyIncome)),
              ),
            ),
            const Divider(height: AppTheme.space6),
            _serviceLegend(context, model.serviceBreakdown),
          ],
        ),
      );

  Widget _changeBadge(Decimal change) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space3,
          vertical: AppTheme.space2,
        ),
        decoration: BoxDecoration(
          color: AppTheme.successBackground,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        ),
        child: Text(
          '+${change.toString()}%',
          style: const TextStyle(
            color: AppTheme.success,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  BarChartData _incomeChartData(List<DashboardChartPoint> points) {
    final maxValue =
        points.map((point) => point.amount.toDouble()).fold<double>(
                  0,
                  (largest, value) => largest > value ? largest : value,
                ) *
            1.2;
    return BarChartData(
      maxY: maxValue,
      minY: 0,
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= points.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: AppTheme.space1),
                child: Text(
                  points[index].label,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                ),
              );
            },
          ),
        ),
      ),
      barGroups: [
        for (var index = 0; index < points.length; index++)
          BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: points[index].amount.toDouble(),
                color: index == 5 ? AppTheme.primary : AppTheme.secondaryTint,
                width: 22,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusSmall),
                ),
              ),
            ],
          ),
      ],
    );
  }

  String _chartDescription(List<DashboardChartPoint> points) =>
      'Ingresos semanales: ${points.map((point) => '${point.label}, ${MoneyFormatter.format(point.amount)}').join('; ')}.';

  Widget _serviceLegend(
    BuildContext context,
    List<DashboardServiceBreakdown> items,
  ) {
    const colors = [
      AppTheme.primary,
      AppTheme.secondary,
      AppTheme.infoBase,
      AppTheme.gold,
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth >= 600
            ? (constraints.maxWidth - AppTheme.space4) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: AppTheme.space4,
          runSpacing: AppTheme.space3,
          children: [
            for (var index = 0; index < items.length; index++)
              SizedBox(
                width: itemWidth,
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: AppTheme.space2),
                    Expanded(
                      child: Text(
                        items[index].label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      MoneyFormatter.format(items[index].amount),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: AppTheme.space1),
                    Text(
                      '${items[index].percentage.toString()}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _attentionPanel(BuildContext context, DashboardModel model) =>
      _taskPanel(
        context,
        title: 'Requieren atención',
        description: 'Prioridades para hoy',
        tasks: model.attentionItems,
        badge: '${model.attentionCount} pendientes',
        footer: _nextCutNote(context),
      );

  Widget _nextCutNote(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: AppTheme.space3),
        padding: const EdgeInsets.all(AppTheme.space3),
        decoration: BoxDecoration(
          color: AppTheme.surfaceSecondary,
          borderRadius: BorderRadius.circular(AppTheme.radiusField),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.schedule, color: AppTheme.primary),
            const SizedBox(width: AppTheme.space2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Semana financiera',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Text('El periodo va de viernes a jueves.'),
                  TextButton(
                    onPressed: () => context.go('/cortes'),
                    child: const Text('Consultar cortes'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _taskPanel(
    BuildContext context, {
    required String title,
    required String description,
    required List<DashboardTask> tasks,
    String? badge,
    Widget? footer,
  }) =>
      _panel(
        context,
        title: title,
        description: description,
        badge: badge,
        child: Column(
          children: [
            for (final task in tasks)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _taskIcon(task.kind),
                title: Text(
                  task.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(task.detail),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(task.route),
              ),
            if (footer != null) footer,
          ],
        ),
      );

  Widget _taskIcon(DashboardTaskKind kind) {
    final (icon, foreground, background) = switch (kind) {
      DashboardTaskKind.validation => (
          Icons.task_alt_outlined,
          AppTheme.goldDark,
          AppTheme.goldSoft,
        ),
      DashboardTaskKind.overdue => (
          Icons.warning_amber_outlined,
          AppTheme.danger,
          AppTheme.dangerBackground,
        ),
      DashboardTaskKind.contract => (
          Icons.description_outlined,
          AppTheme.info,
          AppTheme.infoBackground,
        ),
      DashboardTaskKind.calendar => (
          Icons.calendar_month_outlined,
          AppTheme.goldDark,
          AppTheme.goldSoft,
        ),
      DashboardTaskKind.evidence => (
          Icons.error_outline,
          AppTheme.danger,
          AppTheme.dangerBackground,
        ),
      DashboardTaskKind.commission => (
          Icons.bar_chart,
          AppTheme.info,
          AppTheme.infoBackground,
        ),
    };
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTheme.radiusField),
      ),
      child: Icon(icon, color: foreground),
    );
  }

  Widget _collectionsPanel(
    BuildContext context,
    List<DashboardCollection> collections,
  ) =>
      _panel(
        context,
        title: 'Próximos cobros',
        description: 'Siguientes 7 días',
        action: TextButton.icon(
          onPressed: () => context.go('/pagos'),
          icon: const Icon(Icons.arrow_forward, size: 18),
          label: const Text('Ver pagos'),
        ),
        child: Column(
          children: [
            for (var index = 0; index < collections.length; index++) ...[
              if (index > 0) const Divider(height: AppTheme.space2),
              Semantics(
                button: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.radiusField),
                  onTap: () => context.go('/pagos'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.space2,
                    ),
                    child: Row(
                      children: [
                        _dateChip(context, collections[index].dueDate),
                        const SizedBox(width: AppTheme.space2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                collections[index].client,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${collections[index].service} · '
                                '${collections[index].description}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppTheme.space2),
                        Text(
                          MoneyFormatter.format(collections[index].amount),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );

  Widget _dateChip(BuildContext context, DateTime date) => Container(
        constraints: const BoxConstraints(minWidth: 54, minHeight: 42),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space2),
        decoration: BoxDecoration(
          color: AppTheme.surfaceSecondary,
          borderRadius: BorderRadius.circular(AppTheme.radiusField),
        ),
        child: Text(
          DateFormat('dd MMM', 'es_MX').format(date).toUpperCase(),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.muted,
                fontWeight: FontWeight.w700,
              ),
        ),
      );

  Widget _activityPanel(
    BuildContext context,
    List<DashboardActivity> activity,
  ) =>
      _panel(
        context,
        title: 'Actividad reciente',
        description: 'Últimos movimientos',
        action: TextButton.icon(
          onPressed: () => context.go('/pagos'),
          icon: const Icon(Icons.arrow_forward, size: 18),
          label: const Text('Ver pagos'),
        ),
        child: Column(
          children: [
            for (final item in activity)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _activityMarker(item.kind),
                title: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(item.detail),
                trailing: Text(
                  item.elapsed,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      );

  Widget _activityMarker(DashboardActivityKind kind) {
    final color = switch (kind) {
      DashboardActivityKind.success => AppTheme.successBase,
      DashboardActivityKind.info => AppTheme.infoBase,
      DashboardActivityKind.danger => AppTheme.dangerBase,
      DashboardActivityKind.neutral => AppTheme.faint,
    };
    return Semantics(
      label: switch (kind) {
        DashboardActivityKind.success => 'Correcto',
        DashboardActivityKind.info => 'Información',
        DashboardActivityKind.danger => 'Atención',
        DashboardActivityKind.neutral => 'Movimiento',
      },
      child: CircleAvatar(radius: 6, backgroundColor: color),
    );
  }

  Widget _panel(
    BuildContext context, {
    required String title,
    required String description,
    required Widget child,
    String? badge,
    Widget? action,
  }) =>
      Container(
        padding: const EdgeInsets.all(AppTheme.space4),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.line),
          borderRadius: BorderRadius.circular(AppTheme.radius),
          boxShadow: AppTheme.elevation,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppTheme.space2,
              runSpacing: AppTheme.space1,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppTheme.space1),
                      Text(
                        description,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppTheme.muted),
                      ),
                    ],
                  ),
                ),
                if (badge != null)
                  AppBadge(label: badge, tone: AppBadgeTone.warning),
                if (action != null) action,
              ],
            ),
            const Divider(height: AppTheme.space6),
            Material(
              type: MaterialType.transparency,
              child: child,
            ),
          ],
        ),
      );
}
