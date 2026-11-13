class CutHistoryModel {
  const CutHistoryModel({
    required this.status,
    required this.actor,
    required this.at,
    this.comment,
  });

  final String status;
  final String actor;
  final DateTime at;
  final String? comment;
}
