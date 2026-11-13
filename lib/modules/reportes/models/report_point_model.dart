import 'package:decimal/decimal.dart';

class ReportPointModel {
  const ReportPointModel({required this.label, required this.amount});

  final String label;
  final Decimal amount;
}
