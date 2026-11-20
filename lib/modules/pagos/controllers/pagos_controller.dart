import 'dart:async';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/platform/selected_file.dart';
import '../../auth/auth.dart';
import '../../contratos/contratos.dart';
import '../models/evidencia_pago_model.dart';
import '../models/pago_model.dart';
import '../models/pago_programado_model.dart';
import '../models/pago_review_policy.dart';
import '../repositories/pagos_repository.dart';

final pagosRepositoryProvider = Provider<PagosRepository>((ref) {
  ref.watch(authControllerProvider);
  return PagosRepository(dio: ref.watch(apiClientProvider));
});
final pagosControllerProvider = StateNotifierProvider.family<PagosController,
        AsyncValue<PagosState?>, UserRole>(
    (ref, role) => PagosController(ref.watch(pagosRepositoryProvider), role,
        demoMode: AppEnv.demoMode));

class PagosState {
  const PagosState(
      {required this.payments, required this.scheduled, this.scheduledError});
  final Object? scheduledError;
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

  int _loadVersion = 0;

  Future<void> load() async {
    final version = ++_loadVersion;
    state = const AsyncLoading();
    try {
      if (!demoMode) {
        final paymentFuture = _repository.payments();
        Object? scheduleError;
        final scheduleFuture =
            _repository.scheduled().catchError((Object error) {
          scheduleError = error;
          return <PagoProgramadoModel>[];
        });
        final results =
            await Future.wait<Object>([paymentFuture, scheduleFuture]);
        if (mounted && version == _loadVersion) {
          state = AsyncData(PagosState(
              payments: results[0] as List<PagoModel>,
              scheduled: results[1] as List<PagoProgramadoModel>,
              scheduledError: scheduleError));
        }
        return;
      }
      state = AsyncData(PagosState(
        payments:
            _repository.loadPayments(_role, demoMode: demoMode) ?? const [],
        scheduled:
            _repository.loadScheduled(_role, demoMode: demoMode) ?? const [],
      ));
    } catch (error, stackTrace) {
      if (mounted && version == _loadVersion) {
        state = AsyncError(error, stackTrace);
      }
    }
  }

  Future<PagoModel> createApi(Map<String, dynamic> payload) async {
    final payment = await _repository.create(payload);
    if (mounted) await load();
    return payment;
  }

  Future<PagoModel> correctApi(String id, Map<String, dynamic> payload) async {
    final payment = await _repository.correct(id, payload);
    if (mounted) await load();
    return payment;
  }

  Future<PagoModel> reviewApi(
      PagoModel payment, String action, String comment) async {
    if (!paymentReviewActions(payment, _role).contains(action)) {
      throw StateError(
          'Acción no permitida para el rol, estado o evidencia actual.');
    }
    if (action == 'rechazar' && comment.trim().isEmpty) {
      throw StateError('Indica el motivo de rechazo.');
    }
    final updated = await _repository.review(payment.id, action, comment);
    if (mounted) await load();
    return updated;
  }

  PagoModel? findPayment(String id) =>
      demoMode ? _repository.findPayment(id, _role) : null;

  PagoModel changeReviewStateDemo({
    required String paymentId,
    required String action,
    required String comment,
    required String actor,
  }) {
    if (!demoMode) {
      throw StateError('Las acciones de demostración están deshabilitadas.');
    }
    final updated = _repository.changeReviewStateDemo(
      paymentId: paymentId,
      role: _role,
      action: action,
      comment: comment,
      actor: actor,
    );
    _refresh();
    return updated;
  }

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

  PagoModel resubmitRejectedDemo({
    required String paymentId,
    required ContratoModel contract,
    required int methodId,
    required String method,
    required Decimal amount,
    required DateTime date,
    required String reference,
    required String observations,
    required String? scheduleId,
    required String? receiptFolio,
    required String? receivedBy,
    required List<EvidenciaPagoModel> existingEvidence,
    required List<SelectedFile> evidenceFiles,
  }) {
    final value = _repository.resubmitRejectedDemo(
      paymentId: paymentId,
      role: _role,
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
      existingEvidence: existingEvidence,
      evidenceFiles: evidenceFiles,
    );
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

final pagoDetailProvider =
    FutureProvider.autoDispose.family<PagoModel, String>((ref, id) {
  final session = ref.watch(authControllerProvider).valueOrNull;
  if (AppEnv.demoMode) {
    return ref.watch(pagosRepositoryProvider).findPayment(id, session!.role)!;
  }
  return ref.watch(pagosRepositoryProvider).detail(id);
});

final evidenceBytesProvider = FutureProvider.autoDispose
    .family<Uint8List, String>(
        (ref, id) => ref.watch(pagosRepositoryProvider).download(id));
