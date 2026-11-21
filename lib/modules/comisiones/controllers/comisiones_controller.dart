import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/env.dart';
import '../../../core/network/finanzas_api.dart';
import '../../auth/models/user_role_model.dart';
import '../models/comisiones_state_model.dart';
import '../models/commission_concept_model.dart';
import '../models/commission_line_model.dart';
import '../models/commission_payment_model.dart';
import '../models/commission_snapshot_model.dart';
import '../models/dispersion_receiver_model.dart';
import '../repositories/comisiones_repository.dart';

final comisionesRepositoryProvider = Provider<ComisionesRepository>(
    (ref) => ComisionesRepository(api: ref.watch(finanzasApiProvider)));

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
        await _repository.loadReal(_role);
      }
      state = AsyncData(_state());
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  CommissionPaymentModel? findPayment(String id) =>
      _repository.findPayment(id, _role);

  CommissionPaymentModel? findContract(String contractId) =>
      _repository.findContract(contractId, _role);

  List<DispersionReceiverModel> activeReceiversFor(int conceptId) =>
      _repository.activeReceiversFor(conceptId);

  List<DispersionReceiverModel> get eligibleAdvisorUsers =>
      _repository.eligibleAdvisorUsers;

  List<CommissionConceptModel> get concepts => _repository.concepts;

  Future<void> saveConfigurationDemo({
    required String contractId,
    required List<CommissionLineModel> lines,
    required String actor,
  }) async {
    if (!demoMode) {
      await _repository.api!.saveConfiguration(
          contractId,
          lines
              .map((l) => {
                    'concepto_id': l.conceptId,
                    if (l.receiverId.isNotEmpty)
                      'receptor_dispersion_id': l.receiverId,
                    'valor': l.percentage.toString(),
                  })
              .toList());
      await load();
      return;
    }
    _ensureDemo();
    _repository.saveConfigurationDemo(
      contractId: contractId,
      lines: lines,
      role: _role,
      actor: actor,
    );
    _refresh();
  }

  Future<void> createReceiverDemo({
    required int conceptId,
    required String? userId,
    required String? externalName,
  }) async {
    if (!demoMode) {
      await _repository.api!.createReceiver({
        'concepto_id': conceptId,
        if (userId != null) 'usuario_id': userId,
        if (externalName != null) 'nombre_externo': externalName
      });
      await load();
      return;
    }
    _ensureDemo();
    _repository.createReceiverDemo(
      conceptId: conceptId,
      userId: userId,
      externalName: externalName,
      role: _role,
    );
    _refresh();
  }

  Future<void> deactivateReceiverDemo(String receiverId) async {
    if (!demoMode) {
      await _repository.api!.deactivateReceiver(receiverId);
      await load();
      return;
    }
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
        payments: _repository.loadPayments(_role, demoMode: true) ?? const [],
        receivers: _repository.loadReceivers(_role, demoMode: true) ?? const [],
      );

  void _refresh() => state = AsyncData(_state());

  void _ensureDemo() {
    if (!demoMode) throw StateError('Las acciones demo no están disponibles.');
  }
}

final contractualCommissionProvider = FutureProvider.autoDispose
    .family<CommissionPaymentModel, String>((ref, id) async {
  final api = ref.watch(finanzasApiProvider);
  final contract = await api.detail('/finanzas/contratos/$id');
  final lines = await api.configuration(id);
  final history = await api.configurationHistory(id);
  return CommissionPaymentModel(
      id: id,
      paymentFolio: '',
      contractId: id,
      contractFolio: apiText(contract['folio']),
      clientName: _fullName(apiMap(contract['clientes'])),
      serviceName: apiText(apiMap(contract['servicios'])['nombre']),
      advisorName: _fullName(apiMap(contract['usuarios'])),
      paymentAmount: Decimal.zero,
      paymentDate: DateTime.parse(
          apiText(contract['creado_en'] ?? contract['fecha_contrato'])),
      paymentMethod: '',
      assignedToCurrentAdvisor: false,
      snapshot: const [],
      configuration: lines
          .map((r) => CommissionLineModel(
              conceptId: r['concepto_id'] as int,
              concept: apiText(apiMap(r['conceptos_dispersion'])['nombre']),
              receiverId: apiText(r['receptor_dispersion_id']),
              receiverName: _receiverName(apiMap(r['receptores_dispersion'])),
              percentage: Decimal.parse(apiText(r['valor']))))
          .toList(),
      configurationHistory: history
          .map((r) =>
              '${r['fecha_cambio']} - ${r['configuracion_anterior']} -> ${r['configuracion_nueva']}')
          .toList());
});

String _fullName(Map<String, dynamic> person) => [
      person['nombre'],
      person['apellido_paterno'],
      person['apellido_materno'],
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');

String _receiverName(Map<String, dynamic> receiver) {
  final external = apiText(receiver['nombre_externo']);
  return external.isNotEmpty ? external : _fullName(apiMap(receiver['usuarios_receptor']));
}
