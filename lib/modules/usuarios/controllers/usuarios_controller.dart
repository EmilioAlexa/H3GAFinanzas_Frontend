import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/env.dart';
import '../models/usuario_model.dart';
import '../repositories/usuarios_repository.dart';

final usuariosDemoModeProvider = Provider<bool>((ref) => AppEnv.demoMode);

final usuariosRepositoryProvider = Provider<UsuariosRepository>(
  (ref) => UsuariosRepository(),
);

final usuariosControllerProvider =
    StateNotifierProvider<UsuariosController, AsyncValue<List<UsuarioModel>>>(
        (ref) {
  return UsuariosController(ref.watch(usuariosRepositoryProvider));
});

class UsuariosController extends StateNotifier<AsyncValue<List<UsuarioModel>>> {
  UsuariosController(this._repository) : super(const AsyncLoading()) {
    loadDemo();
  }

  final UsuariosRepository _repository;

  void loadDemo() => state = AsyncData(_repository.listDemo());

  Future<UsuarioModel> createDemo({
    required String nombre,
    required String apellidoPaterno,
    required String? apellidoMaterno,
    required String correo,
    required String rolId,
    required String contrasena,
  }) async {
    final created = await _repository.createDemo(
      nombre: nombre,
      apellidoPaterno: apellidoPaterno,
      apellidoMaterno: apellidoMaterno,
      correo: correo,
      rolId: rolId,
      contrasena: contrasena,
    );
    loadDemo();
    return created;
  }

  Future<UsuarioModel> updateDemo(
    String id, {
    required String nombre,
    required String apellidoPaterno,
    required String? apellidoMaterno,
    required String correo,
  }) async {
    final updated = await _repository.updateDemo(
      id,
      nombre: nombre,
      apellidoPaterno: apellidoPaterno,
      apellidoMaterno: apellidoMaterno,
      correo: correo,
    );
    loadDemo();
    return updated;
  }

  Future<UsuarioModel> changeRoleDemo(String id, String roleId) async {
    final updated = await _repository.changeRoleDemo(id, roleId);
    loadDemo();
    return updated;
  }

  Future<UsuarioModel> changeStatusDemo(String id, bool active) async {
    final updated = await _repository.changeStatusDemo(id, active);
    loadDemo();
    return updated;
  }
}
