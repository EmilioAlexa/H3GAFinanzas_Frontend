import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/modules/usuarios/repositories/usuarios_repository.dart';
import 'package:h3ga_finanzas/modules/usuarios/repositories/usuarios_repository_exception.dart';

void main() {
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
