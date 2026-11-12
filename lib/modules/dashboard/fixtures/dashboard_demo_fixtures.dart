import 'package:decimal/decimal.dart';

import '../../../core/demo/demo_dataset.dart';
import '../../../core/demo/demo_metric.dart';
import '../../../core/demo/demo_record.dart';
import '../../../core/utils/money_formatter.dart';
import '../../auth/auth.dart';
import '../models/dashboard_model.dart';

abstract final class DashboardDemoFixtures {
  static DashboardModel forRole(UserRole role) =>
      role == UserRole.asesor ? _advisorModel() : _managementModel();

  static DashboardModel _managementModel() {
    final total = Decimal.parse('1284500');
    return DashboardModel(
      isAdvisor: false,
      metrics: [
        (
          label: 'Ingresos del periodo',
          value: MoneyFormatter.format(total),
          detail: '+12.4% vs. periodo anterior',
          icon: DashboardMetricIcon.chart,
          tone: DashboardMetricTone.positive,
        ),
        (
          label: 'Por cobrar',
          value: MoneyFormatter.format(Decimal.parse('386200')),
          detail: '42 pagos pendientes',
          icon: DashboardMetricIcon.clock,
          tone: DashboardMetricTone.info,
        ),
        (
          label: 'Pendientes de validación',
          value: '8 pagos',
          detail: '\$127,450 por revisar',
          icon: DashboardMetricIcon.check,
          tone: DashboardMetricTone.warning,
        ),
        (
          label: 'Contratos activos',
          value: '248',
          detail: '17 finalizan este mes',
          icon: DashboardMetricIcon.document,
          tone: DashboardMetricTone.soft,
        ),
        (
          label: 'Comisiones generadas',
          value: MoneyFormatter.format(Decimal.parse('164820')),
          detail: 'Periodo de demostración',
          icon: DashboardMetricIcon.briefcase,
          tone: DashboardMetricTone.navy,
        ),
      ],
      totalValidated: total,
      periodChange: Decimal.parse('12.4'),
      periodLabel: 'Semana de demostración · viernes a jueves',
      weeklyIncome: [
        (label: 'V', amount: Decimal.parse('158000')),
        (label: 'S', amount: Decimal.parse('182000')),
        (label: 'D', amount: Decimal.parse('132000')),
        (label: 'L', amount: Decimal.parse('214000')),
        (label: 'M', amount: Decimal.parse('191000')),
        (label: 'M', amount: Decimal.parse('229500')),
        (label: 'J', amount: Decimal.parse('178000')),
      ],
      serviceBreakdown: [
        (
          label: 'Modalidad 40',
          amount: Decimal.parse('486300'),
          percentage: Decimal.parse('38'),
        ),
        (
          label: 'APD',
          amount: Decimal.parse('398250'),
          percentage: Decimal.parse('31'),
        ),
        (
          label: 'Modalidad 10',
          amount: Decimal.parse('274650'),
          percentage: Decimal.parse('21'),
        ),
        (
          label: 'M40 Retroactiva',
          amount: Decimal.parse('125300'),
          percentage: Decimal.parse('10'),
        ),
      ],
      attentionCount: 12,
      attentionItems: const [
        (
          title: '8 pagos por validar',
          detail: '3 con más de 24 horas',
          kind: DashboardTaskKind.validation,
          route: '/validacion',
        ),
        (
          title: '4 pagos vencidos',
          detail: 'Saldo total de \$58,900',
          kind: DashboardTaskKind.overdue,
          route: '/pagos',
        ),
        (
          title: '17 contratos por finalizar',
          detail: 'En los próximos 30 días',
          kind: DashboardTaskKind.contract,
          route: '/contratos',
        ),
      ],
      collections: [
        for (final collection in [
          (
            offset: 1,
            client: 'Elena Robles',
            service: 'Modalidad 40',
            description: 'Mensualidad 7 de 12',
            amount: '10000',
          ),
          (
            offset: 2,
            client: 'Carlos Mendoza',
            service: 'Modalidad 10',
            description: 'Mensualidad 3 de 6',
            amount: '6900',
          ),
          (
            offset: 4,
            client: 'Sofía Ramírez',
            service: 'APD',
            description: 'Pago único · 1 de 1',
            amount: '42500',
          ),
        ])
          (
            dueDate: DateTime.now().add(Duration(days: collection.offset)),
            client: collection.client,
            service: collection.service,
            description: collection.description,
            amount: Decimal.parse(collection.amount),
          ),
      ],
      recentActivity: const [
        (
          title: 'Pago validado',
          detail: 'Elena Robles · \$10,000',
          elapsed: 'Hace 12 min',
          kind: DashboardActivityKind.success,
        ),
        (
          title: 'Evidencia recibida',
          detail: 'Javier Torres · \$12,800',
          elapsed: 'Hace 34 min',
          kind: DashboardActivityKind.info,
        ),
        (
          title: 'Pago rechazado',
          detail: 'María Salgado · Referencia ilegible',
          elapsed: 'Hace 1 h',
          kind: DashboardActivityKind.danger,
        ),
        (
          title: 'Contrato activado',
          detail: 'Sofía Ramírez · APD',
          elapsed: 'Hace 2 h',
          kind: DashboardActivityKind.neutral,
        ),
      ],
    );
  }

