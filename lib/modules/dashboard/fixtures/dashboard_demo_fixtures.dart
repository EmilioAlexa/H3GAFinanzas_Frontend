import '../../../core/demo/demo_dataset.dart';
import '../../../core/demo/demo_metric.dart';
import '../../../core/demo/demo_record.dart';

abstract final class DashboardDemoFixtures {
  static const dataset = DemoDataset(
    module: 'dashboard',
    metrics: [
      DemoMetric(
          label: 'Ingresos del periodo',
          value: '\$1,284,500',
          detail: '+12.4% vs. periodo anterior'),
      DemoMetric(
          label: 'Por cobrar',
          value: '\$386,200',
          detail: '42 pagos pendientes'),
      DemoMetric(
          label: 'Pendientes de validación',
          value: '8 pagos',
          detail: '\$127,450 por revisar'),
      DemoMetric(
          label: 'Contratos activos',
          value: '248',
          detail: '17 finalizan este mes'),
      DemoMetric(
          label: 'Comisiones generadas',
          value: '\$164,820',
          detail: 'Corte 17–23 may.'),
    ],
    records: [
      DemoRecord(
          id: 'dash-1',
          title: 'Elena Robles',
          subtitle: 'Modalidad 40 · Mensualidad 7 de 12',
          amount: '\$10,000',
          status: 'Próximo cobro'),
      DemoRecord(
          id: 'dash-2',
          title: 'Carlos Mendoza',
          subtitle: 'Modalidad 10 · Mensualidad 3 de 6',
          amount: '\$6,900',
          status: 'Próximo cobro'),
      DemoRecord(
          id: 'dash-3',
          title: 'Sofía Ramírez',
          subtitle: 'APD · Pago único',
          amount: '\$42,500',
          status: 'Próximo cobro'),
    ],
    notes: ['Todos los valores del Dashboard son muestras visuales de Figma.'],
  );
}
