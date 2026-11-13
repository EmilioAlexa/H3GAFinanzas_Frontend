import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/modules/comisiones/utils/commission_math.dart';

void main() {
  test('sums decimal percentages and accepts half point increments', () {
    expect(
      CommissionMath.sum([Decimal.parse('10.5'), Decimal.parse('12.5')]),
      Decimal.parse('23'),
    );
    expect(CommissionMath.isAllowedPercentage(Decimal.parse('12.5')), isTrue);
    expect(CommissionMath.isAllowedPercentage(Decimal.parse('12.3')), isFalse);
    expect(CommissionMath.isAllowedPercentage(Decimal.parse('100.5')), isFalse);
  });

  test('calculates commission cents without double precision loss', () {
    expect(
      CommissionMath.amountFor(
        Decimal.parse('1234.56'),
        Decimal.parse('12.5'),
      ),
      Decimal.parse('154.32'),
    );
    expect(
      CommissionMath.amountFor(Decimal.parse('0.10'), Decimal.parse('5')),
      Decimal.parse('0.01'),
    );
  });

  test('company is the non-negative remainder', () {
    expect(
      CommissionMath.remainderPercentage(
        [Decimal.parse('15'), Decimal.parse('24.5')],
      ),
      Decimal.parse('60.5'),
    );
    expect(
      CommissionMath.remainderAmount(
        Decimal.parse('1000'),
        [Decimal.parse('150'), Decimal.parse('245')],
      ),
      Decimal.parse('605'),
    );
  });
}
