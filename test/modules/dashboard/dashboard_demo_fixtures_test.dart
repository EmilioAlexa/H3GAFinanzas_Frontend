import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/modules/auth/auth.dart';
import 'package:h3ga_finanzas/modules/dashboard/dashboard.dart';

void main() {
  test('management fixture totals agree with chart and service breakdown', () {
    final dashboard = DashboardDemoFixtures.forRole(
      UserRole.administradorFinanciero,
    );
    final weeklyTotal = dashboard.weeklyIncome.fold<Decimal>(
      Decimal.zero,
      (total, point) => total + point.amount,
    );
    final serviceTotal = dashboard.serviceBreakdown.fold<Decimal>(
      Decimal.zero,
      (total, service) => total + service.amount,
    );

    expect(dashboard.isAdvisor, isFalse);
    expect(dashboard.totalValidated, Decimal.parse('1284500'));
    expect(weeklyTotal, dashboard.totalValidated);
    expect(serviceTotal, dashboard.totalValidated);
  });

  test('advisor fixture contains only personal metrics and tasks', () {
    final dashboard = DashboardDemoFixtures.forRole(UserRole.asesor);
    final labels = dashboard.metrics.map((metric) => metric.label).toSet();

    expect(dashboard.isAdvisor, isTrue);
    expect(dashboard.totalValidated, isNull);
    expect(dashboard.serviceBreakdown, isEmpty);
    expect(dashboard.weeklyIncome, isEmpty);
    expect(dashboard.recentActivity, isEmpty);
    expect(
      labels,
      containsAll(['Clientes asignados', 'Mis comisiones']),
    );
    expect(
      dashboard.advisorAgenda.map((task) => task.title),
      isNot(contains('Próximo corte financiero')),
    );
  });
}
