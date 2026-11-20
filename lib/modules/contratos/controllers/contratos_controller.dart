import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/selected_file.dart';
import '../../auth/auth.dart';
import '../models/contrato_model.dart';
import '../models/penalizacion_model.dart';
import '../repositories/contratos_repository.dart';

final contratosControllerProvider = StateNotifierProvider.family<
    ContratosController, AsyncValue<List<ContratoModel>?>, UserRole>(
  (ref, role) =>
      ContratosController(ref.watch(contratosRepositoryProvider), role),
);

class ContratosController
    extends StateNotifier<AsyncValue<List<ContratoModel>?>> {
  ContratosController(this._repository, this._role)
      : super(const AsyncLoading()) {
    unawaited(load());
  }

  final ContratosRepository _repository;
  final UserRole _role;
  int _loadVersion = 0;

  Future<void> load() async {
    final version = ++_loadVersion;
    state = const AsyncLoading();
    try {
      final contracts = await _repository.load(_role);
      if (mounted && version == _loadVersion) {
        state = AsyncData(contracts);
      }
    } catch (error, stackTrace) {
      if (mounted && version == _loadVersion) {
        state = AsyncError(error, stackTrace);
      }
    }
  }

  Future<ContratoModel> create(Map<String, dynamic> payload) async {
    final contract = await _repository.create(payload);
    if (mounted) await load();
    return contract;
  }

  Future<ContratoModel> updateObservations(
      String id, String? observations) async {
    final contract =
        await _repository.updateObservations(id, observations, _role);
    if (mounted) await load();
    return contract;
  }

  ContratoModel? findById(String id) => _repository.findById(id, _role);

  List<PenalizacionModel> penaltiesFor(String contractId) =>
      _repository.penaltiesFor(contractId);

  PenalizacionModel createPenaltyDemo({
    required String contractId,
    required String concepto,
    required Decimal monto,
    required DateTime fecha,
    required String estado,
    required String? observaciones,
  }) {
    final penalty = _repository.createPenaltyDemo(
      contractId: contractId,
      concepto: concepto,
      monto: monto,
      fecha: fecha,
      estado: estado,
      observaciones: observaciones,
    );
    state = AsyncData(_repository.loadSynchronously(_role));
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
    required String currentUserId,
    required String currentUserName,
    String? advisorId,
    String? advisorName,
    List<SelectedFile> documentos = const [],
  }) {
    final contract = _repository.createDemo(
      clienteId: clienteId,
      clienteNombre: clienteNombre,
      servicioId: servicioId,
      folio: folio,
      fechaContrato: fechaContrato,
      estadoContratoId: estadoContratoId,
      estadoNombre: estadoNombre,
      cantidadPagos: cantidadPagos,
      observaciones: observaciones,
      role: _role,
      currentUserId: currentUserId,
      currentUserName: currentUserName,
      advisorId: advisorId,
      advisorName: advisorName,
      documentos: documentos,
    );
    state = AsyncData(_repository.loadSynchronously(_role));
    return contract;
  }

  ContratoModel updateObservationsDemo(String id, String? observations) {
    final contract = _repository.updateObservationsDemo(
      contractId: id,
      observations: observations,
      role: _role,
    );
    state = AsyncData(_repository.loadSynchronously(_role));
    return contract;
  }
}

final contratoDetailProvider =
    FutureProvider.autoDispose.family<ContratoModel, String>((ref, id) {
  final session = ref.watch(authControllerProvider).valueOrNull;
  return ref.watch(contratosRepositoryProvider).detail(id, session!.role);
});
