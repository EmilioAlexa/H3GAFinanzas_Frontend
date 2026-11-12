import '../../../core/demo/demo_dataset.dart';
import '../../../core/demo/demo_metric.dart';
import '../../../core/demo/demo_record.dart';

abstract final class ReportesDemoFixtures {
  static const dataset = DemoDataset(
    module: 'reportes',
    metrics: [
      DemoMetric(label: 'Ingresos validados', value: '\$1,284,500'),
      DemoMetric(label: 'Comisiones', value: '\$164,820'),
      DemoMetric(label: 'Pagos', value: '124'),
    ],
    records: [
      DemoRecord(
          id: 'demo-report-1',
          title: 'Modalidad 40',
          subtitle: '38% del ingreso · 24 pagos',
          amount: '\$486,300'),
      DemoRecord(
          id: 'demo-report-2',
          title: 'APD',
          subtitle: '31% del ingreso · 18 pagos',
          amount: '\$398,250'),
      DemoRecord(
          id: 'demo-report-3',
          title: 'Modalidad 10',
          subtitle: '21% del ingreso · 32 pagos',
          amount: '\$274,650'),
      DemoRecord(
          id: 'demo-report-4',
          title: 'M40 Retroactiva',
          subtitle: '10% del ingreso · 8 pagos',
          amount: '\$125,300'),
    ],
    notes: [
      'No usar como base de cifras oficiales ni como datos personales reales.'
    ],
  );
}
