import 'package:decimal/decimal.dart';

class ReportRowModel {
  const ReportRowModel({
    required this.title,
    required this.amount,
    this.subtitle,
    this.service,
    this.count,
    this.percentage,
    this.average,
    this.status,
  });

  final String title;
  final String? subtitle;
  final String? service;
  final int? count;
  final Decimal amount;
  final Decimal? percentage;
  final Decimal? average;
  final String? status;
}
