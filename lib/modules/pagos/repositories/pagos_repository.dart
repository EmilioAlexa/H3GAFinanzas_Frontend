import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';

import '../../../core/platform/selected_file.dart';
import '../../auth/models/user_role_model.dart';
import '../../contratos/contratos.dart';
import '../fixtures/pagos_demo_fixtures.dart';
import '../models/evidencia_pago_model.dart';
import '../models/pago_api_mapping.dart';
import '../models/pago_model.dart';
import '../models/pago_programado_model.dart';
import '../models/payment_evidence_validation.dart';

class PagosRepository {
  PagosRepository({this.dio});
  final Dio? dio;

  Future<({List<PagoModel> data, int page, int total, int totalPages})> page({
    int page = 1,
    int limit = 100,
    Map<String, dynamic> filters = const {},
  }) async {
    final body = (await dio!.get<Map<String, dynamic>>('/finanzas/pagos',
            queryParameters: {...filters, 'page': page, 'limit': limit}))
        .data!;
    final pagination = pagoMap(body['pagination']);
    return (
      data: (body['data'] as List)
          .map((e) => PagoModel.fromJson(pagoMap(e)))
          .toList(),
      page: pagination['page'] as int,
      total: pagination['total'] as int,
      totalPages: pagination['totalPages'] as int
    );
  }

  Future<List<PagoModel>> payments(
      {Map<String, dynamic> filters = const {}}) async {
    final result = <PagoModel>[];
    var next = 1;
    while (true) {
      final batch = await page(page: next, filters: filters);
      result.addAll(batch.data);
      if (next >= batch.totalPages) return result;
      next++;
    }
  }

  Future<List<Map<String, dynamic>>> readAll(String path,
      {Map<String, dynamic> filters = const {}}) async {
    final rows = <Map<String, dynamic>>[];
    var page = 1;
    while (true) {
      final body = (await dio!.get<Map<String, dynamic>>(path,
              queryParameters: {...filters, 'page': page, 'limit': 100}))
          .data!;
      rows.addAll((body['data'] as List).map(pagoMap));
      if (page >= (pagoMap(body['pagination'])['totalPages'] as int)) {
        return rows;
      }
      page++;
    }
  }

  Future<List<PagoProgramadoModel>> scheduled({String? contractId}) async =>
      (await readAll('/finanzas/pagos-programados', filters: {
        if (contractId != null) 'contrato_id': contractId,
      }))
          .map(PagoProgramadoModel.fromJson)
          .toList();

  Future<List<Map<String, dynamic>>> history(String id) async =>
      ((await dio!.get<List<dynamic>>('/finanzas/pagos/$id/historial')).data!)
          .map(pagoMap)
          .toList();
  Future<List<Map<String, dynamic>>> corrections(String id) async =>
      ((await dio!.get<List<dynamic>>('/finanzas/pagos/$id/correcciones'))
              .data!)
          .map(pagoMap)
          .toList();
  Future<List<EvidenciaPagoModel>> evidences(String id, String method) async =>
      ((await dio!.get<List<dynamic>>('/finanzas/pagos/$id/evidencias')).data!)
          .map((e) => EvidenciaPagoModel.fromJson(pagoMap(e), method: method))
          .toList();

  Future<PagoModel> detail(String id) async {
    final json =
        (await dio!.get<Map<String, dynamic>>('/finanzas/pagos/$id')).data!;
    final method = pagoMap(json['formas_pago'])['nombre'] as String? ?? '';
    final evidenceFuture = evidences(id, method);
    final historyFuture = history(id);
    final correctionsFuture = corrections(id);
    final results = await Future.wait<Object>(
        [evidenceFuture, historyFuture, correctionsFuture]);
    final entries = (results[1] as List<Map<String, dynamic>>).map((e) {
      final state = pagoPersonName(e[
          'estados_pago_historial_estados_pago_estado_nuevo_idToestados_pago']);
      return [
        e['fecha_cambio'],
        state,
        pagoPersonName(e['usuarios']),
        e['comentario']
      ].whereType<String>().where((v) => v.isNotEmpty).join(' · ');
    }).toList();
    return PagoModel.fromJson(json,
        evidences: results[0] as List<EvidenciaPagoModel>,
        history: entries,
        corrections: results[2] as List<Map<String, dynamic>>);
  }

  Future<PagoModel> create(Map<String, dynamic> payload) async =>
      PagoModel.fromJson((await dio!
              .post<Map<String, dynamic>>('/finanzas/pagos', data: payload))
          .data!);
  Future<PagoModel> correct(String id, Map<String, dynamic> payload) async =>
      PagoModel.fromJson((await dio!.patch<Map<String, dynamic>>(
              '/finanzas/pagos/$id/corregir',
              data: payload))
          .data!);
  Future<PagoModel> review(String id, String action, String comment) async =>
      PagoModel.fromJson((await dio!
              .patch<Map<String, dynamic>>('/finanzas/pagos/$id/estado', data: {
        'accion': action,
        'comentario': comment.trim().isEmpty ? null : comment.trim()
      }))
          .data!);
  Future<PagoProgramadoModel> createSchedule(
          Map<String, dynamic> payload) async =>
      PagoProgramadoModel.fromJson((await dio!.post<Map<String, dynamic>>(
              '/finanzas/pagos-programados',
              data: payload))
          .data!);
  Future<PagoProgramadoModel> cancelSchedule(String id, String reason) async =>
      PagoProgramadoModel.fromJson((await dio!.patch<Map<String, dynamic>>(
              '/finanzas/pagos-programados/$id/cancelar',
              data: {'motivo': reason.trim()}))
          .data!);

