import 'dart:typed_data';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/core/platform/selected_file.dart';
import 'package:h3ga_finanzas/modules/auth/auth.dart';
import 'package:h3ga_finanzas/modules/pagos/controllers/pagos_controller.dart';
import 'package:h3ga_finanzas/modules/pagos/models/pago_model.dart';
import 'package:h3ga_finanzas/modules/pagos/models/pago_programado_model.dart';
import 'package:h3ga_finanzas/modules/pagos/models/pago_review_policy.dart';
import 'package:h3ga_finanzas/modules/pagos/repositories/pagos_repository.dart';

void main() {
  const id = '00000000-0000-4000-8000-000000000001';
  const evidence = {
    'id': id,
    'vigente': true,
    'nombre_original': 'recibo.pdf',
    'tipo_archivo': 'application/pdf',
    'tamano_bytes': 12,
    'fecha_carga': '2026-11-20T15:00:00Z',
    'tipos_evidencia_pago': {'nombre': 'Comprobante bancario'}
  };
  const payment = {
    'id': id,
    'contrato_id': id,
    'forma_pago_id': 72,
    'estado_pago_id': 19,
    'monto': '9999999999.99',
    'fecha_pago': null,
    'registrado_por': id,
    'fecha_registro': '2026-11-20T15:00:00Z',
    'referencia_pago': 'REF',
    'formas_pago': {'nombre': 'Transferencia electrónica'},
    'estados_pago': {'nombre': 'Pendiente de revisión financiera'},
    'contratos': {
      'folio': 'M40202600001',
      'cliente_id': id,
      'asesor_id': id,
      'clientes': {'nombre': 'Cliente', 'apellido_paterno': 'Test'},
      'servicios': {'nombre': 'Modalidad 40'},
      'usuarios': {'nombre': 'Asesor'}
    },
    'evidencias_pago': [evidence]
  };
  late Dio dio;
  late PagosRepository repository;
  late List<RequestOptions> requests;
  setUp(() {
    requests = [];
    dio = Dio();
    repository = PagosRepository(dio: dio);
    dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
      requests.add(request);
      Object data = payment;
      if (request.path == '/finanzas/pagos' && request.method == 'GET') {
        data = {
          'data': [payment],
          'pagination': {
            'page': request.queryParameters['page'],
            'total': 2,
            'totalPages': 2
          }
        };
      } else if (request.path == '/finanzas/pagos-programados') {
        data = {
          'data': <Object>[],
          'pagination': {'totalPages': 0}
        };
      } else if (request.path.endsWith('/historial')) {
        data = [
          {
            'fecha_cambio': '2026-11-20T15:00:00Z',
            'comentario': 'Registrado',
            'estados_pago_historial_estados_pago_estado_nuevo_idToestados_pago':
                {'nombre': 'Pendiente de revisión financiera'},
            'usuarios': {'nombre': 'Actor'}
          }
        ];
      } else if (request.path.endsWith('/correcciones')) {
        data = [
          {
            'motivo': 'Importe corregido',
            'monto_anterior': '10.00',
            'monto_nuevo': '12.00'
          }
        ];
      } else if (request.path.endsWith('/evidencias')) {
        data = request.method == 'POST' ? evidence : [evidence];
      } else if (request.path.endsWith('/descargar')) {
        data = Uint8List.fromList('%PDF-test'.codeUnits);
      }
      handler.resolve(Response(requestOptions: request, data: data));
    }));
  });
  test('paginación HTTP conserva precisión y fechas históricas nulas',
      () async {
    final rows = await repository.payments();
    expect(rows, hasLength(2));
    expect(requests.map((e) => e.queryParameters['page']), [1, 2]);
    expect(rows.first.monto, Decimal.parse('9999999999.99'));
    expect(rows.first.fechaPago, isNull);
    expect(rows.first.folio, id);
    expect(rows.first.clienteNombre, 'Cliente Test');
    expect(rows.first.formaPagoId, 72);
  });
  test('detalle carga evidencias privadas, historial y correcciones', () async {
    final result = await repository.detail(id);
    expect(result.hasEvidenceForApproval, isTrue);
    expect(result.evidencias.single.demoOnly, isFalse);
    expect(result.historial.single, contains('Actor'));
    expect(result.correcciones.single['motivo'], 'Importe corregido');
    expect(
        requests.map((e) => e.path),
        containsAll([
          '/finanzas/pagos/$id',
          '/finanzas/pagos/$id/evidencias',
          '/finanzas/pagos/$id/historial',
          '/finanzas/pagos/$id/correcciones'
        ]));
  });
  test('alta, corrección y revisión usan rutas y cuerpos distintos', () async {
    final payload = <String, dynamic>{
      'contrato_id': id,
      'forma_pago_id': 72,
      'monto': '1234.50',
      'fecha_pago': '2026-11-20T15:00:00Z'
    };
    await repository.create(payload);
    expect(requests.last.method, 'POST');
    expect(requests.last.data, isNot(contains('estado_pago_id')));
    expect(requests.last.data, isNot(contains('folio')));
    expect((requests.last.data as Map<String, dynamic>)['monto'], '1234.50');
    await repository.correct(id, {'motivo': 'Corrección', 'monto': '100.00'});
    expect(requests.last.path, '/finanzas/pagos/$id/corregir');
    expect(requests.last.method, 'PATCH');
    await repository.review(id, 'rechazar', ' Motivo ');
    expect(requests.last.path, '/finanzas/pagos/$id/estado');
    expect(requests.last.data, {'accion': 'rechazar', 'comentario': 'Motivo'});
  });
  test('multipart solo file y descarga autenticada en bytes', () async {
    await repository.upload(
        id,
        SelectedFile(
            name: 'recibo.pdf',
            bytes: Uint8List.fromList('%PDF-test'.codeUnits)));
    final data = requests.last.data as FormData;
    expect(data.files.single.key, 'file');
    expect(data.files.single.value.contentType.toString(), 'application/pdf');
    expect(data.fields, isEmpty);
    expect(await repository.download(id), '%PDF-test'.codeUnits);
    expect(requests.last.responseType, ResponseType.bytes);
    expect(requests.last.path, '/finanzas/evidencias/$id/descargar');
  });
  test('evidencia sustituida o de otro método no autoriza aprobación', () {
    for (final badEvidence in [
      {...evidence, 'vigente': false},
      {
        ...evidence,
        'tipos_evidencia_pago': {'nombre': 'Comprobante de efectivo'}
      },
    ]) {
      final model = PagoModel.fromJson({
        ...payment,
        'evidencias_pago': [badEvidence]
      });
      expect(model.hasEvidenceForApproval, isFalse);
      expect(paymentReviewActions(model, UserRole.administradorFinanciero),
          ['rechazar']);
      expect(paymentReviewActions(model, UserRole.administrador), ['rechazar']);
    }
  });
  test(
      'matriz de permisos respeta estados iniciales, autorización y terminales',
      () {
    final initial = PagoModel.fromJson(payment);
    expect(paymentReviewActions(initial, UserRole.asesor), isEmpty);
    expect(paymentReviewActions(initial, UserRole.administradorFinanciero),
        ['rechazar', 'enviar_a_autorizacion']);
    expect(paymentReviewActions(initial, UserRole.administrador),
        ['rechazar', 'validar']);
    final waiting = PagoModel.fromJson({
      ...payment,
      'estados_pago': {'nombre': 'Pendiente de autorización'}
    });
    expect(paymentReviewActions(waiting, UserRole.administradorFinanciero),
        isEmpty);
    expect(paymentReviewActions(waiting, UserRole.administrador),
        ['rechazar', 'validar']);
    for (final state in ['Validado', 'Rechazado', 'Cancelado']) {
      final closed = PagoModel.fromJson({
        ...payment,
        'estados_pago': {'nombre': state}
      });
      expect(paymentReviewActions(closed, UserRole.administrador), isEmpty);
    }
  });
  test('cobranza usa saldo y estado del servidor sin calcularlos', () {
    final model = PagoProgramadoModel.fromJson({
      'id': id,
      'contrato_id': id,
      'numero_pago': 1,
      'fecha_vencimiento': '2026-11-20T00:00:00Z',
      'monto_esperado': '1000.00',
      'estado_operativo': {'id': 17, 'nombre': 'Parcial'},
      'estados_pago_programado': {'nombre': 'Pendiente'},
      'monto_abonado_validado': '12.00',
      'saldo_pendiente_confirmado': '50.00',
      'pagos': <Object>[]
    });
    expect(model.saldoPendienteConfirmado, Decimal.parse('50.00'));
    expect(model.estado, 'Parcial');
    expect(model.fechaVencimiento!.day, 20);
    final unknown = PagoProgramadoModel.fromJson({
      'id': id,
      'contrato_id': id,
      'numero_pago': 2,
      'saldo_pendiente_confirmado': null,
      'motivo_saldo_no_disponible': 'IMPORTE_NO_DEFINIDO'
    });
    expect(unknown.saldoPendienteConfirmado, isNull);
  });
  test('errores HTTP nunca recuperan fixtures', () async {
    dio.interceptors.clear();
    dio.interceptors.add(InterceptorsWrapper(
        onRequest: (request, handler) => handler.reject(DioException(
            requestOptions: request,
            response: Response(requestOptions: request, statusCode: 403)))));
    await expectLater(repository.payments(), throwsA(isA<DioException>()));
    await expectLater(repository.detail(id), throwsA(isA<DioException>()));
  });
  test('programación usa vencimiento civil y cancelación auditada sin cambiar estado por ID', () async {
    dio.interceptors.insert(0, InterceptorsWrapper(onRequest: (request, handler) {
      if (request.path.startsWith('/finanzas/pagos-programados') && request.method != 'GET') {
        requests.add(request);
        handler.resolve(Response(requestOptions: request, data: {
          'id': id, 'contrato_id': id, 'numero_pago': 1,
          'fecha_vencimiento': '2026-11-20T00:00:00Z',
          'estados_pago_programado': {'nombre': request.method == 'PATCH' ? 'Cancelado' : 'Pendiente'},
        }));
      } else { handler.next(request); }
    }));
    final original = PagoProgramadoModel.fromJson({'id': id, 'contrato_id': id, 'numero_pago': 1});
    final payload = original.toCreatePayload(contratoId: id, numeroPago: 1,
      fechaVencimiento: DateTime(2026, 11, 20), montoEsperado: Decimal.parse('100.01'));
    await repository.createSchedule(Map<String, dynamic>.from(payload));
    expect((requests.last.data as Map<String, dynamic>)['fecha_vencimiento'], '2026-11-20');
    expect((requests.last.data as Map<String, dynamic>)['monto_esperado'], '100.01');
    await repository.cancelSchedule(id, ' Motivo de prueba ');
    expect(requests.last.path, '/finanzas/pagos-programados/$id/cancelar');
    expect(requests.last.data, {'motivo': 'Motivo de prueba'});
  });
  test('fallo de cobranza no bloquea consulta independiente de pagos',
      () async {
    dio.interceptors.insert(0,
        InterceptorsWrapper(onRequest: (request, handler) {
      if (request.path == '/finanzas/pagos-programados') {
        handler.reject(DioException(requestOptions: request));
      } else {
        handler.next(request);
      }
    }));
    final controller =
        PagosController(repository, UserRole.asesor, demoMode: false);
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.state.valueOrNull!.payments, hasLength(2));
    expect(controller.state.valueOrNull!.scheduledError, isNotNull);
  });
}
