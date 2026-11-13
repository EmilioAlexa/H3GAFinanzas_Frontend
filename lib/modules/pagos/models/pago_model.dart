import 'package:decimal/decimal.dart';

import 'evidencia_pago_model.dart';

class PagoModel {
  const PagoModel({
    required this.id,
    required this.folio,
    required this.contratoId,
    required this.contratoFolio,
    required this.clienteNombre,
    required this.servicioNombre,
    required this.asesorNombre,
    required this.formaPagoId,
    required this.formaPago,
    required this.estadoPagoId,
    required this.estado,
    required this.monto,
    required this.fechaPago,
    this.numeroPago,
    this.cantidadPagos,
    required this.referencia,
    required this.observaciones,
    required this.evidencias,
    required this.historial,
    this.pagoProgramadoId,
    this.folioRecibo,
    this.recibidoPor,
    this.assignedToCurrentAdvisor = false,
  });

  final String id;
  final String folio;
  final String contratoId;
  final String contratoFolio;
  final String clienteNombre;
  final String servicioNombre;
  final String asesorNombre;
  final int formaPagoId;
  final String formaPago;
  final int estadoPagoId;
  final String estado;
  final Decimal monto;
  final DateTime fechaPago;
  final int? numeroPago;
  final int? cantidadPagos;
  final String referencia;
  final String observaciones;
  final List<EvidenciaPagoModel> evidencias;
  final List<String> historial;
  final String? pagoProgramadoId;
  final String? folioRecibo;
  final String? recibidoPor;
  final bool assignedToCurrentAdvisor;

  bool get hasEvidenceForApproval =>
      evidencias.any((evidence) => evidence.tipoCompatibleConMetodo);

  PagoModel withReview({
    required int estadoPagoId,
    required String estado,
    required String historyEntry,
  }) =>
      PagoModel(
        id: id,
        folio: folio,
        contratoId: contratoId,
        contratoFolio: contratoFolio,
        clienteNombre: clienteNombre,
        servicioNombre: servicioNombre,
        asesorNombre: asesorNombre,
        formaPagoId: formaPagoId,
        formaPago: formaPago,
        estadoPagoId: estadoPagoId,
        estado: estado,
        monto: monto,
        fechaPago: fechaPago,
        numeroPago: numeroPago,
        cantidadPagos: cantidadPagos,
        referencia: referencia,
        observaciones: observaciones,
        evidencias: evidencias,
        historial: [...historial, historyEntry],
        pagoProgramadoId: pagoProgramadoId,
        folioRecibo: folioRecibo,
        recibidoPor: recibidoPor,
        assignedToCurrentAdvisor: assignedToCurrentAdvisor,
      );

  Map<String, Object?> toCreatePayload({
    required String contratoId,
    required int formaPagoId,
    required Decimal monto,
    required DateTime fechaPago,
    String? pagoProgramadoId,
    String? referencia,
    String? folioRecibo,
    String? recibidoPor,
    String? lugarRecepcion,
    String? observaciones,
  }) =>
      {
        'contrato_id': contratoId,
        'forma_pago_id': formaPagoId,
        'monto': monto.toString(),
        'fecha_pago': fechaPago.toIso8601String(),
        if (pagoProgramadoId != null) 'pago_programado_id': pagoProgramadoId,
        if (referencia?.trim().isNotEmpty ?? false)
          'referencia_pago': referencia!.trim(),
        if (folioRecibo?.trim().isNotEmpty ?? false)
          'folio_recibo': folioRecibo!.trim(),
        if (recibidoPor?.trim().isNotEmpty ?? false)
          'recibido_por': recibidoPor!.trim(),
        if (lugarRecepcion?.trim().isNotEmpty ?? false)
          'lugar_recepcion': lugarRecepcion!.trim(),
        if (observaciones?.trim().isNotEmpty ?? false)
          'observaciones': observaciones!.trim(),
      };
}
