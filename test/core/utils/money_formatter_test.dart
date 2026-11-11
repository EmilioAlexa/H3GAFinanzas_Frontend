import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/core/utils/money_formatter.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  await initializeDateFormatting('es_MX');
  test(
    'formats exact Decimal values as MXN without floating point conversion',
    () {
      expect(MoneyFormatter.format(Decimal.parse('10000.5')), r'$10,000.50');
    },
  );

  test('formats calendar dates as dd/mm/yyyy', () {
    expect(MoneyFormatter.formatDate(DateTime(2026, 11, 9)), '09/11/2026');
  });
}
