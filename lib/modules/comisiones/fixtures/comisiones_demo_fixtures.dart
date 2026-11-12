import '../../../core/demo/demo_dataset.dart';
import '../../../core/demo/demo_metric.dart';
import '../../../core/demo/demo_record.dart';

abstract final class ComisionesDemoFixtures {
  static const dataset = DemoDataset(
    module: 'comisiones',
    metrics: [
      DemoMetric(label: 'Comisiones generadas', value: '\$164,820'),
      DemoMetric(label: 'Pendientes de dispersión', value: '\$48,500'),
      DemoMetric(label: 'Dispersadas', value: '\$116,320'),
    ],
    records: [
      DemoRecord(
          id: 'demo-commission-1',
          title: 'PG-2025-0428',
          subtitle: 'Daniela Cruz · Modalidad 40',
          status: 'Dispersada',
          amount: '\$1,500',
          details: {'porcentaje': '15%'}),
      DemoRecord(
          id: 'demo-commission-2',
          title: 'PG-2025-0501',
          subtitle: 'Daniela Cruz · Referidor',
          status: 'Dispersada',
          amount: '\$1,200',
          details: {'porcentaje': '12%'}),
      DemoRecord(
          id: 'demo-commission-3',
          title: 'PG-2025-0502',
          subtitle: 'Jorge Silva · Modalidad 10',
          status: 'Pendiente de dispersión',
          amount: '\$1,000',
          details: {'porcentaje': '10%'}),
      DemoRecord(
          id: 'demo-commission-4',
          title: 'PG-2025-0503',
          subtitle: 'Mónica Ruiz · APD',
          status: 'Pendiente de dispersión',
          amount: '\$800',
          details: {'porcentaje': '8%'}),
    ],
    notes: [
      'Porcentajes ficticios válidos en pasos de 0.5; Empresa es remanente.'
    ],
  );
}
