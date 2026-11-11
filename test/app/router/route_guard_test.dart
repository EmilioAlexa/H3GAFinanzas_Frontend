import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/app/router/route_guard.dart';
import 'package:h3ga_finanzas/modules/auth/auth.dart';

void main() {
  const advisor = AuthSessionModel(
    id: '1',
    name: 'Asesor',
    email: 'a@example.test',
    role: UserRole.asesor,
  );

  test('sends anonymous users to login', () {
    expect(
      routeGuard(
        location: '/clientes',
        session: null,
        loading: false,
        allowedRoles: {},
      ),
      '/login',
    );
  });

  test('sends disallowed roles to dashboard', () {
    expect(
      routeGuard(
        location: '/reportes',
        session: advisor,
        loading: false,
        allowedRoles: {UserRole.administrador},
      ),
      '/dashboard',
    );
  });

  test('allows an authenticated user on a public module route', () {
    expect(
      routeGuard(
        location: '/clientes',
        session: advisor,
        loading: false,
        allowedRoles: {},
      ),
      isNull,
    );
  });
}
