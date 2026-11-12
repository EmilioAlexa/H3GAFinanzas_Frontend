import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/app/router/route_roles.dart';
import 'package:h3ga_finanzas/modules/auth/auth.dart';

void main() {
  test('only advisor can open client creation route', () {
    expect(
      allowedRolesForLocation('/clientes/nuevo'),
      {UserRole.asesor},
    );
  });

  test('admin and assigned advisor roles can open client editing route', () {
    expect(
      allowedRolesForLocation('/clientes/demo-client-1/editar'),
      {UserRole.administrador, UserRole.asesor},
    );
  });

  test('client details allow every signed-in role', () {
    expect(allowedRolesForLocation('/clientes/demo-client-1'), isEmpty);
  });
}
