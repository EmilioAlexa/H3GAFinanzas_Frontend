import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../app/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../auth/auth.dart';
import '../../contratos/fixtures/contratos_demo_fixtures.dart';
import '../../pagos/fixtures/pagos_demo_fixtures.dart';
import '../fixtures/clientes_demo_fixtures.dart';
import '../models/cliente_model.dart';

final clientesRepositoryProvider = Provider<ClientesRepository>(
  (ref) => ClientesRepository(
      demoMode: AppEnv.demoMode, dio: ref.watch(apiClientProvider)),
);

class ClientesRepository {
  ClientesRepository({required this.demoMode, this.dio})
      : _clients = [...ClientesDemoFixtures.clients];

  final bool demoMode;
  final Dio? dio;
  final List<ClienteModel> _clients;
  var _nextId = 6;

  Future<List<ClienteModel>?> load(UserRole role) async {
    if (demoMode) return loadSynchronously(role);
    return (await page()).data;
  }

  Future<({List<ClienteModel> data, int page, int total, int totalPages})> page(
      {int page = 1, int limit = 20, String? query}) async {
    final response =
        await dio!.get<Map<String, dynamic>>('/clientes', queryParameters: {
      'page': page,
      'limit': limit,
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
    });
    final body = response.data!;
    final pagination = body['pagination'] as Map<String, dynamic>;
    return (
      data: (body['data'] as List)
          .map(
              (e) => ClienteModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      page: pagination['page'] as int,
      total: pagination['total'] as int,
      totalPages: pagination['totalPages'] as int
    );
  }

  Future<ClienteModel> detail(String id) async => ClienteModel.fromJson(
      (await dio!.get<Map<String, dynamic>>('/clientes/$id')).data!);
  Future<ClienteModel> create(ClienteModel client,
          {String? referidorId}) async =>
      ClienteModel.fromJson(
          (await dio!.post<Map<String, dynamic>>('/clientes', data: {
        ...client.toApiPayload(),
        if (referidorId != null) 'referido_por_cliente_id': referidorId
      }))
              .data!);
  Future<ClienteModel> update(ClienteModel client) async =>
      ClienteModel.fromJson((await dio!.patch<Map<String, dynamic>>(
              '/clientes/${client.id}',
              data: client.toApiPayload()))
          .data!);
  Future<ClienteModel> setPaused(String id, bool paused) async =>
      ClienteModel.fromJson((await dio!.patch<Map<String, dynamic>>(
              '/clientes/$id/estado-operativo',
              data: {'pausado': paused}))
          .data!);
  Future<void> setReferidor(
      String id, String? referidorId, String motivo) async {
    await dio!.patch<void>('/clientes/$id/referidor',
        data: {'referidor_cliente_id': referidorId, 'motivo': motivo});
  }

  Future<List<dynamic>> referidorHistory(String id) async =>
      (await dio!.get<List<dynamic>>('/clientes/$id/referidor/historial'))
          .data!;
  Future<Map<String, dynamic>> dependencies(String id) async =>
      (await dio!.get<Map<String, dynamic>>('/clientes/$id/dependencias'))
          .data!;
  Future<void> delete(String id) async {
    await dio!.delete<void>('/clientes/$id');
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
    String? asesorId,
    String? asesorNombre,
    DateTime? fechaIngreso,
    DateTime? fechaNacimiento,
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
      asesorId: asesorId,
      fechaIngreso: fechaIngreso ?? DateTime.now(),
      fechaNacimiento: fechaNacimiento,
      demoMetadata: (
        status: 'Activo',
        advisorName: asesorNombre,
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
      asesorId: updated.asesorId ?? current.asesorId,
      fechaIngreso: updated.fechaIngreso ?? current.fechaIngreso,
      fechaNacimiento: updated.fechaNacimiento ?? current.fechaNacimiento,
      direccion: updated.direccion,
      referidoPor: updated.referidoPor,
      observaciones: updated.observaciones,
      demoMetadata: updated.demoMetadata ?? current.demoMetadata,
    );
    _clients[index] = client;
    return client;
  }

  void deleteDemo(String clientId) {
    _requireDemoMode();
    final index = _clients.indexWhere((client) => client.id == clientId);
    if (index < 0) throw StateError('No se encontró el cliente de demo.');
    final client = _clients[index];
    if (client.demoMetadata?.status != 'Pausado') {
      throw StateError('Solo puedes eliminar clientes pausados.');
    }
    final contractIds = ContratosDemoFixtures.contracts
        .where((contract) => contract.clienteId == clientId)
        .map((contract) => contract.id)
        .toSet();
    if (contractIds.isNotEmpty ||
        PagosDemoFixtures.payments
            .any((payment) => contractIds.contains(payment.contratoId))) {
      throw StateError(
        'No puedes eliminar un cliente con contratos o pagos asignados.',
      );
    }
    _clients.removeAt(index);
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
