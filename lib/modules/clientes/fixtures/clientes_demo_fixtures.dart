import '../../../core/demo/demo_dataset.dart';
import '../../../core/demo/demo_metric.dart';
import '../../../core/demo/demo_record.dart';

abstract final class ClientesDemoFixtures {
  static const dataset = DemoDataset(
    module: 'clientes',
    metrics: [
      DemoMetric(label: 'Clientes', value: '326'),
      DemoMetric(label: 'Activos', value: '284'),
      DemoMetric(label: 'En seguimiento', value: '18'),
    ],
    records: [
      DemoRecord(
          id: 'demo-client-1',
          title: 'Elena Robles Vargas',
          subtitle: 'ROVE680214MDFBLN08 · Daniela Cruz',
          status: 'Activo',
          details: {'servicio': 'Modalidad 40'}),
      DemoRecord(
          id: 'demo-client-2',
          title: 'Carlos Mendoza Ruiz',
          subtitle: 'MERC720908HDFNZR04 · Jorge Silva',
          status: 'Activo',
          details: {'servicio': 'Modalidad 10'}),
      DemoRecord(
          id: 'demo-client-3',
          title: 'Sofía Ramírez León',
          subtitle: 'RALS650320MDFMNF02 · Daniela Cruz',
          status: 'Seguimiento',
          details: {'servicio': 'APD'}),
      DemoRecord(
          id: 'demo-client-4',
          title: 'Javier Torres Luna',
          subtitle: 'TOLJ700711HDFRNV07 · Mónica Ruiz',
          status: 'Activo',
          details: {'servicio': 'M40 Retroactiva'}),
      DemoRecord(
          id: 'demo-client-5',
          title: 'María Salgado Pérez',
          subtitle: 'SAPM691104MDFLNR01 · Jorge Silva',
          status: 'Pausado',
          details: {'servicio': 'Modalidad 40'}),
    ],
    notes: [
      'Identidades y conteos son ficticios; no son datos de clientes reales.'
    ],
  );
}
