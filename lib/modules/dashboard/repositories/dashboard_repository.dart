import 'package:decimal/decimal.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/env.dart';

import '../../../core/network/finanzas_api.dart';

import '../../auth/auth.dart';

import '../fixtures/dashboard_demo_fixtures.dart';

import '../models/dashboard_model.dart';

class DashboardRepository {
  const DashboardRepository({required this.demoMode, this.api});

  final bool demoMode;

  final FinanzasApi? api;

  Future<DashboardModel?> load(UserRole role) async {
    if (!demoMode) {
      final body = await api!.detail('/finanzas/dashboard');

      final indicators = apiMap(body['indicadores']);

      final income = apiMap(body['ingresos_por_servicio']);

      final period = apiMap(body['periodo']);

      Decimal amount(Object? value) =>
          Decimal.parse(apiText(value).isEmpty ? '0' : apiText(value));

      List<Map<String, dynamic>> rows(Object? value) =>
          (value as List? ?? []).map(apiMap).toList();

      final pending = apiMap(indicators['pagos_pendientes_validacion']);

      return DashboardModel(
        isAdvisor: body['alcance'] == 'asesor',
        metrics: [
          (
            label: 'Ingresos del periodo',
            value: '\$${indicators['ingresos_periodo']}',
            detail: 'Periodo seleccionado',
            icon: DashboardMetricIcon.chart,
            tone: DashboardMetricTone.positive
          ),
          (
            label: 'Por cobrar',
            value: indicators['por_cobrar_conocido'] == null
                ? 'No disponible'
                : '\$${indicators['por_cobrar_conocido']}',
            detail: indicators['por_cobrar_completo'] == true
                ? 'Saldo pendiente de cobro'
                : 'Saldo conocido; existen obligaciones sin saldo disponible',
            icon: DashboardMetricIcon.clock,
            tone: DashboardMetricTone.info
          ),
          (
            label: 'Pendientes de validación',
            value: apiText(pending['stock']),
            detail: 'Por revisar o autorizar',
            icon: DashboardMetricIcon.clock,
            tone: DashboardMetricTone.warning
          ),
          (
            label: 'Contratos activos',
            value: apiText(indicators['contratos_activos']),
            detail: 'Alcance autorizado',
            icon: DashboardMetricIcon.document,
            tone: DashboardMetricTone.info
          ),
          (
            label: 'Comisiones generadas',
            value: '\$${indicators['comisiones_generadas']}',
            detail:
                'Pendientes: Transferencias históricas: \$${indicators['transferencias_historicas']}',
            icon: DashboardMetricIcon.briefcase,
            tone: DashboardMetricTone.soft
          ),
        ],
        totalValidated: amount(indicators['ingresos_periodo']),
        periodChange: indicators['variacion_periodo_porcentaje'] == null
            ? null
            : amount(indicators['variacion_periodo_porcentaje']),
        periodLabel: '${period['inicio_local']} | America/Cancun',
        weeklyIncome: [
          for (final r in rows(income['dias']))
            (label: apiText(r['fecha']), amount: amount(r['monto']))
        ],
        serviceBreakdown: [
          for (final r in rows(income['servicios']))
            (
              label: apiText(r['nombre']),
              amount: amount(r['monto']),
              percentage: amount(r['porcentaje'])
            )
        ],
        attentionCount: (pending['stock'] as num? ?? 0).toInt(),
        attentionItems: [
          if ((pending['stock'] as num? ?? 0) > 0)
            (
              title: 'Pagos pendientes',
              detail: 'Consultar pagos autorizados',
              kind: DashboardTaskKind.validation,
              route: '/pagos'
            )
        ],
        collections: [
          for (final r in rows(apiMap(body['proximos_cobros'])['items']))
            (
              dueDate: DateTime.parse(apiText(r['fecha_esperada'])),
              client: apiText(apiMap(r['cliente'])['nombre']),
              service: apiText(apiMap(r['servicio'])['nombre']),
              description: apiText(r['folio']),
              amount: amount(r['importe_pendiente'])
            )
        ],
        recentActivity: [
          for (final r in rows(apiMap(body['actividad_reciente'])['items']))
            (
              title: apiText(r['tipo']).replaceAll('_', ' '),
              detail: apiText(r['folio']),
              elapsed: apiText(r['ocurrido_en']),
              kind: DashboardActivityKind.info
            )
        ],
      );
    }

    return DashboardDemoFixtures.forRole(role);
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(
      demoMode: AppEnv.demoMode, api: ref.watch(finanzasApiProvider)),
);
