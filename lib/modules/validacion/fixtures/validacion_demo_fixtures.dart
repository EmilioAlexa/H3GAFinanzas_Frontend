import '../../../core/demo/demo_dataset.dart';
import '../../../core/demo/demo_metric.dart';
import '../../../core/demo/demo_record.dart';

abstract final class ValidacionDemoFixtures {
  static const dataset = DemoDataset(
    module: 'validacion',
    metrics: [
      DemoMetric(label: 'Por validar', value: '8 pagos'),
      DemoMetric(label: 'Por autorizar', value: '3 pagos'),
      DemoMetric(label: 'Vencidos', value: '4 pagos'),
    ],
    records: [
      DemoRecord(
          id: 'demo-validation-1',
          title: 'PG-2025-0502',
          subtitle: 'Arturo Medina · 22 may. 2025',
          status: 'Pendiente de validación',
          amount: '\$6,900'),
      DemoRecord(
          id: 'demo-validation-2',
          title: 'PG-2025-0503',
          subtitle: 'Rosa Elena Pacheco · 23 may. 2025',
          status: 'Pendiente de autorización',
          amount: '\$42,500'),
      DemoRecord(
          id: 'demo-validation-3',
          title: 'PG-2025-0492',
          subtitle: 'María Salgado · 20 may. 2025',
          status: 'Con observaciones',
          amount: '\$8,200'),
    ],
    notes: ['Las acciones solo deben mutar estado local en demos futuros.'],
  );
}
