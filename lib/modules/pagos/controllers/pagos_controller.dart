import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/env.dart';
import '../../../core/platform/selected_file.dart';
import '../../auth/models/user_role_model.dart';
import '../../contratos/contratos.dart';
import '../models/pago_model.dart';
import '../models/pago_programado_model.dart';
import '../repositories/pagos_repository.dart';

final pagosRepositoryProvider =
    Provider<PagosRepository>((ref) => PagosRepository());
final pagosControllerProvider = StateNotifierProvider.family<PagosController,
        AsyncValue<PagosState?>, UserRole>(
    (ref, role) => PagosController(ref.watch(pagosRepositoryProvider), role,
        demoMode: AppEnv.demoMode));

class PagosState {
  const PagosState({required this.payments, required this.scheduled});
  final List<PagoModel> payments;
  final List<PagoProgramadoModel> scheduled;
}

class PagosController extends StateNotifier<AsyncValue<PagosState?>> {
  PagosController(this._repository, this._role, {required this.demoMode})
      : super(const AsyncLoading()) {
    unawaited(load());
  }

  final PagosRepository _repository;
  final UserRole _role;
  final bool demoMode;

  Future<void> load() async {
    state = const AsyncLoading();
    try {
      if (!demoMode) {
        state = const AsyncData(null);
        return;
      }
      state = AsyncData(PagosState(
        payments:
            _repository.loadPayments(_role, demoMode: demoMode) ?? const [],
        scheduled:
            _repository.loadScheduled(_role, demoMode: demoMode) ?? const [],
      ));
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  PagoModel? findPayment(String id) =>
      demoMode ? _repository.findPayment(id, _role) : null;

  PagoModel createPayment(
      {required ContratoModel contract,
      required int methodId,
      required String method,
      required Decimal amount,
      required DateTime date,
      required String reference,
      required String observations,
      String? scheduleId,
      String? receiptFolio,
      String? receivedBy,
      List<SelectedFile> evidenceFiles = const []}) {
    final value = _repository.createPayment(
        contract: contract,
        methodId: methodId,
        method: method,
        amount: amount,
        date: date,
        reference: reference,
        observations: observations,
        scheduleId: scheduleId,
        receiptFolio: receiptFolio,
        receivedBy: receivedBy,
        evidenceFiles: evidenceFiles);
    _refresh();
    return value;
  }

  PagoProgramadoModel createScheduled(
      {required ContratoModel contract,
      required int number,
      required Decimal? amount,
      required DateTime? expectedDate,
      required DateTime? dueDate,
      required DateTime? period}) {
    final value = _repository.createScheduled(
        contract: contract,
        number: number,
        amount: amount,
        expectedDate: expectedDate,
        dueDate: dueDate,
        period: period);
    _refresh();
    return value;
  }

  void _refresh() => state = AsyncData(PagosState(
        payments:
            _repository.loadPayments(_role, demoMode: demoMode) ?? const [],
        scheduled:
            _repository.loadScheduled(_role, demoMode: demoMode) ?? const [],
      ));
}
