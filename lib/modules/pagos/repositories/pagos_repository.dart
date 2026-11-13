import 'package:decimal/decimal.dart';

import '../../../core/platform/selected_file.dart';
import '../../auth/models/user_role_model.dart';
import '../../contratos/contratos.dart';
import '../fixtures/pagos_demo_fixtures.dart';
import '../models/evidencia_pago_model.dart';
import '../models/pago_model.dart';
import '../models/pago_programado_model.dart';

class PagosRepository {
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
