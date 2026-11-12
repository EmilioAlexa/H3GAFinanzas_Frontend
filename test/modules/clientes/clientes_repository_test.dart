import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/modules/auth/auth.dart';
import 'package:h3ga_finanzas/modules/clientes/clientes.dart';

void main() {
  test('advisor only receives the clients assigned in the demo dataset',
      () async {
    final repository = ClientesRepository(demoMode: true);
    final clients = await repository.load(UserRole.asesor);

    expect(clients, hasLength(2));
    expect(
      clients!.map((client) => client.nombreCompleto),
      ['Elena Robles Vargas', 'Sofía Ramírez León'],
    );
  });

  test('non-demo repository never returns local demo clients', () async {
    final repository = ClientesRepository(demoMode: false);

    expect(await repository.load(UserRole.administrador), isNull);
  });

  test('client payload contains only fields described by OpenAPI', () {
    const client = ClienteModel(
      id: 'demo-client-1',
      nombre: 'Elena',
      apellidoPaterno: 'Robles',
      apellidoMaterno: 'Vargas',
      telefono: '55 3140 8872',
      correoElectronico: 'elena@example.test',
      curp: 'ROVE680214MDFBLN08',
      demoMetadata: (
        status: 'Activo',
        advisorName: 'Demo',
        service: 'M40',
        assignedToCurrentAdvisor: true,
      ),
    );

    expect(
      client.toApiPayload().keys.toSet(),
      {
        'nombre',
        'apellido_paterno',
        'apellido_materno',
        'telefono',
        'correo_electronico',
        'curp',
        'rfc',
      },
    );
    expect(client.toApiPayload(), isNot(contains('servicio')));
  });

  test('demo create and update modify local repository only', () async {
    final repository = ClientesRepository(demoMode: true);
    final created = repository.createDemo(
      nombre: 'Lucía',
      apellidoPaterno: 'Ortega',
    );
    expect((await repository.load(UserRole.asesor)), contains(created));

    final updated = repository.updateDemo(
      ClienteModel(
        id: created.id,
        nombre: 'Lucía Fernanda',
        apellidoPaterno: 'Ortega',
        demoMetadata: created.demoMetadata,
      ),
    );
    expect(updated.nombreCompleto, 'Lucía Fernanda Ortega');
  });
}
