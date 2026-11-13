import 'package:decimal/decimal.dart';

abstract final class CommissionMath {
  static Decimal sum(Iterable<Decimal> percentages) =>
      percentages.fold(Decimal.zero, (total, value) => total + value);

  static bool isAllowedPercentage(Decimal value) {
    if (value < Decimal.zero || value > Decimal.fromInt(100)) return false;
    final halfSteps = value * Decimal.fromInt(2);
    return !halfSteps.toString().contains('.');
  }

  /// Applies ROUND_HALF_UP using integer cents, without converting money to double.
  static Decimal amountFor(Decimal base, Decimal percentage) {
    final cents = BigInt.parse((base * Decimal.fromInt(100)).toString());
    final halfSteps = BigInt.parse(
      (percentage * Decimal.fromInt(2)).toString(),
    );
    final resultCents =
        (cents * halfSteps + BigInt.from(100)) ~/ BigInt.from(200);
    final whole = resultCents ~/ BigInt.from(100);
    final fractional =
        (resultCents % BigInt.from(100)).toString().padLeft(2, '0');
    return Decimal.parse('$whole.$fractional');
  }

  static Decimal remainderPercentage(Iterable<Decimal> assigned) =>
      Decimal.fromInt(100) - sum(assigned);

  static Decimal remainderAmount(
    Decimal base,
    Iterable<Decimal> assignedAmounts,
  ) =>
      base -
      assignedAmounts.fold(Decimal.zero, (total, value) => total + value);
}
