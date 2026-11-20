import 'package:decimal/decimal.dart';
import 'pago_api_mapping.dart';

class PagoProgramadoModel {
  const PagoProgramadoModel({
    required this.id,
    required this.contratoId,
    required this.contratoFolio,
    required this.clienteNombre,
    required this.servicioNombre,
    required this.numeroPago,
    required this.fechaEsperada,
    required this.fechaVencimiento,
    required this.montoEsperado,
    required this.estadoId,
    required this.estado,
    required this.pagosRegistrados,
    this.tipoCobroId,
    this.montoAbonadoValidado,
    this.saldoPendienteConfirmado,
    this.motivoSaldoNoDisponible,
    this.tipoCobroNombre,
    this.motivoPenalizacion,
    this.clasificacionTopeApd,
    this.montoRecibidoBeneficiarioApd,
    this.justificacionDuplicado,
    this.canceladoPor,
    this.canceladoEn,
    this.motivoCancelacion,
    this.periodo,
    this.assignedToCurrentAdvisor = false,
  });

  factory PagoProgramadoModel.fromJson(Map<String, dynamic> json) {
    final contract = pagoMap(json['contratos']);
    final operational = pagoMap(json['estado_operativo']);
    final stored = pagoMap(json['estados_pago_programado']);
    Decimal? decimal(Object? value) =>
        value == null ? null : Decimal.parse(value.toString());
    return PagoProgramadoModel(
      id: json['id'] as String,
      contratoId: json['contrato_id'] as String,
      contratoFolio: contract['folio'] as String? ?? '',
      clienteNombre: pagoPersonName(contract['clientes']),
      servicioNombre: pagoPersonName(contract['servicios']),
      numeroPago: json['numero_pago'] as int,
      fechaEsperada: pagoDate(json['fecha_esperada']),
      fechaVencimiento: pagoDate(json['fecha_vencimiento']),
      montoEsperado: decimal(json['monto_esperado']),
      estadoId: operational['id'] as int? ?? json['estado_id'] as int?,
      estado: operational['nombre'] as String? ??
          stored['nombre'] as String? ??
          'Sin estado operativo',
      pagosRegistrados: (json['pagos'] as List? ?? []).length,
      tipoCobroId: json['tipo_cobro_id'] as int?,
      periodo: pagoDate(json['periodo']),
      tipoCobroNombre: pagoMap(json['tipos_cobro'])['nombre'] as String?,
      montoAbonadoValidado: decimal(json['monto_abonado_validado']),
      saldoPendienteConfirmado: decimal(json['saldo_pendiente_confirmado']),
      motivoSaldoNoDisponible: json['motivo_saldo_no_disponible'] as String?,
      motivoPenalizacion: json['motivo_penalizacion'] as String?,
      justificacionDuplicado: json['justificacion_duplicado'] as String?,
      canceladoPor: json['cancelado_por'] as String?,
      canceladoEn: pagoInstant(json['cancelado_en']),
      motivoCancelacion: json['motivo_cancelacion'] as String?,
      clasificacionTopeApd: json['clasificacion_tope_apd'] as String?,
      montoRecibidoBeneficiarioApd:
          decimal(json['monto_recibido_beneficiario_apd']),
    );
  }

  final Decimal? montoAbonadoValidado;
  final Decimal? saldoPendienteConfirmado;
  final String? motivoSaldoNoDisponible;
  final String? tipoCobroNombre;
  final String? motivoPenalizacion;
  final String? justificacionDuplicado;
  final String? canceladoPor;
  final DateTime? canceladoEn;
  final String? motivoCancelacion;
  final String? clasificacionTopeApd;
  final Decimal? montoRecibidoBeneficiarioApd;
  final String id;
  final String contratoId;
  final String contratoFolio;
  final String clienteNombre;
  final String servicioNombre;
  final int numeroPago;
  final DateTime? fechaEsperada;
  final DateTime? fechaVencimiento;
  final Decimal? montoEsperado;
  final int? estadoId;
  final String estado;
  final int pagosRegistrados;
  final int? tipoCobroId;
  final DateTime? periodo;
  final bool assignedToCurrentAdvisor;

  Map<String, Object?> toCreatePayload({
    required String contratoId,
    required int numeroPago,
    int? tipoCobroId,
    DateTime? fechaEsperada,
    required DateTime fechaVencimiento,
    Decimal? montoEsperado,
    DateTime? periodo,
  }) =>
      {
        'contrato_id': contratoId,
        'numero_pago': numeroPago,
        if (tipoCobroId != null) 'tipo_cobro_id': tipoCobroId,
        if (fechaEsperada != null) 'fecha_esperada': _dateOnly(fechaEsperada),
        'fecha_vencimiento': _dateOnly(fechaVencimiento),
        if (montoEsperado != null) 'monto_esperado': montoEsperado.toString(),
        if (periodo != null) 'periodo': _dateOnly(periodo),
      };

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
