import 'package:decimal/decimal.dart';

class CommissionLineModel {
  const CommissionLineModel({
    required this.conceptId,
    required this.concept,
    required this.receiverId,
    required this.receiverName,
    required this.percentage,
  });

  final int conceptId;
  final String concept;
  final String receiverId;
  final String receiverName;
  final Decimal percentage;

  CommissionLineModel copyWith({
    String? receiverId,
    String? receiverName,
    Decimal? percentage,
  }) =>
      CommissionLineModel(
        conceptId: conceptId,
        concept: concept,
        receiverId: receiverId ?? this.receiverId,
        receiverName: receiverName ?? this.receiverName,
        percentage: percentage ?? this.percentage,
      );

  Map<String, Object?> toPayload() => {
        'concepto_id': conceptId,
        'receptor_dispersion_id': receiverId,
        'valor': percentage.toString(),
      };
}
