import 'package:decimal/decimal.dart';

class CommissionLineModel {
  const CommissionLineModel({
    required this.conceptId,
    required this.concept,
    required this.receiverId,
    required this.receiverName,
    required this.percentage,
    this.payrollIncluded = false,
    this.payrollName,
  });

  final int conceptId;
  final String concept;
  final String receiverId;
  final String receiverName;
  final Decimal percentage;
  final bool payrollIncluded;
  final String? payrollName;

  CommissionLineModel copyWith({
    String? receiverId,
    String? receiverName,
    Decimal? percentage,
    bool? payrollIncluded,
    String? payrollName,
  }) =>
      CommissionLineModel(
        conceptId: conceptId,
        concept: concept,
        receiverId: receiverId ?? this.receiverId,
        receiverName: receiverName ?? this.receiverName,
        percentage: percentage ?? this.percentage,
        payrollIncluded: payrollIncluded ?? this.payrollIncluded,
        payrollName: payrollName ?? this.payrollName,
      );

  Map<String, Object?> toPayload() => {
        'concepto_id': conceptId,
        'receptor_dispersion_id': receiverId,
        'valor': percentage.toString(),
      };
}
