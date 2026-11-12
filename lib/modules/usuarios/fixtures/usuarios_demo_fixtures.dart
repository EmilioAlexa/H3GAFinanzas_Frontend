import '../../../core/demo/demo_dataset.dart';
import '../../../core/demo/demo_metric.dart';
import '../../../core/demo/demo_record.dart';

abstract final class UsuariosDemoFixtures {
  static const dataset = DemoDataset(
    module: 'usuarios',
    metrics: [
      DemoMetric(label: 'Usuarios activos', value: '18'),
      DemoMetric(label: 'Usuarios suspendidos', value: '2'),
      DemoMetric(label: 'Administradores', value: '3'),
    ],
    records: [
      DemoRecord(
          id: 'demo-user-1',
          title: 'Joyce Mabel',
          subtitle: 'joyce@h3ga.local',
          status: 'Activo',
          details: {'rol': 'administrador financiero'}),
      DemoRecord(
          id: 'demo-user-2',
          title: 'Daniela Cruz',
          subtitle: 'daniela@h3ga.local',
          status: 'Activo',
          details: {'rol': 'asesor'}),
      DemoRecord(
          id: 'demo-user-3',
          title: 'Jorge Silva',
          subtitle: 'jorge@h3ga.local',
          status: 'Suspendido',
          details: {'rol': 'asesor'}),
    ],
    notes: ['Usuarios ficticios; no son credenciales ni cuentas del backend.'],
  );
}
