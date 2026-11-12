import '../../../core/demo/demo_dataset.dart';
import '../../../core/demo/demo_metric.dart';
import '../../../core/demo/demo_record.dart';

abstract final class CortesDemoFixtures {
  static const dataset = DemoDataset(
    module: 'cortes',
    metrics: [
      DemoMetric(label: 'Corte actual', value: '17–23 may.'),
      DemoMetric(label: 'Pagos incluidos', value: '42'),
      DemoMetric(label: 'Por revisar', value: '8'),
    ],
    records: [
      DemoRecord(
          id: 'demo-cut-1',
          title: 'Corte 17–23 mayo 2025',
          subtitle: 'Semana financiera · viernes a jueves',
          status: 'En preparación',
          amount: '\$1,284,500'),
      DemoRecord(
          id: 'demo-cut-2',
          title: 'Corte 10–16 mayo 2025',
          subtitle: '42 pagos incluidos',
          status: 'Cerrado',
          amount: '\$1,146,200'),
    ],
    notes: [
      'Los periodos son muestras; la zona real de reportes es America/Cancun.'
    ],
  );
}
