import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/env.dart';
import '../models/prenomina_model.dart';
import '../repositories/prenomina_repository.dart';

final prenominaRepositoryProvider =
    Provider<PrenominaRepository>((ref) => PrenominaRepository());

final prenominaControllerProvider = StateNotifierProvider<PrenominaController,
    AsyncValue<List<PrenominaModel>?>>(
  (ref) => PrenominaController(
    ref.watch(prenominaRepositoryProvider),
    demoMode: AppEnv.demoMode,
  ),
);

class PrenominaController
    extends StateNotifier<AsyncValue<List<PrenominaModel>?>> {
  PrenominaController(this._repository, {required this.demoMode})
      : super(const AsyncLoading()) {
    unawaited(load());
  }

  final PrenominaRepository _repository;
  final bool demoMode;

  Future<void> load() async {
    state = const AsyncLoading();
    try {
      state = AsyncData(demoMode ? _repository.listDemo() : null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  List<PrenominaModel> forCut(String cutId) =>
      demoMode ? _repository.recipientsForCut(cutId) : const [];

  PrenominaModel? find(String id) => demoMode ? _repository.findDemo(id) : null;

  void generateDemo(String cutId) {
    if (!demoMode) {
      throw StateError('La generación demo no está habilitada.');
    }
    _repository.generateDemo(cutId);
    state = AsyncData(_repository.listDemo());
  }
}
