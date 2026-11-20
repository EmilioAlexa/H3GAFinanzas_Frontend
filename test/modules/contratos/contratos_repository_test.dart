import 'package:dio/dio.dart';
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
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
      handler.resolve(Response(requestOptions: request, data: {
        'data': <dynamic>[],
        'pagination': {'totalPages': 0}
      }));
    }));
    final repository = ContratosRepository(demoMode: false, dio: dio);

    expect(await repository.load(UserRole.administrador), isEmpty);
    expect(await repository.loadServices(), isEmpty);
    expect(await repository.loadStates(), isEmpty);
    expect(repository.penaltiesFor('demo-contract-1'), isEmpty);
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
