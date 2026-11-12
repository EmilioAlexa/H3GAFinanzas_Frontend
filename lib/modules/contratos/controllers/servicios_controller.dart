import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/servicio_model.dart';
import '../repositories/contratos_repository.dart';

final serviciosControllerProvider = StateNotifierProvider<ServiciosController,
    AsyncValue<List<ServicioModel>?>>(
  (ref) => ServiciosController(ref.watch(contratosRepositoryProvider)),
);

class ServiciosController
    extends StateNotifier<AsyncValue<List<ServicioModel>?>> {
  ServiciosController(this._repository) : super(const AsyncLoading()) {
    unawaited(load());
  }

  final ContratosRepository _repository;

  Future<void> load() async {
    state = const AsyncLoading();
    try {
      state = AsyncData(await _repository.loadServices());
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}
