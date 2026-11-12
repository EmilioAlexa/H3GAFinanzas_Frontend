import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/env.dart';
import '../../auth/auth.dart';
import '../fixtures/clientes_demo_fixtures.dart';
import '../models/cliente_model.dart';

final clientesRepositoryProvider = Provider<ClientesRepository>(
  (ref) => ClientesRepository(demoMode: AppEnv.demoMode),
);

class ClientesRepository {
  ClientesRepository({required this.demoMode})
      : _clients = [...ClientesDemoFixtures.clients];

  final bool demoMode;
  final List<ClienteModel> _clients;
  var _nextId = 6;

  Future<List<ClienteModel>?> load(UserRole role) async {
    return loadSynchronously(role);
  }

  List<ClienteModel>? loadSynchronously(UserRole role) {
    if (!demoMode) return null;
    final clients = role == UserRole.asesor
        ? _clients
            .where((client) =>
                client.demoMetadata?.assignedToCurrentAdvisor ?? false)
            .toList()
        : _clients;
    return List.unmodifiable(clients);
  }

  ClienteModel createDemo({
    required String nombre,
    required String apellidoPaterno,
    String? apellidoMaterno,
    String? telefono,
    String? correoElectronico,
    String? curp,
    String? rfc,
  }) {
    _requireDemoMode();
    final client = ClienteModel(
      id: 'demo-client-${_nextId++}',
      nombre: nombre,
      apellidoPaterno: apellidoPaterno,
      apellidoMaterno: apellidoMaterno,
      telefono: telefono,
      correoElectronico: correoElectronico,
      curp: curp,
      rfc: rfc,
      demoMetadata: (
        status: 'Nuevo · demo',
        advisorName: 'Asesor de demostración',
        service: null,
        assignedToCurrentAdvisor: true,
      ),
    );
    _clients.insert(0, client);
    return client;
  }

  ClienteModel updateDemo(ClienteModel updated) {
    _requireDemoMode();
    final index = _clients.indexWhere((client) => client.id == updated.id);
    if (index < 0) throw StateError('No se encontró el cliente de demo.');
    final current = _clients[index];
    final client = ClienteModel(
      id: current.id,
      nombre: updated.nombre,
      apellidoPaterno: updated.apellidoPaterno,
      apellidoMaterno: updated.apellidoMaterno,
      telefono: updated.telefono,
      correoElectronico: updated.correoElectronico,
      curp: updated.curp,
      rfc: updated.rfc,
      asesorId: current.asesorId,
      demoMetadata: current.demoMetadata,
    );
    _clients[index] = client;
    return client;
  }

  void _requireDemoMode() {
    if (!demoMode) {
      throw StateError(
          'Las acciones de muestra solo están disponibles en demo.');
    }
  }
}
