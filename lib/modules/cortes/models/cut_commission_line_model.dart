import 'package:decimal/decimal.dart';

class CutCommissionLineModel {
  const CutCommissionLineModel({
    required this.destination,
    required this.percentage,
    required this.amount,
  });

  final String destination;
  final Decimal percentage;
  final Decimal amount;
}
