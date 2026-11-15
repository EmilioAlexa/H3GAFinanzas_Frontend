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
      fechaIngreso: DateTime.now(),
      demoMetadata: (
        status: 'Activo',
        advisorName: 'Asesor asignado',
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
      fechaIngreso: updated.fechaIngreso ?? current.fechaIngreso,
      fechaNacimiento: updated.fechaNacimiento ?? current.fechaNacimiento,
      direccion: updated.direccion,
      referidoPor: updated.referidoPor,
      observaciones: updated.observaciones,
      demoMetadata: current.demoMetadata,
    );
    _clients[index] = client;
    return client;
  }

  ClienteModel toggleStatusDemo(String clientId) {
    _requireDemoMode();
    final index = _clients.indexWhere((client) => client.id == clientId);
    if (index < 0) throw StateError('No se encontrÃ³ el cliente de demo.');
    final current = _clients[index];
    final metadata = current.demoMetadata;
    if (metadata == null) return current;
    final updated = ClienteModel(
      id: current.id,
      nombre: current.nombre,
      apellidoPaterno: current.apellidoPaterno,
      apellidoMaterno: current.apellidoMaterno,
      telefono: current.telefono,
      correoElectronico: current.correoElectronico,
      curp: current.curp,
      rfc: current.rfc,
      asesorId: current.asesorId,
      fechaIngreso: current.fechaIngreso,
      fechaNacimiento: current.fechaNacimiento,
      direccion: current.direccion,
      referidoPor: current.referidoPor,
      observaciones: current.observaciones,
      demoMetadata: (
        status: metadata.status == 'Pausado' ? 'Activo' : 'Pausado',
        advisorName: metadata.advisorName,
        service: metadata.service,
        assignedToCurrentAdvisor: metadata.assignedToCurrentAdvisor,
      ),
    );
    _clients[index] = updated;
    return updated;
  }

  void _requireDemoMode() {
    if (!demoMode) {
      throw StateError(
          'Las acciones de muestra solo están disponibles en demo.');
    }
  }
}
