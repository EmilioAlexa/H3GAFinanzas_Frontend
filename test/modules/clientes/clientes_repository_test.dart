import 'dart:typed_data';

import 'package:dio/dio.dart';
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

  test('real client list calls the API and maps the paginated response',
      () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = _JsonAdapter(
        '{"data":[{"id":"client-1","nombre":"Ana",'
        '"apellido_paterno":"López","apellido_materno":null}],'
        '"pagination":{"page":1,"limit":100,"total":1,"totalPages":1}}',
      );
    final repository = ClientesRepository(demoMode: false, dio: dio);

    final clients = await repository.load(UserRole.administrador);
    expect(clients, hasLength(1));
    expect(clients!.single.id, 'client-1');
    expect(clients.single.nombreCompleto, 'Ana López');
    expect(dio.options.baseUrl, 'https://api.example.test');
  });

  test('real client detail calls its endpoint and maps authorized fields',
      () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = _JsonAdapter(
        '{"id":"client-1","nombre":"Ana","apellido_paterno":"López",'
        '"domicilio":"Centro","observaciones_generales":"Seguimiento"}',
      );
    final repository = ClientesRepository(demoMode: false, dio: dio);

    final client = await repository.findOne('client-1');
    expect(client.direccion, 'Centro');
    expect(client.observaciones, 'Seguimiento');
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

class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this.body);
  final String body;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    return ResponseBody.fromString(body, 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType]
    });
  }

  @override
  void close({bool force = false}) {}
}
