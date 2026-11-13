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
import 'route_roles.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);
  final session = auth.valueOrNull;
  final router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) => routeGuard(
      location: state.uri.path,
      session: session,
      loading: auth.isLoading,
      allowedRoles: allowedRolesForLocation(state.uri.path),
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
            path: '/clientes/nuevo',
            builder: (context, state) => const clientes.ClienteFormPage(),
          ),
          GoRoute(
            path: '/clientes/:id/editar',
            builder: (context, state) => clientes.ClienteFormPage(
              clienteId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: '/clientes/:id',
            builder: (context, state) => clientes.ClienteDetallePage(
              clienteId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/servicios',
            builder: (context, state) => const contratos.ServiciosPage(),
          ),
          GoRoute(
            path: '/servicios/:servicio',
            builder: (context, state) => contratos.ServicioDetallePage(
              servicioClave: state.pathParameters['servicio']!,
            ),
          ),
          GoRoute(
            path: '/contratos',
            builder: (context, state) => const contratos.ContratosPage(),
          ),
          GoRoute(
            path: '/contratos/nuevo',
            builder: (context, state) => const contratos.ContratoFormPage(),
          ),
          GoRoute(
            path: '/contratos/:id/editar',
            builder: (context, state) => contratos.ContratoFormPage(
              contratoId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: '/contratos/:id',
            builder: (context, state) => contratos.ContratoDetallePage(
              contratoId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/pagos',
            builder: (context, state) => const pagos.PagosPage(),
          ),
          GoRoute(
            path: '/pagos/nuevo',
            builder: (context, state) => const pagos.PagoFormPage(),
          ),
          GoRoute(
            path: '/pagos/:id',
            builder: (context, state) => pagos.PagoDetallePage(
              paymentId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/pagos-programados',
            builder: (context, state) => const pagos.PagosProgramadosPage(),
          ),
          GoRoute(
            path: '/pagos-programados/nuevo',
            builder: (context, state) => const pagos.PagoProgramadoFormPage(),
          ),
          GoRoute(
            path: '/validacion',
            builder: (context, state) => const validacion.ValidacionPage(),
          ),
          GoRoute(
            path: '/validacion/:id',
            builder: (context, state) => validacion.ValidacionDetallePage(
              paymentId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/comisiones',
            builder: (context, state) => const comisiones.ComisionesPage(),
          ),
          GoRoute(
            path: '/comisiones/receptores',
            builder: (context, state) => const comisiones.ReceptoresPage(),
          ),
          GoRoute(
            path: '/comisiones/contratos/:id/configuracion',
            builder: (context, state) => comisiones.ComisionConfiguracionPage(
              contractId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/comisiones/:id',
            builder: (context, state) => comisiones.ComisionDetallePage(
              paymentId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/cortes',
            builder: (context, state) => const cortes.CortesPage(),
          ),
          GoRoute(
            path: '/cortes/:id/preparacion',
            builder: (context, state) => cortes.CortePreparacionPage(
              cutId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/cortes/:id',
            builder: (context, state) => cortes.CorteDetallePage(
              cutId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/prenomina/preparacion/:id',
            builder: (context, state) => prenomina.PrenominaPreparacionPage(
              cutId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/prenomina/detalle/:id',
            builder: (context, state) => prenomina.PrenominaDetallePage(
              recipientId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/prenomina',
            builder: (context, state) => const prenomina.PrenominaPage(),
          ),
          GoRoute(
            path: '/reportes/:reportType',
            builder: (context, state) => reportes.ReportesPage(
              reportType: reportes.ReportType.fromKey(
                state.pathParameters['reportType'],
              ),
            ),
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
