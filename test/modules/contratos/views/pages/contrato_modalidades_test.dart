import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/core/storage/token_storage.dart';
import 'package:h3ga_finanzas/modules/auth/auth.dart';
import 'package:h3ga_finanzas/modules/contratos/controllers/contrato_options_controller.dart';
import 'package:h3ga_finanzas/modules/contratos/models/servicio_model.dart';
import 'package:h3ga_finanzas/modules/contratos/repositories/contratos_repository.dart';
import 'package:h3ga_finanzas/modules/contratos/views/pages/contrato_form_page.dart';
import 'package:intl/date_symbol_data_local.dart';

class _Auth extends AuthController {
  _Auth()
      : super(AuthRepository(Dio(), const TokenStorage(FlutterSecureStorage())),
            demoMode: true, demoRole: UserRole.administrador) {
    state = const AsyncData(AuthSessionModel(
        id: 'admin-test',
        name: 'Admin',
        email: 'test@example.test',
        role: UserRole.administrador));
  }
}

Future<void> main() async {
  await initializeDateFormatting('es_MX');
  for (final scenario in [
    for (final code in ['APD', 'M10', 'M40', 'M40R'])
      for (final ready in [false, true]) (code: code, ready: ready)
  ]) {
    final code = scenario.code;
    final ready = scenario.ready;
    testWidgets(
        '$code schema=$ready uses the approved scheme and only APD exposes sale type',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 1400);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
          onRequest: (r, h) => h.resolve(Response(requestOptions: r, data: {
                'data': <dynamic>[],
                'pagination': {'totalPages': 1}
              }))));
      await tester.pumpWidget(ProviderScope(overrides: [
        authControllerProvider.overrideWith((ref) => _Auth()),
        contratosRepositoryProvider
            .overrideWithValue(ContratosRepository(demoMode: false, dio: dio)),
        contratoOptionsProvider(UserRole.administrador)
            .overrideWith((ref) async => (
                  clients: [(id: 'client', name: 'Cliente')],
                  advisors: [(id: 'advisor', name: 'Asesor')],
                  services: [
                    ServicioModel.fromJson(
                        {'id': 90, 'nombre': code, 'codigo_folio': code})
                  ],
                  states: [(id: 1, name: 'Borrador')],
                  saleTypes: [
                    (id: 76, name: 'Cambaceo'),
                    (id: 77, name: 'Marketing')
                  ],
                  advisorMessage: null,
                  documentsReady: ready
                )),
      ], child: const MaterialApp(home: Scaffold(body: ContratoFormPage()))));
      await tester.pumpAndSettle();
      final service = find.byWidgetPredicate((w) =>
          w is DropdownButtonFormField<int> &&
          w.decoration.labelText == 'Tipo de servicio');
      await tester.tap(service);
      await tester.pumpAndSettle();
      await tester.tap(find.text(code).last);
      await tester.pumpAndSettle();
      final single = code == 'APD' || code == 'M40R';
      final scheme = tester.widget<TextField>(find.byWidgetPredicate((w) =>
          w is TextField && w.decoration?.labelText == 'Esquema de pago'));
      expect(scheme.controller!.text, single ? 'Pago \u00fanico' : 'Mensual');
      final amount = tester.widget<TextField>(find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == 'Monto mensual'));
      expect(amount.enabled, !single);
      final salary = tester.widget<TextField>(find.byWidgetPredicate((w) =>
          w is TextField &&
          w.decoration?.labelText == 'Salario diario de cotizaci\u00f3n'));
      expect(salary.enabled, code != 'APD');
      final sale = find.byWidgetPredicate((w) =>
          w is DropdownButtonFormField<int> &&
          w.decoration.labelText == 'Tipo de venta');
      expect(sale, code == 'APD' ? findsOneWidget : findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
