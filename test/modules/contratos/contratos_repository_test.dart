import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/modules/auth/auth.dart';
import 'package:h3ga_finanzas/modules/contratos/contratos.dart';

void main() {
  test('advisor only receives assigned demo contracts', () async {
    final repository = ContratosRepository(demoMode: true);
    final contracts = await repository.load(UserRole.asesor);

    expect(contracts, hasLength(2));
    expect(contracts!.every((item) => item.assignedToCurrentAdvisor), isTrue);
  });

  test('real repository mode does not expose fixture records', () async {
    final repository = ContratosRepository(demoMode: false);

    expect(await repository.load(UserRole.administrador), isNull);
    expect(await repository.loadServices(), isNull);
  });

  test('contract payload matches fields accepted by OpenAPI', () {
    final contract = ContratosDemoFixtures.contracts.first;
    final adminPayload = contract.toCreatePayload(isAdvisor: false);
    final advisorPayload = contract.toCreatePayload(isAdvisor: true);

    expect(
      adminPayload.keys.toSet(),
      {
        'cliente_id',
        'servicio_id',
        'asesor_id',
        'folio',
        'fecha_contrato',
        'estado_contrato_id',
        'cantidad_pagos',
        'observaciones',
      },
    );
    expect(advisorPayload, isNot(contains('asesor_id')));
    expect(contract.toUpdatePayload().keys, ['observaciones']);
    expect(adminPayload['fecha_contrato'], '2024-11-14');
  });

  test('non-demo write operations are rejected', () {
    final repository = ContratosRepository(demoMode: false);

    expect(
      () => repository.updateObservationsDemo(
        contractId: 'demo-contract-1',
        observations: 'Cambio',
        role: UserRole.administrador,
      ),
      throwsStateError,
    );
  });
}
