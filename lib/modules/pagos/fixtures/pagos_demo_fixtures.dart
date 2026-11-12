import '../../../core/demo/demo_dataset.dart';
import '../../../core/demo/demo_metric.dart';
import '../../../core/demo/demo_record.dart';

abstract final class PagosDemoFixtures {
  static const dataset = DemoDataset(
    module: 'pagos',
    metrics: [
      DemoMetric(label: 'Pagos del periodo', value: '124'),
      DemoMetric(label: 'Por validar', value: '8'),
      DemoMetric(label: 'Vencidos', value: '4'),
    ],
    records: [
      DemoRecord(
          id: 'demo-payment-1',
          title: 'PG-2025-0428',
          subtitle: 'Elena Robles · M40202500001',
          status: 'Validado',
          amount: '\$10,000'),
      DemoRecord(
          id: 'demo-payment-2',
          title: 'PG-2025-0501',
          subtitle: 'Natalia Vázquez · H3-M40-0317',
          status: 'Programado',
          amount: '\$10,000'),
      DemoRecord(
          id: 'demo-payment-3',
          title: 'PG-2025-0502',
          subtitle: 'Arturo Medina · H3-M10-0426',
          status: 'Pendiente',
          amount: '\$6,900'),
      DemoRecord(
          id: 'demo-payment-4',
          title: 'PG-2025-0503',
          subtitle: 'Rosa Pacheco · H3-APD-0189',
          status: 'Rechazado',
          amount: '\$42,500'),
    ],
    notes: [
      'Registros y movimientos son muestras de interfaz, no transacciones.'
    ],
  );
}
