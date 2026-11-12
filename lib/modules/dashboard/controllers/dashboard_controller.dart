import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth.dart';
import '../models/dashboard_model.dart';
import '../repositories/dashboard_repository.dart';

final dashboardControllerProvider = StateNotifierProvider.family<
    DashboardController, AsyncValue<DashboardModel?>, UserRole>(
  (ref, role) => DashboardController(
    ref.watch(dashboardRepositoryProvider),
    role,
  ),
);

class DashboardController extends StateNotifier<AsyncValue<DashboardModel?>> {
  DashboardController(this._repository, this._role)
      : super(const AsyncLoading()) {
    unawaited(load());
  }

  final DashboardRepository _repository;
  final UserRole _role;

  Future<void> load() async {
    state = const AsyncLoading();
    try {
      state = AsyncData(await _repository.load(_role));
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}
