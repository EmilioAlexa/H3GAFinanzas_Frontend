import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/modules/auth/models/user_role_model.dart';
import 'package:h3ga_finanzas/modules/comisiones/repositories/comisiones_repository.dart';

void main() {
  test('advisor list is restricted to assigned payments', () {
    final repository = ComisionesRepository();
    final payments = repository.loadPayments(UserRole.asesor, demoMode: true)!;

    expect(payments, isNotEmpty);
    expect(payments.every((item) => item.assignedToCurrentAdvisor), isTrue);
    expect(repository.findPayment('demo-commission-payment-3', UserRole.asesor),
        isNull);
  });

  test('configuration changes leave existing commission snapshots untouched',
      () {
    final repository = ComisionesRepository();
    final before =
        repository.findContract('demo-contract-1', UserRole.administrador)!;
    final lines = [...before.configuration];
    lines[0] = lines[0].copyWith(percentage: Decimal.parse('14.5'));

    final after = repository.saveConfigurationDemo(
      contractId: before.contractId,
      lines: lines,
      role: UserRole.administrador,
      actor: 'Admin demo',
    );

    expect(after.configuration.first.percentage, Decimal.parse('14.5'));
    expect(after.snapshot.first.percentage, before.snapshot.first.percentage);
    expect(after.configurationHistory,
        hasLength(before.configurationHistory.length + 1));
  });

  test('rejects over-allocation, invalid steps, and IMSS for APD', () {
    final repository = ComisionesRepository();
    final m40 =
        repository.findContract('demo-contract-1', UserRole.administrador)!;
    final overallocated = [...m40.configuration];
    overallocated[0] =
        overallocated[0].copyWith(percentage: Decimal.parse('60'));
    expect(
      () => repository.saveConfigurationDemo(
        contractId: m40.contractId,
        lines: overallocated,
        role: UserRole.administrador,
        actor: 'Admin demo',
      ),
      throwsStateError,
    );
    final invalidStep = [...m40.configuration];
    invalidStep[0] = invalidStep[0].copyWith(percentage: Decimal.parse('15.3'));
    expect(
      () => repository.saveConfigurationDemo(
        contractId: m40.contractId,
        lines: invalidStep,
        role: UserRole.administrador,
        actor: 'Admin demo',
      ),
      throwsStateError,
    );

    final apd =
        repository.findContract('demo-contract-3', UserRole.administrador)!;
    expect(
      () => repository.saveConfigurationDemo(
        contractId: apd.contractId,
        lines: [
          ...apd.configuration,
          m40.configuration.firstWhere((line) => line.conceptId == 4),
        ],
        role: UserRole.administrador,
        actor: 'Admin demo',
      ),
      throwsStateError,
    );
  });

  test('only administrators can disperse a pending commission', () {
    final repository = ComisionesRepository();
    expect(
      () => repository.disperseDemo(
        paymentId: 'demo-commission-payment-3',
        commissionId: 'demo-com-3-advisor',
        role: UserRole.asesor,
        comment: '',
        actor: 'Asesor demo',
      ),
      throwsStateError,
    );
    final commission = repository.disperseDemo(
      paymentId: 'demo-commission-payment-3',
      commissionId: 'demo-com-3-advisor',
      role: UserRole.administradorFinanciero,
      comment: 'Confirmado',
      actor: 'Finanzas demo',
    );
    expect(commission.status, 'Dispersada');
    expect(commission.history.last, contains('Confirmado'));
  });
}
