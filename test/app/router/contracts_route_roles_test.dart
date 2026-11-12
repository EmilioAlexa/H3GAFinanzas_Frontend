import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/app/router/route_roles.dart';
import 'package:h3ga_finanzas/modules/auth/auth.dart';

void main() {
  test('contract and service routes allow all authenticated roles', () {
    for (final path in [
      '/servicios',
      '/servicios/m40',
      '/contratos',
      '/contratos/nuevo',
      '/contratos/demo-contract-1',
      '/contratos/demo-contract-1/editar',
    ]) {
      expect(allowedRolesForLocation(path), isEmpty, reason: path);
    }
    for (final role in UserRole.values) {
      expect(allowedRolesForLocation('/contratos').contains(role), isFalse);
    }
  });
}
