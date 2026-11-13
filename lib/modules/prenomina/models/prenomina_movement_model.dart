import 'package:decimal/decimal.dart';

class PrenominaMovementModel {
  const PrenominaMovementModel({
    required this.id,
    required this.payment,
    required this.contract,
    required this.saleType,
    required this.percentage,
    required this.baseAmount,
    required this.commissionAmount,
    required this.status,
  });

  final String id;
  final String payment;
  final String contract;
  final String saleType;
  final Decimal percentage;
  final Decimal baseAmount;
  final Decimal commissionAmount;
  final String status;

  PrenominaMovementModel copyWithStatus(String value) => PrenominaMovementModel(
        id: id,
        payment: payment,
        contract: contract,
        saleType: saleType,
        percentage: percentage,
        baseAmount: baseAmount,
        commissionAmount: commissionAmount,
        status: value,
      );
}
