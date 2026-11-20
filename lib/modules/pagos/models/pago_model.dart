import 'package:decimal/decimal.dart';

import 'evidencia_pago_model.dart';
import 'pago_api_mapping.dart';

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
    this.registradoPor,
    this.fechaRegistro,
    this.clienteId,
    this.asesorId,
    this.recibidoPorNombre,
    this.lugarRecepcion,
    this.correcciones = const [],
  });

  factory PagoModel.fromJson(Map<String, dynamic> json,
      {List<EvidenciaPagoModel>? evidences,
      List<String> history = const [],
      List<Map<String, dynamic>> corrections = const []}) {
    final contract = pagoMap(json['contratos']);
    final method = pagoMap(json['formas_pago'])['nombre'] as String? ?? '';
    return PagoModel(
      id: json['id'] as String,
      // The API has no payment folio. Show the supplied receipt or actual UUID.
      folio: json['folio_recibo'] as String? ?? json['id'] as String,
      contratoId: json['contrato_id'] as String,
      contratoFolio: contract['folio'] as String? ?? '',
      clienteId: contract['cliente_id'] as String?,
      asesorId: contract['asesor_id'] as String?,
      clienteNombre: pagoPersonName(contract['clientes']),
      servicioNombre: pagoPersonName(contract['servicios']),
      asesorNombre: pagoPersonName(contract['usuarios']),
      formaPagoId: json['forma_pago_id'] as int?, formaPago: method,
      estadoPagoId: json['estado_pago_id'] as int?,
      estado: pagoMap(json['estados_pago'])['nombre'] as String? ?? '',
      monto: Decimal.parse(json['monto'].toString()),
      fechaPago: pagoInstant(json['fecha_pago']),
      fechaRegistro: pagoInstant(json['fecha_registro']),
      registradoPor: json['registrado_por'] as String?,
      numeroPago: pagoMap(json['pagos_programados'])['numero_pago'] as int?,
      cantidadPagos: contract['cantidad_pagos'] as int?,
      referencia: json['referencia_pago'] as String? ?? '',
      observaciones: json['observaciones'] as String? ?? '',
      pagoProgramadoId: json['pago_programado_id'] as String?,
      folioRecibo: json['folio_recibo'] as String?,
      recibidoPor: json['recibido_por'] as String?,
      recibidoPorNombre: pagoPersonName(json['usuario_receptor']),
      lugarRecepcion: json['lugar_recepcion'] as String?,
      evidencias: evidences ??
          (json['evidencias_pago'] as List? ?? [])
              .map((e) =>
                  EvidenciaPagoModel.fromJson(pagoMap(e), method: method))
              .toList(),
      historial: history, correcciones: corrections,
    );
  }

  final String? registradoPor;
  final DateTime? fechaRegistro;
  final String? clienteId;
  final String? asesorId;
  final String? recibidoPorNombre;
  final String? lugarRecepcion;
  final List<Map<String, dynamic>> correcciones;
  final String id;
  final String folio;
  final String contratoId;
  final String contratoFolio;
  final String clienteNombre;
  final String servicioNombre;
  final String asesorNombre;
  final int? formaPagoId;
  final String formaPago;
  final int? estadoPagoId;
  final String estado;
  final Decimal monto;
  final DateTime? fechaPago;
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

  bool get hasEvidenceForApproval => evidencias
      .any((evidence) => evidence.vigente && evidence.tipoCompatibleConMetodo);

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
