import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/env.dart';
import '../../auth/models/user_role_model.dart';
import '../models/comisiones_state_model.dart';
import '../models/commission_concept_model.dart';
import '../models/commission_line_model.dart';
import '../models/commission_payment_model.dart';
import '../models/commission_snapshot_model.dart';
import '../models/dispersion_receiver_model.dart';
import '../repositories/comisiones_repository.dart';

final comisionesRepositoryProvider =
    Provider<ComisionesRepository>((ref) => ComisionesRepository());

final comisionesControllerProvider = StateNotifierProvider.family<
    ComisionesController, AsyncValue<ComisionesStateModel?>, UserRole>(
  (ref, role) => ComisionesController(
    ref.watch(comisionesRepositoryProvider),
    role,
    demoMode: AppEnv.demoMode,
  ),
);

class ComisionesController
    extends StateNotifier<AsyncValue<ComisionesStateModel?>> {
  ComisionesController(this._repository, this._role, {required this.demoMode})
      : super(const AsyncLoading()) {
    unawaited(load());
  }

  final ComisionesRepository _repository;
  final UserRole _role;
  final bool demoMode;

  Future<void> load() async {
    state = const AsyncLoading();
    try {
      if (!demoMode) {
        state = const AsyncData(null);
        return;
      }
      state = AsyncData(_state());
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  CommissionPaymentModel? findPayment(String id) =>
      demoMode ? _repository.findPayment(id, _role) : null;

  CommissionPaymentModel? findContract(String contractId) =>
      demoMode ? _repository.findContract(contractId, _role) : null;

  List<DispersionReceiverModel> activeReceiversFor(int conceptId) =>
      demoMode ? _repository.activeReceiversFor(conceptId) : const [];

  List<CommissionConceptModel> get concepts => _repository.concepts;

  void saveConfigurationDemo({
    required String contractId,
    required List<CommissionLineModel> lines,
    required String actor,
  }) {
    _ensureDemo();
    _repository.saveConfigurationDemo(
      contractId: contractId,
      lines: lines,
      role: _role,
      actor: actor,
    );
    _refresh();
  }

  DispersionReceiverModel createReceiverDemo({
    required int conceptId,
    required String? userId,
    required String? externalName,
  }) {
    _ensureDemo();
    final receiver = _repository.createReceiverDemo(
      conceptId: conceptId,
      userId: userId,
      externalName: externalName,
      role: _role,
    );
    _refresh();
    return receiver;
  }

  void deactivateReceiverDemo(String receiverId) {
    _ensureDemo();
    _repository.deactivateReceiverDemo(receiverId, _role);
    _refresh();
  }

  CommissionSnapshotModel disperseDemo({
    required String paymentId,
    required String commissionId,
    required String comment,
    required String actor,
  }) {
    _ensureDemo();
    final value = _repository.disperseDemo(
      paymentId: paymentId,
      commissionId: commissionId,
      role: _role,
      comment: comment,
      actor: actor,
    );
    _refresh();
    return value;
  }

  ComisionesStateModel _state() => ComisionesStateModel(
        payments:
            _repository.loadPayments(_role, demoMode: demoMode) ?? const [],
        receivers:
            _repository.loadReceivers(_role, demoMode: demoMode) ?? const [],
      );

  void _refresh() => state = AsyncData(_state());

  void _ensureDemo() {
    if (!demoMode) throw StateError('Las acciones demo no están disponibles.');
  }
}
