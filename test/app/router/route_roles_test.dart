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

  test('validation queue and details only allow management roles', () {
    const management = {
      UserRole.administrador,
      UserRole.administradorFinanciero,
    };
    expect(allowedRolesForLocation('/validacion'), management);
    expect(allowedRolesForLocation('/validacion/demo-payment-1'), management);
  });

  test('commission configuration and receiver management are restricted', () {
    const management = {
      UserRole.administrador,
      UserRole.administradorFinanciero,
    };
    expect(allowedRolesForLocation('/comisiones/receptores'), management);
    expect(
      allowedRolesForLocation('/comisiones/contratos/demo/configuracion'),
      management,
    );
    expect(allowedRolesForLocation('/comisiones/demo-payment'), isEmpty);
  });

  test('all cut screens require management roles', () {
    const management = {
      UserRole.administrador,
      UserRole.administradorFinanciero,
    };
    expect(allowedRolesForLocation('/cortes'), management);
    expect(allowedRolesForLocation('/cortes/demo-cut'), management);
    expect(allowedRolesForLocation('/cortes/demo-cut/preparacion'), management);
  });

  test('all prenomina screens require management roles', () {
    const management = {
      UserRole.administrador,
      UserRole.administradorFinanciero,
    };
    expect(allowedRolesForLocation('/prenomina'), management);
    expect(
        allowedRolesForLocation('/prenomina/preparacion/demo-cut'), management);
    expect(allowedRolesForLocation('/prenomina/detalle/demo-recipient'),
        management);
    expect(allowedRolesForLocation('/prenomina/detalle/demo-recipient'),
        isNot(contains(UserRole.asesor)));
  });

  test('all report screens require management roles', () {
    const management = {
      UserRole.administrador,
      UserRole.administradorFinanciero,
    };
    expect(allowedRolesForLocation('/reportes'), management);
    expect(allowedRolesForLocation('/reportes/imss'), management);
    expect(allowedRolesForLocation('/reportes/pagos-metodo'), management);
  });
}
