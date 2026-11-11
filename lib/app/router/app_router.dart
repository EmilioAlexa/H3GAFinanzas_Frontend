import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/shell/app_shell.dart';
import '../../modules/auth/auth.dart';
import '../../modules/clientes/clientes.dart' as clientes;
import '../../modules/comisiones/comisiones.dart' as comisiones;
import '../../modules/contratos/contratos.dart' as contratos;
import '../../modules/cortes/cortes.dart' as cortes;
import '../../modules/dashboard/dashboard.dart' as dashboard;
import '../../modules/pagos/pagos.dart' as pagos;
import '../../modules/prenomina/prenomina.dart' as prenomina;
import '../../modules/reportes/reportes.dart' as reportes;
import '../../modules/usuarios/usuarios.dart' as usuarios;
import '../../modules/validacion/validacion.dart' as validacion;
import 'route_guard.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);
  final session = auth.valueOrNull;
  final router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) => routeGuard(
      location: state.uri.path,
      session: session,
      loading: auth.isLoading,
      allowedRoles: _allowedRoles(state.uri.path),
    ),
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      ShellRoute(
        builder: (context, state, child) => AppShell(
          session: session ??
              const AuthSessionModel(
                id: '',
                name: '',
                email: '',
                role: UserRole.asesor,
              ),
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const dashboard.DashboardPage(),
          ),
          GoRoute(
            path: '/clientes',
            builder: (context, state) => const clientes.ClientesPage(),
          ),
          GoRoute(
            path: '/contratos',
            builder: (context, state) => const contratos.ContratosPage(),
          ),
          GoRoute(
            path: '/pagos',
            builder: (context, state) => const pagos.PagosPage(),
          ),
          GoRoute(
            path: '/validacion',
            builder: (context, state) => const validacion.ValidacionPage(),
          ),
          GoRoute(
            path: '/comisiones',
            builder: (context, state) => const comisiones.ComisionesPage(),
          ),
          GoRoute(
            path: '/cortes',
            builder: (context, state) => const cortes.CortesPage(),
          ),
          GoRoute(
            path: '/prenomina',
            builder: (context, state) => const prenomina.PrenominaPage(),
          ),
          GoRoute(
            path: '/reportes',
            builder: (context, state) => const reportes.ReportesPage(),
          ),
          GoRoute(
            path: '/usuarios',
            builder: (context, state) => const usuarios.UsuariosPage(),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

Set<UserRole> _allowedRoles(String path) => switch (path) {
      '/cortes' || '/prenomina' || '/reportes' => {
          UserRole.administrador,
          UserRole.administradorFinanciero
        },
      '/usuarios' => {UserRole.administrador},
      _ => {},
    };
