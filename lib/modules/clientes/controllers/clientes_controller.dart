import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth.dart';
import '../models/cliente_model.dart';
import '../repositories/clientes_repository.dart';

final clientesControllerProvider = StateNotifierProvider.family<
    ClientesController, AsyncValue<List<ClienteModel>?>, UserRole>(
  (ref, role) => ClientesController(
    ref.watch(clientesRepositoryProvider),
    role,
  ),
);

class ClientesController
    extends StateNotifier<AsyncValue<List<ClienteModel>?>> {
  ClientesController(this._repository, this._role)
      : super(const AsyncLoading()) {
    unawaited(load());
  }

  final ClientesRepository _repository;
  final UserRole _role;

  Future<void> load() async {
    state = const AsyncLoading();
    try {
      state = AsyncData(await _repository.load(_role));
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  ClienteModel createDemo({
    required String nombre,
    required String apellidoPaterno,
    String? apellidoMaterno,
    String? telefono,
    String? correoElectronico,
    String? curp,
    String? rfc,
    String? asesorId,
    String? asesorNombre,
    DateTime? fechaIngreso,
    DateTime? fechaNacimiento,
  }) {
    final client = _repository.createDemo(
      nombre: nombre,
      apellidoPaterno: apellidoPaterno,
      apellidoMaterno: apellidoMaterno,
      telefono: telefono,
      correoElectronico: correoElectronico,
      curp: curp,
      rfc: rfc,
      asesorId: asesorId,
      asesorNombre: asesorNombre,
      fechaIngreso: fechaIngreso,
      fechaNacimiento: fechaNacimiento,
    );
    state = AsyncData(_repository.loadSynchronously(_role));
    return client;
  }

  ClienteModel updateDemo(ClienteModel client) {
    final updated = _repository.updateDemo(client);
    state = AsyncData(_repository.loadSynchronously(_role));
    return updated;
  }

  void deleteDemo(String clientId) {
    _repository.deleteDemo(clientId);
    state = AsyncData(_repository.loadSynchronously(_role));
  }

  ClienteModel toggleStatusDemo(String clientId) {
    final updated = _repository.toggleStatusDemo(clientId);
    state = AsyncData(_repository.loadSynchronously(_role));
    return updated;
  }
}
