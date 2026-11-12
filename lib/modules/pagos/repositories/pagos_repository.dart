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
      estado: 'Pendiente de revisión financiera',
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
              ))
          .toList(),
      historial: ['Pendiente de revisión financiera · ${_shortDate(date)}'],
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
