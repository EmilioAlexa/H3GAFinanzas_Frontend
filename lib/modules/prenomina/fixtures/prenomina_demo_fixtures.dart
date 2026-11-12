import '../../../core/demo/demo_dataset.dart';
import '../../../core/demo/demo_metric.dart';
import '../../../core/demo/demo_record.dart';

abstract final class PrenominaDemoFixtures {
  static const dataset = DemoDataset(
    module: 'prenomina',
    metrics: [
      DemoMetric(label: 'Periodo', value: '17–23 may.'),
      DemoMetric(label: 'Asesores', value: '12'),
      DemoMetric(label: 'Total estimado', value: '\$164,820'),
    ],
    records: [
      DemoRecord(
          id: 'demo-payroll-1',
          title: 'Daniela Cruz',
          subtitle: '8 pagos · 4 contratos',
          status: 'Por revisar',
          amount: '\$42,500'),
      DemoRecord(
          id: 'demo-payroll-2',
          title: 'Jorge Silva',
          subtitle: '6 pagos · 3 contratos',
          status: 'Preparada',
          amount: '\$36,300'),
      DemoRecord(
          id: 'demo-payroll-3',
          title: 'Mónica Ruiz',
          subtitle: '5 pagos · 3 contratos',
          status: 'Preparada',
          amount: '\$28,700'),
    ],
    notes: ['Montos de nómina ficticios; no representan una dispersión.'],
  );
}
