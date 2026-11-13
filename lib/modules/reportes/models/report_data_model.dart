import 'package:decimal/decimal.dart';

import 'report_point_model.dart';
import 'report_row_model.dart';
import 'report_type_model.dart';

class ReportDataModel {
  const ReportDataModel({
    required this.type,
    required this.total,
    required this.rows,
    this.points = const [],
    this.comparisonTotal,
    this.serviceBreakdown = const [],
  });

  final ReportType type;
  final Decimal total;
  final List<ReportRowModel> rows;
  final List<ReportPointModel> points;
  final Decimal? comparisonTotal;
  final List<ReportRowModel> serviceBreakdown;
}
