import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/env.dart';
import '../../../core/network/finanzas_api.dart';
import '../../auth/auth.dart';
import '../models/report_data_model.dart';
import '../models/report_filters_model.dart';
import '../models/report_type_model.dart';
import '../repositories/reportes_repository.dart';
final reportesRepositoryProvider = Provider<ReportesRepository>((ref) =>
    ReportesRepository(
        demoMode: AppEnv.demoMode, api: ref.watch(finanzasApiProvider)));

final reportesControllerProvider =
    StateNotifierProvider<ReportesController, ReportFiltersModel>(
  (ref) => ReportesController(demoMode: AppEnv.demoMode),
);

class ReportesController extends StateNotifier<ReportFiltersModel> {
  ReportesController({required this.demoMode})
      : super(ReportFiltersModel(
          from: demoMode
              ? DateTime(2025, 4, 4)
              : DateTime(DateTime.now().year, DateTime.now().month, 1),
          to: demoMode ? DateTime(2025, 5, 23) : DateTime.now(),
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
  void setService(String value) =>
      state = state.copyWith(service: value, applied: false);
  void setSaleType(String value) =>
      state = state.copyWith(saleType: value, applied: false);
  void setPaymentMethod(String value) =>
      state = state.copyWith(paymentMethod: value, applied: false);

  void apply() => state = state.copyWith(applied: true);

  void clear() => state = ReportFiltersModel(
        from: demoMode
            ? DateTime(2025, 4, 4)
            : DateTime(DateTime.now().year, DateTime.now().month, 1),
        to: demoMode ? DateTime(2025, 5, 23) : DateTime.now(),
      );
}

final reportDataProvider =
    FutureProvider.family<ReportDataModel, ReportType>((ref, type) {
  ref.watch(authControllerProvider);
  final filters = ref.watch(appliedReportFiltersProvider);
  return ref.watch(reportesRepositoryProvider).load(type, filters);
});
final appliedReportFiltersProvider = StateProvider<ReportFiltersModel>(
    (ref) => ref.read(reportesControllerProvider));