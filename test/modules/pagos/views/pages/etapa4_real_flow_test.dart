import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/app/theme/app_theme.dart';
import 'package:h3ga_finanzas/core/storage/token_storage.dart';
import 'package:h3ga_finanzas/modules/auth/auth.dart';
import 'package:h3ga_finanzas/modules/contratos/models/contrato_model.dart';
import 'package:h3ga_finanzas/modules/pagos/controllers/pago_options_controller.dart';
import 'package:h3ga_finanzas/modules/pagos/controllers/pagos_controller.dart';
import 'package:h3ga_finanzas/modules/pagos/models/pago_model.dart';
import 'package:h3ga_finanzas/modules/pagos/repositories/pagos_repository.dart';
import 'package:h3ga_finanzas/modules/pagos/views/pages/pago_form_page.dart';
import 'package:h3ga_finanzas/modules/validacion/views/pages/validacion_detalle_page.dart';
import 'package:intl/date_symbol_data_local.dart';

const _id = '00000000-0000-4000-8000-000000000001';
PagoModel _payment(String state, {String actor = _id}) => PagoModel.fromJson({
      'id': _id,
      'contrato_id': _id,
      'forma_pago_id': 72,
      'estado_pago_id': 19,
      'monto': '10.00',
      'fecha_pago': null,
      'registrado_por': actor,
      'formas_pago': {'nombre': 'Efectivo'},
      'estados_pago': {'nombre': state},
      'contratos': {
        'folio': 'APD Test',
        'cliente_id': _id,
        'asesor_id': _id,
        'clientes': {'nombre': 'Cliente Test'},
        'servicios': {'nombre': 'APD'}
      },
    });

Future<void> main() async {
  await initializeDateFormatting('es_MX');
  PagosRepository repository() {
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(
        onRequest: (request, handler) =>
            handler.resolve(Response(requestOptions: request, data: {
              'data': <Object>[],
              'pagination': {'page': 1, 'total': 0, 'totalPages': 0},
            }))));
    return PagosRepository(dio: dio);
  }

  Widget page(Widget child, UserRole role, {PagoModel? payment}) =>
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => _Auth(role)),
          pagosRepositoryProvider.overrideWithValue(repository()),
          pagoOptionsProvider.overrideWith((ref, role) async => (
                contracts: <ContratoModel>[],
                methods: <PagoOption>[],
                chargeTypes: <PagoOption>[],
                receivers: <PaymentReceiver>[],
                receiverMessage: null,
                methodError: null,
                chargeError: null,
              )),
          if (payment != null)
            pagoDetailProvider(_id).overrideWith((ref) async => payment),
        ],
        child: MaterialApp(theme: AppTheme.light, home: Scaffold(body: child)),
      );
  testWidgets(
      'formulario real conserva secciones con catálogos vacíos y bloquea alta',
      (tester) async {
    await tester.pumpWidget(page(const PagoFormPage(), UserRole.asesor));
    await tester.pumpAndSettle();
    expect(find.text('Relación del pago'), findsOneWidget);
    expect(find.text('Información del pago'), findsOneWidget);
    expect(find.text('Evidencia'), findsOneWidget);
    expect(find.text('No hay métodos de pago activos.'), findsOneWidget);
    final button =
        find.widgetWithText(FilledButton, 'Registrar y enviar a revisión');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets('financiero no puede enviar a autorización sin evidencia vigente',
      (tester) async {
    await tester.pumpWidget(page(const ValidacionDetallePage(paymentId: _id),
        UserRole.administradorFinanciero,
        payment: _payment('Pendiente de revisión financiera')));
    await tester.pumpAndSettle();
    final approve = find.widgetWithText(FilledButton, 'Enviar a autorización');
    expect(tester.widget<FilledButton>(approve).onPressed, isNull);
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Rechazar pago'))
            .onPressed,
        isNotNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets('corrección queda bloqueada si otro usuario registró el pago',
      (tester) async {
    await tester.pumpWidget(page(
        const PagoFormPage(paymentId: _id), UserRole.asesor,
        payment: _payment('Rechazado',
            actor: '00000000-0000-4000-8000-000000000002')));
    await tester.pumpAndSettle();
    expect(find.text('Pago no editable'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _Auth extends AuthController {
  _Auth(UserRole role)
      : super(AuthRepository(Dio(), const TokenStorage(FlutterSecureStorage())),
            demoMode: true, demoRole: role) {
    state = AsyncData(AuthSessionModel(
        id: _id, name: 'Sesión Test', email: 'test@example.test', role: role));
  }
}
