import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/core/network/finanzas_api.dart';

void main() {
  test('configuration omits any invented receiver and keeps Decimal text',
      () async {
    final dio = Dio();
    RequestOptions? captured;
    dio.interceptors.add(InterceptorsWrapper(onRequest: (r, h) {
      captured = r;
      h.resolve(Response(requestOptions: r, data: []));
    }));
    await FinanzasApi(dio).saveConfiguration('contract', [
      {'concepto_id': 4, 'valor': '12.5'},
    ]);
    expect(captured!.method, 'PUT');
    expect(captured!.data, {
      'configuracion': [
        {'concepto_id': 4, 'valor': '12.5'}
      ]
    });
  });
  test('payroll generation requires an explicit existing state identifier',
      () async {
    final dio = Dio();
    RequestOptions? captured;
    dio.interceptors.add(InterceptorsWrapper(onRequest: (r, h) {
      captured = r;
      h.resolve(Response(requestOptions: r, data: {'id': 'payroll'}));
    }));
    final result = await FinanzasApi(dio).generatePayroll('cut', 9, 'Aprobado');
    expect(result['id'], 'payroll');
    expect(captured!.path, '/finanzas/cortes/cut/prenomina/generar');
    expect(captured!.data['estado_id'], 9);
  });

  test('pagination preserves authorized filters and collects every page',
      () async {
    final dio = Dio();
    final requests = <RequestOptions>[];
    dio.interceptors.add(InterceptorsWrapper(onRequest: (r, h) {
      requests.add(r);
      h.resolve(Response(requestOptions: r, data: {
        'data': [
          {'id': 'commission-${r.queryParameters['page']}'}
        ],
        'total': 2,
      }));
    }));
    final rows = await FinanzasApi(dio)
        .list('/finanzas/comisiones', filters: {'contrato_id': 'contract-id'});
    expect(rows.length, 2);
    expect(requests.map((r) => r.queryParameters['page']), [1, 2]);
    expect(
        requests
            .every((r) => r.queryParameters['contrato_id'] == 'contract-id'),
        isTrue);
  });
  test('server failure propagates instead of returning demo or empty data',
      () async {
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (r, h) {
      h.reject(DioException(
          requestOptions: r,
          response: Response(requestOptions: r, statusCode: 403)));
    }));
    await expectLater(FinanzasApi(dio).list('/finanzas/comisiones'),
        throwsA(isA<DioException>()));
  });
  test('cut actions use the audited route and preserve the comment', () async {
    final dio = Dio();
    RequestOptions? request;
    dio.interceptors.add(InterceptorsWrapper(onRequest: (r, h) {
      request = r;
      h.resolve(Response(requestOptions: r, data: {'id': 'cut'}));
    }));
    await FinanzasApi(dio).cutAction('cut', 'cancelar', 'Motivo autorizado');
    expect(request!.path, '/finanzas/cortes/cut/cancelar');
    expect(request!.data, {'comentario': 'Motivo autorizado'});
    await expectLater(
        FinanzasApi(dio).cutAction('cut', 'invalid', ''), throwsArgumentError);
  });
}
