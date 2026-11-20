import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/modules/usuarios/repositories/usuarios_repository.dart';

void main() {
  test('usuarios y roles usan respuestas y DTO reales', () async {
    final requests = <RequestOptions>[];
    final dio = Dio();
    const user = {
      'id': '00000000-0000-4000-8000-000000000001',
      'nombre': 'Ana',
      'apellido_paterno': 'Prueba',
      'apellido_materno': null,
      'correo_electronico': 'ana@example.test',
      'rol_id': 7,
      'activo': true,
      'fecha_creacion': '2026-01-01T00:00:00.000Z',
      'roles': {'id': 7, 'nombre': 'asesor'}
    };
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      requests.add(options);
      Object data = user;
      if (options.path == '/roles')
        data = [
          {'id': 7, 'nombre': 'asesor'}
        ];
      if (options.path == '/usuarios' && options.method == 'GET') data = [user];
      handler.resolve(
          Response(requestOptions: options, data: data, statusCode: 200));
    }));
    final repository = UsuariosRepository(demoMode: false, dio: dio);
    final users = await repository.load();
    expect(users.single.rolId, '7');
    expect(users.single.ultimoAccesoDemo, isNull);
    expect(repository.availableRoles.single.id, '7');
    await repository.detail(users.single.id);
    await repository.createDemo(
        nombre: 'Ana',
        apellidoPaterno: 'Prueba',
        apellidoMaterno: null,
        correo: 'ana@example.test',
        rolId: '7',
        contrasena: 'clave-de-prueba');
    expect(requests.last.data, containsPair('rol_id', 7));
    await repository.updateDemo(users.single.id,
        nombre: 'Ana',
        apellidoPaterno: 'Prueba',
        apellidoMaterno: null,
        correo: 'ana@example.test');
    expect((requests.last.data as Map).containsKey('rol_id'), false);
    await repository.changeRoleDemo(users.single.id, '7');
    expect(requests.last.data, {'rol_id': 7});
    await repository.changeStatusDemo(users.single.id, false);
    expect(requests.last.data, {'activo': false});
    await expectLater(
        repository.deleteDemo(users.single.id), throwsA(isA<Exception>()));
    expect(requests.where((r) => r.method == 'DELETE'), isEmpty);
  });
}
