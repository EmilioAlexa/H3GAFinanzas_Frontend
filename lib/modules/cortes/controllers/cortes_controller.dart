import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/env.dart';
import '../../../core/network/finanzas_api.dart';
import '../models/cut_model.dart';
import '../repositories/cortes_repository.dart';

final cortesRepositoryProvider = Provider<CortesRepository>(
    (ref) => CortesRepository(api: ref.watch(finanzasApiProvider)));

final cortesControllerProvider =
    StateNotifierProvider<CortesController, AsyncValue<List<CutModel>?>>(
  (ref) => CortesController(
    ref.watch(cortesRepositoryProvider),
    demoMode: AppEnv.demoMode,
  ),
);

final corteDetailProvider = FutureProvider.family<CutModel, String>((ref, id) {
  final repository = ref.watch(cortesRepositoryProvider);
  if (AppEnv.demoMode) return repository.find(id)!;
  return repository.loadDetail(id);
});

class CortesController extends StateNotifier<AsyncValue<List<CutModel>?>> {
  CortesController(this._repository, {required this.demoMode})
      : super(const AsyncLoading()) {
    unawaited(load());
  }

  final CortesRepository _repository;
  final bool demoMode;
  Future<void>? _loading;

  Future<void> load() =>
      _loading ??= _load().whenComplete(() => _loading = null);

  Future<void> _load() async {
    state = const AsyncLoading();
    try {
      state = AsyncData(
          demoMode ? _repository.list() : await _repository.loadReal());
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  CutModel? find(String id) => _repository.find(id);

  CutModel? findByPeriod(DateTime periodStart) =>
      demoMode ? _repository.findByPeriod(periodStart) : null;

  Future<CutModel> createDemo(
      {required DateTime periodStart, required String actor}) async {
    if (!demoMode) {
      final civil =
          '${periodStart.year.toString().padLeft(4, '0')}-${periodStart.month.toString().padLeft(2, '0')}-${periodStart.day.toString().padLeft(2, '0')}';
      final row = await _repository.api!.createCut(civil);
      final cut = _repository.accept(row);
      state = AsyncData(_repository.list());
      return cut;
    }
    _requireDemo();
    final cut = _repository.createDemo(periodStart: periodStart, actor: actor);
    _refresh();
    return cut;
  }

  Future<CutModel> transitionDemo({
    required String id,
    required String action,
    required String actor,
    required String comment,
  }) async {
    if (!demoMode) {
      final row = await _repository.api!.cutAction(id, action, comment);
      final cut = _repository.accept(row);
      state = AsyncData(_repository.list());
      return cut;
    }
    _requireDemo();
    final cut = _repository.transitionDemo(
      id: id,
      action: action,
      actor: actor,
      comment: comment,
    );
    _refresh();
    return cut;
  }

  void _refresh() => state = AsyncData(_repository.list());

  void _requireDemo() {
    if (!demoMode) throw StateError('Las acciones demo no están disponibles.');
  }
}
