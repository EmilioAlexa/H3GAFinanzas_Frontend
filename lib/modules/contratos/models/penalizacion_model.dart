import 'package:decimal/decimal.dart';

class PenalizacionModel {
  const PenalizacionModel({
    required this.id,
    required this.contratoId,
    required this.concepto,
    required this.monto,
    required this.fecha,
    required this.estado,
    this.observaciones,
  });

  final String id;
  final String contratoId;
  final String concepto;
  final Decimal monto;
  final DateTime fecha;
  final String estado;
  final String? observaciones;
}
