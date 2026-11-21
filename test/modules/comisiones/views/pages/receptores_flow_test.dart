import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:h3ga_finanzas/app/router/route_roles.dart';
import 'package:h3ga_finanzas/app/theme/app_theme.dart';
import 'package:h3ga_finanzas/core/network/finanzas_api.dart';
import 'package:h3ga_finanzas/core/storage/token_storage.dart';
import 'package:h3ga_finanzas/modules/auth/auth.dart';
import 'package:h3ga_finanzas/modules/comisiones/controllers/comisiones_controller.dart';
import 'package:h3ga_finanzas/modules/comisiones/repositories/comisiones_repository.dart';
import 'package:h3ga_finanzas/modules/comisiones/views/pages/comisiones_page.dart';
import 'package:h3ga_finanzas/modules/comisiones/views/pages/receptores_page.dart';

void main() {
  testWidgets(
      'admin opens existing page and creates first advisor receiver, reloads and deactivates',
      (tester) async {
    final requests = <RequestOptions>[];
    final receivers = <Map<String, dynamic>>[];
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (r, h) {
      requests.add(r);
      Object data;
      if (r.path == '/finanzas/comisiones') {
        data = {'data': <dynamic>[], 'total': 0};
      } else if (r.path == '/finanzas/catalogos/conceptos-dispersion') {
        data = [
          {'id': 1, 'nombre': 'Asesor', 'tipo_destino': 'usuario'}
        ];
      } else if (r.path == '/usuarios') {
        data = [
          {
            'id': 'advisor-real',
            'nombre': 'Ana',
            'apellido_paterno': 'Paz',
            'activo': true,
            'roles': {'nombre': 'asesor'}
          },
          {
            'id': 'inactive',
            'nombre': 'Inactivo',
            'activo': false,
            'roles': {'nombre': 'asesor'}
          },
        ];
      } else if (r.path == '/finanzas/receptores-dispersion' &&
          r.method == 'POST') {
        expect(r.data, {'concepto_id': 1, 'usuario_id': 'advisor-real'});
        receivers.add({
          'id': 'receiver-real',
          'concepto_id': 1,
          'usuario_id': 'advisor-real',
          'activo': true,
          'conceptos_dispersion': {'nombre': 'Asesor'},
          'usuarios_receptor': {'nombre': 'Ana', 'apellido_paterno': 'Paz'}
        });
        data = receivers.single;
      } else if (r.path.endsWith('/desactivar')) {
        receivers.clear();
        data = {'activo': false};
      } else if (r.path == '/finanzas/receptores-dispersion') {
        data = List.of(receivers);
      } else {
        fail('Unexpected HTTP ${r.method} ${r.path}');
      }
      h.resolve(Response(requestOptions: r, data: data));
    }));
    final container = ProviderContainer(overrides: [
      authControllerProvider
          .overrideWith((ref) => _Session(UserRole.administrador)),
      comisionesControllerProvider.overrideWith((ref, role) =>
          ComisionesController(ComisionesRepository(api: FinanzasApi(dio)), role,
              demoMode: false)),
    ]);
    addTearDown(container.dispose);
    final router = GoRouter(initialLocation: '/comisiones', routes: [
      GoRoute(
          path: '/comisiones',
          builder: (_, __) => const Scaffold(body: ComisionesPage())),
      GoRoute(
          path: '/comisiones/receptores',
          builder: (_, __) => const Scaffold(body: ReceptoresPage())),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child:
            MaterialApp.router(theme: AppTheme.light, routerConfig: router)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Administrar receptores'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path,
        '/comisiones/receptores');
    await tester.tap(find.text('Agregar receptor'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Asesor').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(find.textContaining('Inactivo'), findsNothing);
    await tester.tap(find.textContaining('Ana Paz').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Agregar'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Ana Paz'), findsOneWidget);
    final controller = container
        .read(comisionesControllerProvider(UserRole.administrador).notifier);
    expect(controller.activeReceiversFor(1).single.id, 'receiver-real');
    expect(controller.activeReceiversFor(2), isEmpty);
    expect(
        requests
            .where((r) =>
                r.method == 'GET' &&
                r.path == '/finanzas/receptores-dispersion')
            .length,
        2);
    await tester.tap(find.byTooltip('Desactivar Ana Paz'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Desactivar'));
    await tester.pumpAndSettle();
    expect(controller.activeReceiversFor(1), isEmpty);
    expect(
        requests.any((r) =>
            r.method == 'PATCH' &&
            r.path ==
                '/finanzas/receptores-dispersion/receiver-real/desactivar'),
        isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('advisor has no management access', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [
      authControllerProvider.overrideWith((ref) => _Session(UserRole.asesor)),
    ], child: const MaterialApp(home: Scaffold(body: ReceptoresPage()))));
    await tester.pumpAndSettle();
    expect(find.text('Acceso restringido'), findsOneWidget);
    expect(find.text('Agregar receptor'), findsNothing);
    expect(allowedRolesForLocation('/comisiones/receptores'),
        isNot(contains(UserRole.asesor)));
  });

  test('financial administrator never requests administrator user directory',
      () async {
    final paths = <String>[];
    final dio = Dio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (r, h) {
        paths.add(r.path);
        h.resolve(Response(
            requestOptions: r,
            data: r.path == '/finanzas/comisiones'
                ? {'data': <dynamic>[], 'total': 0}
                : <dynamic>[]));
      }));
    final repository = ComisionesRepository(api: FinanzasApi(dio));
    await repository.loadReal(UserRole.administradorFinanciero);
    expect(paths, isNot(contains('/usuarios')));
    expect(repository.eligibleAdvisorUsers, isEmpty);
  });
}

class _Session extends AuthController {
  _Session(UserRole role)
      : super(AuthRepository(Dio(), const TokenStorage(FlutterSecureStorage())),
            demoMode: true, demoRole: role) {
    state = AsyncData(AuthSessionModel(
        id: 'test-session',
        name: 'Test',
        email: 'test@example.test',
        role: role));
  }
}
