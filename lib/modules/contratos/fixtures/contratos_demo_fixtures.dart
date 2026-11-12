import '../../../core/demo/demo_dataset.dart';
import '../../../core/demo/demo_metric.dart';
import '../../../core/demo/demo_record.dart';

abstract final class ContratosDemoFixtures {
  static const dataset = DemoDataset(
    module: 'contratos',
    metrics: [
      DemoMetric(label: 'Contratos activos', value: '248'),
      DemoMetric(label: 'Por finalizar', value: '17'),
      DemoMetric(label: 'En revisión', value: '8'),
    ],
    records: [
      DemoRecord(
          id: 'demo-contract-1',
          title: 'H3-M40-0317',
          subtitle: 'Elena Robles Vargas',
          status: 'Activo',
          amount: '\$120,000',
          details: {'modalidad': 'Modalidad 40'}),
      DemoRecord(
          id: 'demo-contract-2',
          title: 'H3-M10-0426',
          subtitle: 'Arturo Medina Flores',
          status: 'Activo',
          amount: '\$41,400',
          details: {'modalidad': 'Modalidad 10'}),
      DemoRecord(
          id: 'demo-contract-3',
          title: 'H3-APD-0189',
          subtitle: 'Rosa Elena Pacheco',
          status: 'En revisión',
          amount: '\$42,500',
          details: {'modalidad': 'APD'}),
      DemoRecord(
          id: 'demo-contract-4',
          title: 'H3-M40R-0064',
          subtitle: 'Javier Torres Luna',
          status: 'Por finalizar',
          amount: '\$96,000',
          details: {'modalidad': 'M40 Retroactiva'}),
    ],
    notes: ['Conteos, folios y saldos son datos visuales de demostración.'],
  );
}
