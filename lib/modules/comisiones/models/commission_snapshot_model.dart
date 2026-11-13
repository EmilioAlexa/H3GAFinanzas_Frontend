import 'package:decimal/decimal.dart';

class CommissionSnapshotModel {
  const CommissionSnapshotModel({
    required this.id,
    required this.conceptId,
    required this.concept,
    required this.receiverName,
    required this.percentage,
    required this.amount,
    required this.status,
    required this.history,
    this.receiverId,
  });

  final String id;
  final int conceptId;
  final String concept;
  final String? receiverId;
  final String receiverName;
  final Decimal percentage;
  final Decimal amount;
  final String status;
  final List<String> history;

  CommissionSnapshotModel copyWithStatus(String value, String historyEntry) =>
      CommissionSnapshotModel(
        id: id,
        conceptId: conceptId,
        concept: concept,
        receiverId: receiverId,
        receiverName: receiverName,
        percentage: percentage,
        amount: amount,
        status: value,
        history: [...history, historyEntry],
      );
}
