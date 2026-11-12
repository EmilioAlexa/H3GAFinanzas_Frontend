import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/env.dart';
import '../../auth/auth.dart';
import '../fixtures/contratos_demo_fixtures.dart';
import '../models/contrato_model.dart';
import '../models/servicio_model.dart';

final contratosRepositoryProvider = Provider<ContratosRepository>(
  (ref) => ContratosRepository(demoMode: AppEnv.demoMode),
);

class ContratosRepository {
  ContratosRepository({required this.demoMode})
      : _contracts = [...ContratosDemoFixtures.contracts];

  final bool demoMode;
  final List<ContratoModel> _contracts;

  Future<List<ContratoModel>?> load(UserRole role) async =>
      loadSynchronously(role);

  List<ContratoModel>? loadSynchronously(UserRole role) {
    if (!demoMode) return null;
    final contracts = role == UserRole.asesor
        ? _contracts.where((item) => item.assignedToCurrentAdvisor)
        : _contracts;
    return List.unmodifiable(contracts.toList());
  }

  Future<List<ServicioModel>?> loadServices() async =>
      demoMode ? List.unmodifiable(ContratosDemoFixtures.services) : null;

  ContratoModel? findById(String id, UserRole role) =>
      loadSynchronously(role)?.where((item) => item.id == id).firstOrNull;

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
