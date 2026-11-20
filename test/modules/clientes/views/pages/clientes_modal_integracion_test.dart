import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/app/theme/app_theme.dart';
import 'package:h3ga_finanzas/core/storage/token_storage.dart';
import 'package:h3ga_finanzas/core/widgets/app_dialog.dart';
import 'package:h3ga_finanzas/modules/auth/auth.dart';
import 'package:h3ga_finanzas/modules/clientes/clientes.dart';

class AdvisorSession extends AuthController {
  AdvisorSession()
      : super(AuthRepository(Dio(), const TokenStorage(FlutterSecureStorage())),
            demoMode: false, demoRole: UserRole.asesor) {
    state = const AsyncData(AuthSessionModel(
        id: 'advisor-test',
        name: 'Asesor Prueba',
        email: 'asesor@example.test',
        role: UserRole.asesor));
  }
}

void main() {
  testWidgets(
      'detalle real conserva las pestañas y evita movimientos ficticios',
      (tester) async {
    const id = '00000000-0000-4000-8000-000000000001';
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      handler.resolve(Response(requestOptions: options, data: <String, dynamic>{
        'id': id,
        'nombre': 'Ana',
        'apellido_paterno': 'Prueba',
        'pausado': false
      }));
    }));
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 900);
    await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => AdvisorSession()),
          clientesRepositoryProvider.overrideWith(
              (ref) => ClientesRepository(demoMode: false, dio: dio)),
        ],
        child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: ClienteDetallePage(clienteId: id)))));
    await tester.pumpAndSettle();
    expect(find.text('Servicios y contratos'), findsOneWidget);
    expect(find.text('Pagos'), findsOneWidget);
    expect(find.text('Historial'), findsOneWidget);
    expect(find.text('Información financiera aún no conectada.'), findsWidgets);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('registro usa Referido por como texto libre sin selector UUID',
      (tester) async {
    const referidor = '00000000-0000-4000-8000-000000000002';
    final requests = <RequestOptions>[];
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      requests.add(options);
      final item = <String, dynamic>{
        'id': referidor,
        'nombre': 'Referencia',
        'apellido_paterno': 'Prueba',
        'pausado': false
      };
      final Object body = options.method == 'GET'
          ? {
              'data': [item],
              'pagination': {'page': 1, 'total': 1, 'totalPages': 1}
            }
          : item;
      handler.resolve(
          Response(requestOptions: options, statusCode: 200, data: body));
    }));
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => AdvisorSession()),
          clientesRepositoryProvider.overrideWith(
              (ref) => ClientesRepository(demoMode: false, dio: dio)),
        ],
        child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: ClientesPage()))));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Registrar cliente'));
    await tester.pumpAndSettle();
    for (final entry in <int, String>{
      0: 'Ana',
      1: 'Prueba',
      2: 'Ejemplo',
      3: '000',
      5: 'LODM800101MQRPRR09',
      6: 'LODM800101AAA'
    }.entries) {
      await tester.enterText(
          find.byType(TextFormField).at(entry.key), entry.value);
    }
    expect(find.text('Referido por'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(9), 'Maria Referidora');
    await tester.ensureVisible(find.text('Guardar').last);
    await tester.tap(find.text('Guardar').last);
    await tester.pumpAndSettle();
    final post = requests.singleWhere((request) => request.method == 'POST');
    expect((post.data as Map).containsKey('referido_por_cliente_id'), false);
    expect((post.data as Map)['referido_por'], 'Maria Referidora');
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('edición consulta detalle y conserva PATCH en modal original',
      (tester) async {
    const id = '00000000-0000-4000-8000-000000000001';
    final requests = <RequestOptions>[];
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      requests.add(options);
      final item = <String, dynamic>{
        'id': id,
        'nombre': 'Ana',
        'apellido_paterno': 'Prueba',
        'apellido_materno': 'Ejemplo',
        'telefono': '000',
        'correo_electronico': null,
        'curp': 'LODM800101MQRPRR09',
        'rfc': 'LODM800101AAA',
        'fecha_ingreso': '2020-01-02T00:00:00.000Z',
        'fecha_nacimiento': '1990-02-28T00:00:00.000Z',
        'domicilio': 'Calle Uno',
        'referido_por': 'Maria Referidora',
        'observaciones_generales': 'Observacion existente',
        'pausado': false
      };
      final Object body = options.method == 'GET' && options.path == '/clientes'
          ? {
              'data': [item],
              'pagination': {'page': 1, 'total': 1, 'totalPages': 1}
            }
          : item;
      handler.resolve(
          Response(requestOptions: options, statusCode: 200, data: body));
    }));
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => AdvisorSession()),
          clientesRepositoryProvider.overrideWith(
              (ref) => ClientesRepository(demoMode: false, dio: dio)),
        ],
        child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: ClientesPage()))));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Acciones de Ana Prueba Ejemplo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar cliente').last);
    await tester.pumpAndSettle();
    expect(find.byType(AppDialog), findsOneWidget);
    expect(
        requests.any((request) =>
            request.method == 'GET' && request.path == '/clientes/$id'),
        true);
    expect(find.text('Fecha de nacimiento *'), findsOneWidget);
    expect(find.text('28/02/1990'), findsOneWidget);
    expect(find.text('Calle Uno'), findsOneWidget);
    expect(find.text('Maria Referidora'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Ana Editada');
    await tester.ensureVisible(find.text('Guardar').last);
    await tester.tap(find.text('Guardar').last);
    await tester.pumpAndSettle();
    final changes =
        requests.where((request) => request.method == 'PATCH').toList();
    expect(changes, hasLength(1));
    expect(changes.single.path, '/clientes/$id');
    expect(changes.single.data, containsPair('nombre', 'Ana Editada'));
    expect(changes.single.data, containsPair('fecha_nacimiento', '1990-02-28'));
    expect(changes.single.data, containsPair('domicilio', 'Calle Uno'));
    expect(changes.single.data,
        containsPair('referido_por', 'Maria Referidora'));
    expect(changes.single.data,
        containsPair('observaciones_generales', 'Observacion existente'));
    expect(changes.single.data, isNot(contains('fecha_ingreso')));
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('modal original en modo real conserva campos y envía solo DTO',
      (tester) async {
    const id = '00000000-0000-4000-8000-000000000001';
    final requests = <RequestOptions>[];
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      requests.add(options);
      final item = <String, dynamic>{
        'id': id,
        'nombre': 'Ana',
        'apellido_paterno': 'Prueba',
        'apellido_materno': 'Ejemplo',
        'telefono': '000',
        'correo_electronico': null,
        'curp': 'LODM800101MQRPRR09',
        'rfc': 'LODM800101AAA',
        'pausado': false
      };
      final Object body = options.method == 'GET' && options.path == '/clientes'
          ? {
              'data': [item],
              'pagination': {'page': 1, 'total': 1, 'totalPages': 1}
            }
          : item;
      handler.resolve(Response(
          requestOptions: options,
          statusCode: options.method == 'POST' ? 201 : 200,
          data: body));
    }));
    for (final size in [const Size(390, 844), const Size(1280, 900)]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      await tester.pumpWidget(ProviderScope(
          overrides: [
            authControllerProvider.overrideWith((ref) => AdvisorSession()),
            clientesRepositoryProvider.overrideWith(
                (ref) => ClientesRepository(demoMode: false, dio: dio)),
          ],
          child: MaterialApp(
              theme: AppTheme.light,
              home: const Scaffold(body: ClientesPage()))));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Registrar cliente'));
      await tester.pumpAndSettle();
      expect(find.byType(AppDialog), findsOneWidget);
      for (final label in [
        'Nombre *',
        'Apellido paterno *',
        'Apellido materno *',
        'Teléfono *',
        'CURP',
        'RFC',
        'Fecha de nacimiento *',
        'Dirección',
        'Referido por',
        'Observaciones'
      ]) {
        expect(find.text(label), findsOneWidget, reason: '$label en $size');
      }
      expect(find.text('Aún no disponible para guardar'), findsNothing);
      expect(tester.takeException(), isNull);
      if (size.width < 1000) {
        await tester.ensureVisible(find.text('Cancelar').last);
        await tester.tap(find.text('Cancelar').last);
        await tester.pumpAndSettle();
      } else {
        for (final entry in <int, String>{
          0: 'Ana',
          1: 'Prueba',
          2: 'Ejemplo',
          3: '000',
          5: 'lodm800101mqrprr09extra',
          6: 'abc010101a12'
        }.entries) {
          await tester.enterText(
              find.byType(TextFormField).at(entry.key), entry.value);
        }
        final dateField = find.byType(TextFormField).at(7);
        await tester.ensureVisible(dateField);
        await tester.tap(dateField);
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Guardar').last);
        await tester.tap(find.text('Guardar').last);
        await tester.pumpAndSettle();
      }
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    final writes =
        requests.where((request) => request.method == 'POST').toList();
    expect(writes, hasLength(1));
    expect(writes.single.data, containsPair('curp', 'LODM800101MQRPRR09'));
    expect(writes.single.data, containsPair('rfc', 'ABC010101A12'));
    expect((writes.single.data as Map).keys.toSet(), {
      'nombre',
      'apellido_paterno',
      'apellido_materno',
      'telefono',
      'correo_electronico',
      'curp',
      'rfc',
      'fecha_nacimiento',
      'domicilio',
      'referido_por',
      'observaciones_generales'
    });
  });
}
