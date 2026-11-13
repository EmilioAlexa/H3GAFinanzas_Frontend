import 'package:decimal/decimal.dart';

import 'cut_commission_line_model.dart';

class CutDistributionModel {
  const CutDistributionModel({
    required this.paymentFolio,
    required this.clientName,
    required this.serviceName,
    required this.paymentMethod,
    required this.amount,
    required this.lines,
  });

  final String paymentFolio;
  final String clientName;
  final String serviceName;
  final String paymentMethod;
  final Decimal amount;
  final List<CutCommissionLineModel> lines;

  Decimal get companyRemainder =>
      amount - lines.fold(Decimal.zero, (sum, line) => sum + line.amount);
}
