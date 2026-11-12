import 'package:decimal/decimal.dart';

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
    this.periodo,
    this.assignedToCurrentAdvisor = false,
  });

  final String id;
  final String contratoId;
  final String contratoFolio;
  final String clienteNombre;
  final String servicioNombre;
  final int numeroPago;
  final DateTime? fechaEsperada;
  final DateTime? fechaVencimiento;
  final Decimal? montoEsperado;
  final int estadoId;
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
    DateTime? fechaVencimiento,
    Decimal? montoEsperado,
    DateTime? periodo,
  }) =>
      {
        'contrato_id': contratoId,
        'numero_pago': numeroPago,
        if (tipoCobroId != null) 'tipo_cobro_id': tipoCobroId,
        if (fechaEsperada != null) 'fecha_esperada': _dateOnly(fechaEsperada),
        if (fechaVencimiento != null)
          'fecha_vencimiento': _dateOnly(fechaVencimiento),
        if (montoEsperado != null) 'monto_esperado': montoEsperado.toString(),
        if (periodo != null) 'periodo': _dateOnly(periodo),
      };

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
