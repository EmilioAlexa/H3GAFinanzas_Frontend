import '../../../core/platform/selected_file.dart';

class ContratoModel {
  const ContratoModel({
    required this.id,
    required this.clienteId,
    required this.servicioId,
    required this.asesorId,
    required this.folio,
    required this.fechaContrato,
    required this.estadoContratoId,
    required this.creadoEn,
    required this.clienteNombre,
    required this.servicioNombre,
    required this.asesorNombre,
    required this.estadoNombre,
    this.cantidadPagos,
    this.observaciones,
    this.totalPagar,
    this.montoMensual,
    this.saldoPendiente,
    this.documentos = const [],
    this.assignedToCurrentAdvisor = false,
  });

  final String id;
  final String clienteId;
  final int servicioId;
  final String asesorId;
  final String folio;
  final DateTime fechaContrato;
  final int estadoContratoId;
  final int? cantidadPagos;
  final String? observaciones;
  final String? totalPagar;
  final String? montoMensual;
  final String? saldoPendiente;
  final List<SelectedFile> documentos;
  final DateTime creadoEn;
  final String clienteNombre;
  final String servicioNombre;
  final String asesorNombre;
  final String estadoNombre;

  /// Only fixture metadata used to filter the demo session for an advisor.
  final bool assignedToCurrentAdvisor;

  Map<String, Object?> toCreatePayload({required bool isAdvisor}) => {
        'cliente_id': clienteId,
        'servicio_id': servicioId,
        if (!isAdvisor) 'asesor_id': asesorId,
        'folio': folio,
        'fecha_contrato': _dateOnly(fechaContrato),
        'estado_contrato_id': estadoContratoId,
        if (cantidadPagos != null) 'cantidad_pagos': cantidadPagos,
        if (observaciones != null) 'observaciones': observaciones,
      };

  Map<String, Object?> toUpdatePayload() => {
        'observaciones': observaciones,
      };

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
