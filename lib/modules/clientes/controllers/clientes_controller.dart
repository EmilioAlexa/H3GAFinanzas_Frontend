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

final clienteDetalleProvider = FutureProvider.family<ClienteModel, String>(
  (ref, id) => ref.watch(clientesRepositoryProvider).detail(id),
);

class ClientesController
    extends StateNotifier<AsyncValue<List<ClienteModel>?>> {
  ClientesController(this._repository, this._role)
      : super(const AsyncLoading()) {
    unawaited(load());
  }

  final ClientesRepository _repository;
  final UserRole _role;
  int pageNumber = 1;
  int total = 0;
  int totalPages = 0;
  String query = '';
  int _generation = 0;

  Future<void> load() async {
    final generation = ++_generation;
    state = const AsyncLoading();
    try {
      if (_repository.demoMode) {
        final clients = await _repository.load(_role);
        if (mounted && generation == _generation) state = AsyncData(clients);
      } else {
        final result =
            await _repository.page(page: pageNumber, limit: 20, query: query);
        if (!mounted || generation != _generation) return;
        pageNumber = result.page;
        total = result.total;
        totalPages = result.totalPages;
        state = AsyncData(result.data);
      }
    } catch (error, stackTrace) {
      if (mounted && generation == _generation)
        state = AsyncError(error, stackTrace);
    }
  }

  Future<void> search(String value) async {
    query = value;
    pageNumber = 1;
    await load();
  }

  Future<void> goToPage(int value) async {
    pageNumber = value;
    await load();
  }

  Future<ClienteModel> save(ClienteModel client,
      {required bool editing, String? referidorId}) async {
    final saved = editing
        ? await _repository.update(client)
        : await _repository.create(client, referidorId: referidorId);
    await load();
    return saved;
  }

  Future<void> setPaused(ClienteModel client) async {
    await _repository.setPaused(client.id, !(client.pausado ?? false));
    await load();
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