  static DashboardModel _advisorModel() => DashboardModel(
        isAdvisor: true,
        metrics: [
          (
            label: 'Clientes asignados',
            value: '42',
            detail: '38 activos',
            icon: DashboardMetricIcon.people,
            tone: DashboardMetricTone.positive,
          ),
          (
            label: 'Contratos activos',
            value: '31',
            detail: '4 por finalizar',
            icon: DashboardMetricIcon.document,
            tone: DashboardMetricTone.info,
          ),
          (
            label: 'Cobros próximos',
            value: MoneyFormatter.format(Decimal.parse('84600')),
            detail: '9 obligaciones',
            icon: DashboardMetricIcon.clock,
            tone: DashboardMetricTone.warning,
          ),
          (
            label: 'Evidencias por corregir',
            value: '2',
            detail: 'Requieren atención',
            icon: DashboardMetricIcon.warning,
            tone: DashboardMetricTone.soft,
          ),
          (
            label: 'Mis comisiones',
            value: MoneyFormatter.format(Decimal.parse('2700')),
            detail: '2 pagos del periodo demo',
            icon: DashboardMetricIcon.briefcase,
            tone: DashboardMetricTone.navy,
          ),
        ],
        advisorPriorities: const [
          (
            title: 'Elena Robles',
            detail: 'Modalidad 40 · Próximo cobro',
            kind: DashboardTaskKind.calendar,
            route: '/clientes',
          ),
          (
            title: 'Sofía Ramírez',
            detail: 'APD · Cobro al cliente',
            kind: DashboardTaskKind.overdue,
            route: '/clientes',
          ),
          (
            title: 'Ana López',
            detail: 'Modalidad 10 · Evidencia por corregir',
            kind: DashboardTaskKind.evidence,
            route: '/pagos',
          ),
        ],
        advisorAgenda: const [
          (
            title: '4 cobros próximos',
            detail: 'Durante los siguientes 7 días',
            kind: DashboardTaskKind.calendar,
            route: '/pagos',
          ),
          (
            title: '2 evidencias por corregir',
            detail: 'Comentarios del área financiera',
            kind: DashboardTaskKind.evidence,
            route: '/pagos',
          ),
          (
            title: 'Consultar mis comisiones',
            detail: 'Periodo actual de demostración',
            kind: DashboardTaskKind.commission,
            route: '/comisiones',
          ),
        ],
      );

  static final dataset = DemoDataset(
    module: 'dashboard',
    metrics: [
      for (final metric in _managementModel().metrics)
        DemoMetric(
          label: metric.label,
          value: metric.value,
          detail: metric.detail,
        ),
    ],
    records: [
      for (final collection in _managementModel().collections)
        DemoRecord(
          id: collection.client,
          title: collection.client,
          subtitle: '${collection.service} · ${collection.description}',
          amount: MoneyFormatter.format(collection.amount),
          status: 'Próximo cobro demo',
        ),
    ],
    notes: const [
      'Datos ficticios de muestra; no representan información del backend.'
    ],
  );
}
