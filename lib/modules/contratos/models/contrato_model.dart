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

  factory ContratoModel.fromJson(Map<String, dynamic> json) {
    String name(dynamic value) {
      final row = value as Map? ?? {};
      return [row['nombre'], row['apellido_paterno'], row['apellido_materno']]
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .join(' ');
    }

    return ContratoModel(
      id: json['id'] as String,
      clienteId: json['cliente_id'] as String,
      servicioId: json['servicio_id'] as int,
      asesorId: json['asesor_id'] as String,
      folio: json['folio'] as String,
      fechaContrato: DateTime.parse(json['fecha_contrato'] as String),
      estadoContratoId: json['estado_contrato_id'] as int,
      creadoEn: DateTime.parse(json['creado_en'] as String),
      cantidadPagos: json['cantidad_pagos'] as int?,
      observaciones: json['observaciones'] as String?,
      clienteNombre: name(json['clientes']),
      servicioNombre: name(json['servicios']),
      asesorNombre: name(json['usuarios']),
      estadoNombre: name(json['estados_contratos']),
    );
  }

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
