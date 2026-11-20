import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/platform/selected_file.dart';
import '../../auth/auth.dart';
import '../fixtures/contratos_demo_fixtures.dart';
import '../models/contrato_model.dart';
import '../models/penalizacion_model.dart';
import '../models/servicio_model.dart';

final contratosRepositoryProvider = Provider<ContratosRepository>(
  (ref) {
    ref.watch(authControllerProvider);
    return ContratosRepository(
        demoMode: AppEnv.demoMode, dio: ref.watch(apiClientProvider));
  },
);

class ContratosRepository {
  ContratosRepository({required this.demoMode, this.dio})
      : _contracts = [...ContratosDemoFixtures.contracts];

  final Dio? dio;
  final List<ContratoModel> _realContracts = [];
  final bool demoMode;
  final List<ContratoModel> _contracts;
  final List<PenalizacionModel> _penalties = [
    ...ContratosDemoFixtures.penalties,
  ];

  Future<List<ContratoModel>?> load(UserRole role) async {
    if (demoMode) return loadSynchronously(role);
    final rows = await readAll('/finanzas/contratos');
    _realContracts
      ..clear()
      ..addAll(rows.map(ContratoModel.fromJson));
    return List.unmodifiable(_realContracts);
  }

  Future<List<Map<String, dynamic>>> readAll(String path,
      {Map<String, dynamic> filters = const {}}) async {
    final rows = <Map<String, dynamic>>[];
    var page = 1;
    while (true) {
      final body = (await dio!.get<Map<String, dynamic>>(path,
              queryParameters: {...filters, 'page': page, 'limit': 100}))
          .data!;
      rows.addAll((body['data'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map)));
      final pagination = body['pagination'] as Map<String, dynamic>;
      if (page >= (pagination['totalPages'] as int)) break;
      page++;
    }
    return rows;
  }

  Future<ContratoModel> detail(String id, UserRole role) async {
    if (demoMode) return findById(id, role)!;
    return ContratoModel.fromJson(
        (await dio!.get<Map<String, dynamic>>('/finanzas/contratos/$id'))
            .data!);
  }

  Future<ContratoModel> create(Map<String, dynamic> payload) async {
    final contract = ContratoModel.fromJson((await dio!
            .post<Map<String, dynamic>>('/finanzas/contratos', data: payload))
        .data!);
    _realContracts.insert(0, contract);
    return contract;
  }

  Future<ContratoModel> updateObservations(
      String id, String? observations, UserRole role) async {
    if (demoMode) {
      return updateObservationsDemo(
          contractId: id, observations: observations, role: role);
    }
    final contract = ContratoModel.fromJson((await dio!
            .patch<Map<String, dynamic>>('/finanzas/contratos/$id',
                data: {'observaciones': observations}))
        .data!);
    final index = _realContracts.indexWhere((e) => e.id == id);
    if (index >= 0) _realContracts[index] = contract;
    return contract;
  }

  Future<List<({int id, String name})>> loadStates() async {
    if (demoMode) return [(id: 1, name: 'Activo')];
    return (await readAll('/finanzas/catalogos/estados-contrato'))
        .map((e) => (id: e['id'] as int, name: e['nombre'] as String))
        .toList();
  }

  Future<ServicioModel> serviceDetail(int id) async =>
      ServicioModel.fromJson((await dio!
              .get<Map<String, dynamic>>('/finanzas/catalogos/servicios/$id'))
          .data!);

  List<ContratoModel>? loadSynchronously(UserRole role) {
    if (!demoMode) return List.unmodifiable(_realContracts);
    final contracts = role == UserRole.asesor
        ? _contracts.where((item) => item.assignedToCurrentAdvisor)
        : _contracts;
    return List.unmodifiable(contracts.toList());
  }

  Future<List<ServicioModel>?> loadServices() async => demoMode
      ? List.unmodifiable(ContratosDemoFixtures.services)
      : (await readAll('/finanzas/catalogos/servicios'))
          .map(ServicioModel.fromJson)
          .toList();

