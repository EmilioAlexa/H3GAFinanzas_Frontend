import 'package:decimal/decimal.dart';

import 'cut_history_model.dart';
import 'cut_movement_model.dart';

class CutModel {
  const CutModel({
    required this.id,
    required this.folio,
    required this.periodStart,
    required this.periodEndExclusive,
    required this.createdAt,
    required this.responsible,
    required this.status,
    required this.totalAmount,
    required this.commissionAmount,
    required this.includedCount,
    required this.excludedCount,
    required this.includedAmount,
    required this.excludedAmount,
    required this.movements,
    required this.history,
    this.advisorCount = 0,
  });

  final String id;
  final String folio;
  final DateTime periodStart;

  /// Backend represents the Friday after the inclusive Friday–Thursday week.
  final DateTime periodEndExclusive;
  final DateTime createdAt;
  final String responsible;
  final String status;
  final Decimal totalAmount;
  final Decimal commissionAmount;
  final int includedCount;
  final int excludedCount;
  final Decimal includedAmount;
  final Decimal excludedAmount;
  final List<CutMovementModel> movements;
  final List<CutHistoryModel> history;
  final int advisorCount;

  DateTime get periodEndInclusive =>
      periodEndExclusive.subtract(const Duration(days: 1));

  CutModel copyWith({
    String? status,
    String? responsible,
    Decimal? totalAmount,
    Decimal? commissionAmount,
    int? includedCount,
    int? excludedCount,
    Decimal? includedAmount,
    Decimal? excludedAmount,
    List<CutMovementModel>? movements,
    List<CutHistoryModel>? history,
  }) =>
      CutModel(
        id: id,
        folio: folio,
        periodStart: periodStart,
        periodEndExclusive: periodEndExclusive,
        createdAt: createdAt,
        responsible: responsible ?? this.responsible,
        status: status ?? this.status,
        totalAmount: totalAmount ?? this.totalAmount,
        commissionAmount: commissionAmount ?? this.commissionAmount,
        includedCount: includedCount ?? this.includedCount,
        excludedCount: excludedCount ?? this.excludedCount,
        includedAmount: includedAmount ?? this.includedAmount,
        excludedAmount: excludedAmount ?? this.excludedAmount,
        movements: movements ?? this.movements,
        history: history ?? this.history,
        advisorCount: advisorCount,
      );
}
