import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/env.dart';
import '../models/report_filters_model.dart';
import '../repositories/reportes_repository.dart';

final reportesRepositoryProvider = Provider<ReportesRepository>(
    (ref) => const ReportesRepository(demoMode: AppEnv.demoMode));

final reportesControllerProvider =
    StateNotifierProvider<ReportesController, ReportFiltersModel>(
  (ref) => ReportesController(demoMode: AppEnv.demoMode),
);

class ReportesController extends StateNotifier<ReportFiltersModel> {
  ReportesController({required this.demoMode})
      : super(ReportFiltersModel(
          from: DateTime(2025, 4, 4),
          to: DateTime(2025, 5, 23),
        ));

  final bool demoMode;

  void setFrom(DateTime value) =>
      state = state.copyWith(from: value, applied: false);
  void setTo(DateTime value) =>
      state = state.copyWith(to: value, applied: false);
  void setGranularity(String value) =>
      state = state.copyWith(granularity: value, applied: false);
  void setCompare(bool value) =>
      state = state.copyWith(compare: value, applied: false);
  void setSaleType(String value) =>
      state = state.copyWith(saleType: value, applied: false);
  void setPaymentMethod(String value) =>
      state = state.copyWith(paymentMethod: value, applied: false);

  void apply() => state = state.copyWith(applied: true);

  void clear() => state = ReportFiltersModel(
        from: DateTime(2025, 4, 4),
        to: DateTime(2025, 5, 23),
      );
}
