import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/modules/usuarios/repositories/usuarios_repository.dart';
import 'package:h3ga_finanzas/modules/usuarios/repositories/usuarios_repository_exception.dart';

void main() {
  test('real list maps public API user and nested role fields', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = _UsersAdapter();
    final repository = UsuariosRepository(dio: dio);

    final users = await repository.load();
    expect(users, hasLength(1));
    expect(users.single.id, 'user-1');
    expect(users.single.rolId, '7');
    expect(users.single.rolNombre, 'Administrador');
    expect(users.single.activo, isTrue);
  });

  test('demo list has users in all three backend roles and both states', () {
    final users = UsuariosRepository().listDemo();

    expect(users.map((user) => user.rolNombre).toSet(), {
      'Administrador',
      'Administrador Financiero',
      'Asesor',
    });
    expect(users.any((user) => user.activo), isTrue);
    expect(users.any((user) => !user.activo), isTrue);
  });

  test('create rejects duplicate email regardless of case', () async {
    final repository = UsuariosRepository();

    await expectLater(
      repository.createDemo(
        nombre: 'Otro',
        apellidoPaterno: 'Usuario',
        apellidoMaterno: null,
        correo: 'LUCIA.MENDEZ@H3GA.LOCAL',
        rolId: UsuariosRepository.roles.last.id,
        contrasena: 'demopass123',
      ),
      throwsA(isA<UsuariosRepositoryException>()),
    );
  });

  test('create and status change only update the in-memory demo repository',
      () async {
    final repository = UsuariosRepository();
    final created = await repository.createDemo(
      nombre: 'Eva',
      apellidoPaterno: 'Prueba',
      apellidoMaterno: null,
      correo: 'eva@example.test',
      rolId: UsuariosRepository.roles.last.id,
      contrasena: 'demopass123',
    );

    expect(created.activo, isTrue);
    expect(repository.listDemo(), contains(created));
    expect(
        (await repository.changeStatusDemo(created.id, false)).activo, isFalse);
  });
}

class _UsersAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    return ResponseBody.fromString(
      '[{"id":"user-1","rol_id":7,"nombre":"Ana",'
      '"apellido_paterno":"López","apellido_materno":null,'
      '"correo_electronico":"ana@example.test","activo":true,'
      '"fecha_creacion":"2026-01-01T00:00:00.000Z",'
      '"roles":{"id":7,"nombre":"Administrador"}}]',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
