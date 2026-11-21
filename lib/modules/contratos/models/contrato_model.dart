import '../../../core/platform/selected_file.dart';

import 'servicio_model.dart';

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
    this.salarioDiario,
    this.periodoContrato,
    this.fechaTermino,
    this.tipoVentaNombre,
    this.esquemaPago,
    this.codigoServicio,
    this.documentsReady = false,
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
      documentsReady: (json['capacidades'] as Map?)?['documentos'] == true,
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
      montoMensual: ((json['seguimiento_m10'] as Map?)?['monto_mensual'] ??
              (json['seguimiento_m40'] as Map?)?['monto_mensual'])
          ?.toString(),
      codigoServicio: (json['servicios'] as Map?)?['codigo_folio'] as String?,
      salarioDiario: ((json['seguimiento_m40'] as Map?)?['salario_diario'] ??
              (json['seguimiento_m40_retroactiva'] as Map?)?['salario_diario'])
          ?.toString(),
      periodoContrato: (json['seguimiento_m10'] as Map?)?['periodo_contrato']
              ?.toString() ??
          ((json['seguimiento_m40'] as Map?)?['cantidad_meses'] == null
              ? null
              : "${(json['seguimiento_m40'] as Map)['cantidad_meses']} meses"),
      fechaTermino: (json['seguimiento_m40'] as Map?)?['fecha_fin'] == null
          ? null
          : DateTime.parse(
              (json['seguimiento_m40'] as Map)['fecha_fin'] as String),
      tipoVentaNombre: ((json['seguimiento_apd'] as Map?)?['tipos_venta']
          as Map?)?['nombre'] as String?,
      esquemaPago: switch (ServicioModel.routeKey(
          (json['servicios'] as Map?)?['codigo_folio'] as String? ??
              name(json['servicios']),
          json['servicio_id'] as int)) {
        'apd' || 'm40-retroactiva' => 'Pago \u00fanico',
        'm10' || 'm40' => 'Mensual',
        _ => null,
      },
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
  final String? salarioDiario;
  final String? periodoContrato;
  final DateTime? fechaTermino;
  final String? tipoVentaNombre;
  final String? esquemaPago;
  final String? codigoServicio;
  final bool documentsReady;
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
