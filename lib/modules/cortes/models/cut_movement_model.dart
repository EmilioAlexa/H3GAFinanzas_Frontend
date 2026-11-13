import 'package:decimal/decimal.dart';

class CutMovementModel {
  const CutMovementModel({
    required this.id,
    required this.paymentFolio,
    required this.clientName,
    required this.serviceName,
    required this.paymentMethod,
    required this.paymentDate,
    required this.amount,
    required this.included,
    this.exclusionReason,
  });

  final String id;
  final String paymentFolio;
  final String clientName;
  final String serviceName;
  final String paymentMethod;
  final DateTime paymentDate;
  final Decimal amount;
  final bool included;
  final String? exclusionReason;
}
