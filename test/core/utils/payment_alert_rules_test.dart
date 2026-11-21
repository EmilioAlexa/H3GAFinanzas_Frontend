import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/core/utils/payment_alert_rules.dart';

void main() {
  test(
      'uses real review states and does not flag validated or rejected payments',
      () {
    expect(needsFinancialReview('Pendiente de revisi?n financiera'), true);
    expect(needsFinancialReview('Pendiente de autorizaci?n'), true);
    expect(needsFinancialReview('Validado'), false);
    expect(needsFinancialReview('Rechazado'), false);
  });
  test('uses Cancun civil dates and excludes covered or cancelled schedules',
      () {
    final now = DateTime.utc(2026, 11, 21, 2); // Still November 20 in Cancun.
    expect(daysUntilPayment(DateTime(2026, 11, 20), now), 0);
    expect(showsScheduledAlert('Vencido', DateTime(2026, 11, 19), now), true);
    expect(showsScheduledAlert('Pendiente', DateTime(2026, 12, 20), now), true);
    expect(
        showsScheduledAlert('Pendiente', DateTime(2026, 12, 21), now), false);
    expect(showsScheduledAlert('Cubierto', DateTime(2026, 11, 19), now), false);
    expect(
        showsScheduledAlert('Cancelado', DateTime(2026, 11, 19), now), false);
    expect(showsScheduledAlert('Pendiente', null, now), false);
  });
}