  Future<EvidenciaPagoModel> upload(String paymentId, SelectedFile file) async {
    final validation = validatePaymentEvidence(file);
    if (validation != null) throw StateError(validation);
    final body = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes,
          filename: file.name,
          contentType: DioMediaType.parse(
              file.name.toLowerCase().endsWith('.pdf')
                  ? 'application/pdf'
                  : 'image/jpeg'))
    });
    return EvidenciaPagoModel.fromJson((await dio!.post<Map<String, dynamic>>(
            '/finanzas/pagos/$paymentId/evidencias',
            data: body))
        .data!);
  }

  Future<Uint8List> download(String evidenceId) async => Uint8List.fromList(
      (await dio!.get<List<int>>('/finanzas/evidencias/$evidenceId/descargar',
              options: Options(responseType: ResponseType.bytes)))
          .data!);

  final List<PagoModel> _payments = List.of(PagosDemoFixtures.payments);
  final List<PagoProgramadoModel> _scheduled =
      List.of(PagosDemoFixtures.scheduled);

  List<PagoModel>? loadPayments(UserRole role, {required bool demoMode}) =>
      demoMode ? _visiblePayments(role) : null;

  List<PagoProgramadoModel>? loadScheduled(UserRole role,
          {required bool demoMode}) =>
      demoMode ? _visibleScheduled(role) : null;

  PagoModel? findPayment(String id, UserRole role) {
    for (final payment in _visiblePayments(role)) {
      if (payment.id == id) return payment;
    }
    return null;
  }

  PagoModel changeReviewStateDemo({
    required String paymentId,
    required UserRole role,
    required String action,
    required String comment,
    required String actor,
  }) {
    final index = _payments.indexWhere((item) => item.id == paymentId);
    if (index < 0) throw StateError('Pago no disponible.');
    final payment = _payments[index];
    if (role == UserRole.asesor) {
      throw StateError('El asesor no puede validar pagos.');
    }
    if (role == UserRole.administradorFinanciero &&
        payment.estado != 'Por revisar') {
      throw StateError(
          'Solo puedes revisar pagos pendientes de revisión financiera.');
    }
    if (role == UserRole.administrador &&
        payment.estado != 'Por revisar' &&
        payment.estado != 'Pendiente de autorización') {
      throw StateError(
          'El pago no está disponible para una decisión administrativa.');
    }
    if (action == 'validar' && role != UserRole.administrador) {
      throw StateError('La validación final corresponde a administración.');
    }
    if (action == 'enviar_a_autorizacion' &&
        role != UserRole.administradorFinanciero) {
      throw StateError('Esta acción corresponde a administración financiera.');
    }
    if (!const {'rechazar', 'enviar_a_autorizacion', 'validar'}
        .contains(action)) {
      throw StateError('Acción de validación no reconocida.');
    }
    if (action == 'validar' && !payment.hasEvidenceForApproval) {
      throw StateError(
        'No se puede validar: falta evidencia compatible con la forma de pago.',
      );
    }
    if (comment.length > 1000) {
      throw StateError('El comentario no puede superar 1000 caracteres.');
    }

    final (nextId, nextStatus) = switch (action) {
      'rechazar' => (5, 'Rechazado'),
      'enviar_a_autorizacion' => (4, 'Pendiente de autorización'),
      _ => (3, 'Validado'),
    };
    final note = comment.trim().isEmpty ? '' : ' · ${comment.trim()}';
    final updated = payment.withReview(
      estadoPagoId: nextId,
      estado: nextStatus,
      historyEntry: '$nextStatus · $actor$note',
    );
    _payments[index] = updated;
    return updated;
  }

  PagoModel createPayment({
    required ContratoModel contract,
    required int methodId,
    required String method,
    required Decimal amount,
    required DateTime date,
    required String reference,
    required String observations,
    required String? scheduleId,
    required String? receiptFolio,
    required String? receivedBy,
    required List<SelectedFile> evidenceFiles,
  }) {
    final number = _payments.length + 1;
    final created = PagoModel(
      id: 'demo-payment-$number',
      folio: 'PG-DEMO-${number.toString().padLeft(4, '0')}',
      contratoId: contract.id,
      contratoFolio: contract.folio,
      clienteNombre: contract.clienteNombre,
      servicioNombre: contract.servicioNombre,
      asesorNombre: contract.asesorNombre,
      formaPagoId: methodId,
      formaPago: method,
      estadoPagoId: 1,
      estado: 'Por revisar',
      monto: amount,
      fechaPago: date,
      numeroPago: scheduleId == null
          ? null
          : _scheduled
              .where((item) => item.id == scheduleId)
              .map((item) => item.numeroPago)
              .first,
      cantidadPagos: contract.cantidadPagos,
      referencia: reference,
      observaciones: observations,
      pagoProgramadoId: scheduleId,
      folioRecibo: receiptFolio,
      recibidoPor: receivedBy,
      assignedToCurrentAdvisor: contract.assignedToCurrentAdvisor,
      evidencias: evidenceFiles
          .map((file) => EvidenciaPagoModel(
                id: 'demo-evidence-${_payments.length}-${file.name}',
                name: file.name,
                mimeType: _mimeType(file.name),
                sizeBytes: file.bytes.lengthInBytes,
                uploadedAt: DateTime.now(),
                previewBytes: file.bytes,
              ))
          .toList(),
      historial: ['Por revisar · ${_shortDate(date)}'],
    );
    _payments.insert(0, created);
    return created;
  }

  PagoModel resubmitRejectedDemo({
    required String paymentId,
    required UserRole role,
    required ContratoModel contract,
    required int methodId,
    required String method,
    required Decimal amount,
    required DateTime date,
    required String reference,
    required String observations,
    required String? scheduleId,
    required String? receiptFolio,
    required String? receivedBy,
    required List<EvidenciaPagoModel> existingEvidence,
    required List<SelectedFile> evidenceFiles,
  }) {
    if (role != UserRole.asesor) {
      throw StateError('Solo el asesor puede reenviar este pago.');
    }
    final index = _payments.indexWhere((payment) => payment.id == paymentId);
    if (index < 0) throw StateError('Pago no disponible.');
    final current = _payments[index];
    if (current.estado != 'Rechazado' || !current.assignedToCurrentAdvisor) {
      throw StateError('Solo puedes reenviar pagos rechazados asignados a ti.');
    }
    final evidence = [
      ...existingEvidence,
      ...evidenceFiles.map(
        (file) => EvidenciaPagoModel(
          id: 'demo-evidence-${_payments.length}-${file.name}',
          name: file.name,
          mimeType: _mimeType(file.name),
          sizeBytes: file.bytes.lengthInBytes,
          uploadedAt: DateTime.now(),
          previewBytes: file.bytes,
          tipoCompatibleConMetodo: true,
        ),
      ),
    ];
    final updated = PagoModel(
      id: current.id,
      folio: current.folio,
      contratoId: contract.id,
      contratoFolio: contract.folio,
      clienteNombre: contract.clienteNombre,
      servicioNombre: contract.servicioNombre,
      asesorNombre: contract.asesorNombre,
      formaPagoId: methodId,
      formaPago: method,
      estadoPagoId: 1,
      estado: 'Por revisar',
      monto: amount,
      fechaPago: date,
      numeroPago: scheduleId == null
          ? null
          : _scheduled
              .where((item) => item.id == scheduleId)
              .map((item) => item.numeroPago)
              .firstOrNull,
      cantidadPagos: contract.cantidadPagos,
      referencia: reference,
      observaciones: observations,
      evidencias: evidence,
      historial: [
        ...current.historial,
        'Por revisar · ${_shortDate(date)}',
      ],
      pagoProgramadoId: scheduleId,
      folioRecibo: receiptFolio,
      recibidoPor: receivedBy,
      assignedToCurrentAdvisor: current.assignedToCurrentAdvisor,
    );
    _payments[index] = updated;
    return updated;
  }

  PagoProgramadoModel createScheduled({
    required ContratoModel contract,
    required int number,
    required Decimal? amount,
    required DateTime? expectedDate,
    required DateTime? dueDate,
    required DateTime? period,
  }) {
    final created = PagoProgramadoModel(
      id: 'demo-schedule-${_scheduled.length + 1}',
      contratoId: contract.id,
      contratoFolio: contract.folio,
      clienteNombre: contract.clienteNombre,
      servicioNombre: contract.servicioNombre,
      numeroPago: number,
      fechaEsperada: expectedDate,
      fechaVencimiento: dueDate,
      montoEsperado: amount,
      estadoId: 1,
      estado: 'Pendiente',
      pagosRegistrados: 0,
      periodo: period,
      assignedToCurrentAdvisor: contract.assignedToCurrentAdvisor,
    );
    _scheduled.insert(0, created);
    return created;
  }

  List<PagoModel> _visiblePayments(UserRole role) => _payments
      .where((item) => role != UserRole.asesor || item.assignedToCurrentAdvisor)
      .toList();
  List<PagoProgramadoModel> _visibleScheduled(UserRole role) => _scheduled
      .where((item) => role != UserRole.asesor || item.assignedToCurrentAdvisor)
      .toList();

  String _mimeType(String name) =>
      name.toLowerCase().endsWith('.pdf') ? 'application/pdf' : 'image/jpeg';
  String _shortDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
