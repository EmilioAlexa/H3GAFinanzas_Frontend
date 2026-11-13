import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/env.dart';
import '../models/cut_model.dart';
import '../repositories/cortes_repository.dart';

final cortesRepositoryProvider =
    Provider<CortesRepository>((ref) => CortesRepository());

final cortesControllerProvider =
    StateNotifierProvider<CortesController, AsyncValue<List<CutModel>?>>(
  (ref) => CortesController(
    ref.watch(cortesRepositoryProvider),
    demoMode: AppEnv.demoMode,
  ),
);

class CortesController extends StateNotifier<AsyncValue<List<CutModel>?>> {
  CortesController(this._repository, {required this.demoMode})
      : super(const AsyncLoading()) {
    unawaited(load());
  }

  final CortesRepository _repository;
  final bool demoMode;

  Future<void> load() async {
    state = const AsyncLoading();
    try {
      state = AsyncData(demoMode ? _repository.list() : null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  CutModel? find(String id) => demoMode ? _repository.find(id) : null;

  CutModel? findByPeriod(DateTime periodStart) =>
      demoMode ? _repository.findByPeriod(periodStart) : null;

  CutModel createDemo({required DateTime periodStart, required String actor}) {
    _requireDemo();
    final cut = _repository.createDemo(periodStart: periodStart, actor: actor);
    _refresh();
    return cut;
  }

  CutModel transitionDemo({
    required String id,
    required String action,
    required String actor,
    required String comment,
  }) {
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
