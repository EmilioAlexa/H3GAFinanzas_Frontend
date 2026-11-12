import '../../../core/demo/demo_dataset.dart';
import '../../../core/demo/demo_record.dart';

abstract final class AuthDemoFixtures {
  static const dataset = DemoDataset(
    module: 'auth',
    records: [
      DemoRecord(
        id: 'demo-admin',
        title: 'Joyce Mabel',
        subtitle: 'demo@h3ga.local',
        status: 'administrador',
      ),
    ],
    notes: ['La sesión y las credenciales no existen en el backend.'],
  );
}
