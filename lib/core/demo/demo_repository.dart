import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/env.dart';
import 'demo_dataset.dart';
import 'demo_fixture_registry.dart';

final demoRepositoryProvider = Provider.family<DemoRepository, String>(
  (ref, module) => DemoRepository(module),
);

class DemoRepository {
  const DemoRepository(this.module);

  final String module;

  Future<DemoDataset> load() async {
    if (!AppEnv.demoMode) {
      throw StateError('Los fixtures solo están disponibles en modo demo.');
    }
    return DemoFixtureRegistry.forModule(module);
  }
}
