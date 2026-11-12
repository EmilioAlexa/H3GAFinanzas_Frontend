import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/core/shell/shell_navigation.dart';
import 'package:h3ga_finanzas/modules/auth/auth.dart';

void main() {
  group('visibleShellItems', () {
    test('asesor only sees routes allowed for the role', () {
      final paths =
          visibleShellItems(UserRole.asesor).map((item) => item.path).toSet();

      expect(paths, containsAll(['/dashboard', '/clientes', '/contratos']));
      expect(paths, isNot(contains('/validacion')));
      expect(paths, isNot(contains('/cortes')));
      expect(paths, isNot(contains('/prenomina')));
      expect(paths, isNot(contains('/reportes')));
      expect(paths, isNot(contains('/usuarios')));
    });

    test('both management roles see finance routes', () {
      for (final role in [
        UserRole.administrador,
        UserRole.administradorFinanciero,
      ]) {
        final paths = visibleShellItems(role).map((item) => item.path).toSet();
        expect(
          paths,
          containsAll([
            '/validacion',
            '/cortes',
            '/prenomina',
            '/reportes',
          ]),
        );
      }
    });

    test('only administrator sees user management', () {
      expect(
        visibleShellItems(UserRole.administrador).map((item) => item.path),
        contains('/usuarios'),
      );
      expect(
        visibleShellItems(UserRole.administradorFinanciero)
            .map((item) => item.path),
        isNot(contains('/usuarios')),
      );
    });
  });

  test('route guards use the same roles as navigation visibility', () {
    for (final item in shellItems) {
      for (final role in UserRole.values) {
        expect(
          item.isVisibleFor(role),
          allowedRolesForRoute(item.path).isEmpty ||
              allowedRolesForRoute(item.path).contains(role),
          reason: 'Navigation and route policy differ for ${item.path}',
        );
      }
    }
  });
}
