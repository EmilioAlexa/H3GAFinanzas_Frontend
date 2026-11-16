import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth.dart';
import '../../../core/platform/selected_file.dart';
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

  Future<void> load() async {
    state = const AsyncLoading();
    try {
      state = AsyncData(await _repository.load(_role));
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
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
