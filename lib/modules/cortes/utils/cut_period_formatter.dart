import 'package:intl/intl.dart';

abstract final class CutPeriodFormatter {
  static String label(DateTime start, DateTime endExclusive) {
    final end = endExclusive.subtract(const Duration(days: 1));
    final first = DateFormat('dd', 'es_MX').format(start);
    final last = DateFormat('dd MMMM yyyy', 'es_MX').format(end);
    return '$first–$last';
  }

  static String short(DateTime date) =>
      DateFormat('dd MMM yyyy', 'es_MX').format(date);

  static String dateChip(DateTime date) =>
      DateFormat('dd MMM', 'es_MX').format(date).toUpperCase();
}
