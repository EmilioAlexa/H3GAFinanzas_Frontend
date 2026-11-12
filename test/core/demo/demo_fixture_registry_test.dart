import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/core/demo/demo_fixture_registry.dart';

void main() {
  test('provides a non-empty labelled demo dataset for every module', () {
    expect(
        DemoFixtureRegistry.all.keys,
        containsAll([
          'auth',
          'dashboard',
          'clientes',
          'contratos',
          'pagos',
          'validacion',
          'comisiones',
          'cortes',
          'prenomina',
          'reportes',
          'usuarios',
        ]));
    for (final dataset in DemoFixtureRegistry.all.values) {
      expect(dataset.isEmpty, isFalse, reason: dataset.module);
      expect(dataset.notes, isNotEmpty, reason: dataset.module);
    }
  });
}
