import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/core/network/finanzas_api.dart';
import 'package:h3ga_finanzas/modules/auth/auth.dart';
import 'package:h3ga_finanzas/modules/dashboard/repositories/dashboard_repository.dart';
import 'package:h3ga_finanzas/modules/reportes/models/report_filters_model.dart';
import 'package:h3ga_finanzas/modules/reportes/models/report_type_model.dart';
import 'package:h3ga_finanzas/modules/reportes/repositories/reportes_repository.dart';

void main() {
  test('real dashboard uses a single request and preserves empty server data',
      () async {
    final dio = Dio();
    var calls = 0;
    dio.interceptors.add(InterceptorsWrapper(onRequest: (r, h) {
      calls++;
      expect(r.path, '/finanzas/dashboard');
      h.resolve(Response(requestOptions: r, data: {
        'alcance': 'asesor',
        'indicadores': {
          'ingresos_periodo': '0.00',
          'por_cobrar_conocido': '386200.25',
          'por_cobrar_completo': true,
          'comisiones_generadas': '42.35',
          'comisiones_pendientes_dispersion': '12.00'
        },
        'ingresos_por_servicio': <String, dynamic>{},
        'periodo': <String, dynamic>{}
      }));
    }));
    final result =
        await DashboardRepository(demoMode: false, api: FinanzasApi(dio))
            .load(UserRole.asesor);
    expect(calls, 1);
    expect(result!.isAdvisor, true);
    expect(result.metrics.map((metric) => metric.label), [
      'Ingresos del periodo',
      'Por cobrar',
      'Pendientes de validación',
      'Contratos activos',
      'Comisiones generadas',
    ]);
    expect(result.metrics[1].value, r'$386200.25');
    expect(
        result.metrics
            .where((m) => m.label == 'Comisiones generadas')
            .single
            .value,
        r'$42.35');
    expect(result.collections, isEmpty);
    expect(result.totalValidated.toString(), '0');
  });
  test('reports preserve backend totals and send filters; errors propagate',
      () async {
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (r, h) {
      expect(r.queryParameters['fecha_desde'], '2026-11-01');
      expect(r.queryParameters['servicio'], 'APD');
      h.resolve(Response(requestOptions: r, data: {
        'datos': <dynamic>[],
        'resumen': {'total': '12.35'},
        'comparacion': null
      }));
    }));
    final repository =
        ReportesRepository(demoMode: false, api: FinanzasApi(dio));
    final filters = ReportFiltersModel(
        from: DateTime(2026, 11), to: DateTime(2026, 11, 20), service: 'APD');
    final result = await repository.load(ReportType.ingresos, filters);
    expect(result.rows, isEmpty);
    expect(result.total.toString(), '12.35');
    expect(result.serverCalculated, true);
    dio.interceptors.clear();
    dio.interceptors.add(InterceptorsWrapper(
        onRequest: (r, h) => h.reject(DioException(
            requestOptions: r,
            response: Response(requestOptions: r, statusCode: 429)))));
    await expectLater(repository.load(ReportType.ingresos, filters),
        throwsA(isA<DioException>()));
  });
}