  ContratoModel? findById(String id, UserRole role) =>
      loadSynchronously(role)?.where((item) => item.id == id).firstOrNull;

  List<PenalizacionModel> penaltiesFor(String contractId) => List.unmodifiable(
        _penalties.where((item) => demoMode && item.contratoId == contractId),
      );

  PenalizacionModel createPenaltyDemo({
    required String contractId,
    required String concepto,
    required Decimal monto,
    required DateTime fecha,
    required String estado,
    required String? observaciones,
  }) {
    _requireDemoMode();
    final penalty = PenalizacionModel(
      id: 'demo-penalty-${_penalties.length + 1}',
      contratoId: contractId,
      concepto: concepto,
      monto: monto,
      fecha: fecha,
      estado: estado,
      observaciones: observaciones,
    );
    _penalties.insert(0, penalty);
    return penalty;
  }

  ContratoModel createDemo({
    required String clienteId,
    required String clienteNombre,
    required int servicioId,
    required String folio,
    required DateTime fechaContrato,
    required int estadoContratoId,
    required String estadoNombre,
    required int? cantidadPagos,
    required String? observaciones,
    required UserRole role,
    required String currentUserId,
    required String currentUserName,
    String? advisorId,
    String? advisorName,
    List<SelectedFile> documentos = const [],
  }) {
    _requireDemoMode();
    final service = ContratosDemoFixtures.services
        .firstWhere((item) => item.id == servicioId);
    final isAdvisor = role == UserRole.asesor;
    final contract = ContratoModel(
      id: 'demo-contract-${_contracts.length + 1}',
      clienteId: clienteId,
      servicioId: servicioId,
      asesorId: isAdvisor ? currentUserId : advisorId!,
      folio: folio,
      fechaContrato: fechaContrato,
      estadoContratoId: estadoContratoId,
      cantidadPagos: cantidadPagos,
      observaciones: observaciones,
      creadoEn: DateTime.now(),
      clienteNombre: clienteNombre,
      servicioNombre: service.nombre,
      asesorNombre: isAdvisor ? currentUserName : advisorName!,
      estadoNombre: estadoNombre,
      documentos: List.unmodifiable(documentos),
      assignedToCurrentAdvisor: isAdvisor,
    );
    _contracts.insert(0, contract);
    return contract;
  }

  ContratoModel updateObservationsDemo({
    required String contractId,
    required String? observations,
    required UserRole role,
  }) {
    _requireDemoMode();
    final index = _contracts.indexWhere((item) => item.id == contractId);
    if (index < 0) throw StateError('No se encontró el contrato de muestra.');
    final current = _contracts[index];
    if (role == UserRole.asesor && !current.assignedToCurrentAdvisor) {
      throw StateError('El contrato no está asignado a esta sesión demo.');
    }
    final updated = ContratoModel(
      id: current.id,
      clienteId: current.clienteId,
      servicioId: current.servicioId,
      asesorId: current.asesorId,
      folio: current.folio,
      fechaContrato: current.fechaContrato,
      estadoContratoId: current.estadoContratoId,
      cantidadPagos: current.cantidadPagos,
      observaciones: observations,
      totalPagar: current.totalPagar,
      montoMensual: current.montoMensual,
      saldoPendiente: current.saldoPendiente,
      documentos: current.documentos,
      creadoEn: current.creadoEn,
      clienteNombre: current.clienteNombre,
      servicioNombre: current.servicioNombre,
      asesorNombre: current.asesorNombre,
      estadoNombre: current.estadoNombre,
      assignedToCurrentAdvisor: current.assignedToCurrentAdvisor,
    );
    _contracts[index] = updated;
    return updated;
  }

  void _requireDemoMode() {
    if (!demoMode) {
      throw StateError(
          'Las acciones de muestra solo están disponibles en demo.');
    }
  }
}
