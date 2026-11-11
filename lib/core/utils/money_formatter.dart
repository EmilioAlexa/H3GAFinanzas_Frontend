import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

class MoneyFormatter {
  static String format(Decimal amount) {
    final negative = amount < Decimal.zero;
    final fixed = amount.abs().toStringAsFixed(2);
    final pieces = fixed.split('.');
    final grouped = pieces.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return '${negative ? '-' : ''}\$$grouped.${pieces.last}';
  }

  static String formatDate(DateTime date) =>
      DateFormat('dd/MM/yyyy', 'es_MX').format(date);
}
