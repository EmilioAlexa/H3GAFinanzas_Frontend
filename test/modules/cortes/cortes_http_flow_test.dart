import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/core/network/finanzas_api.dart';
import 'package:h3ga_finanzas/modules/cortes/controllers/cortes_controller.dart';
import 'package:h3ga_finanzas/modules/cortes/repositories/cortes_repository.dart';

Map<String, dynamic> cut([String state = 'Abierto']) => {
      'id': 'real-cut',
      'folio': 'CF-real',
      'fecha_inicio': '2026-11-13',
      'fecha_fin': '2026-11-20',
      'creado_en': '2026-11-13T12:00:00Z',
      'estados_corte': {'nombre': state},
      'detalle_corte': <dynamic>[],
      'resumen': {
        'total_ingresos': '125.00',
        'total_comisiones': '25.00',
        'cantidad_pagos': 0
      },
    };

void main() {
  test('detail and preparation share the UUID provider without reloading the list', () async {
    final requests = <String>[];
    final dio = Dio()..interceptors.add(InterceptorsWrapper(onRequest: (r,h) {
      requests.add(r.path);
      h.resolve(Response(requestOptions: r, data: r.path.endsWith('/historial') ? <dynamic>[] : cut()));
    }));
    final container = ProviderContainer(overrides: [
      cortesRepositoryProvider.overrideWith((ref) => CortesRepository(api: FinanzasApi(dio))),
    ]);
    addTearDown(container.dispose);
    final first = container.listen(corteDetailProvider('real-cut'), (_, __) {});
    final detail = await container.read(corteDetailProvider('real-cut').future);
    first.close();
    final second = container.listen(corteDetailProvider('real-cut'), (_, __) {});
    final preparation = await container.read(corteDetailProvider('real-cut').future);
    second.close();
    expect(detail.id, preparation.id);
    expect(requests, ['/finanzas/cortes/real-cut', '/finanzas/cortes/real-cut/historial']);
  });

  test(
      'one initial list GET, overlapping refreshes coalesced; mutations reuse POST result',
      () async {
    final requests = <RequestOptions>[];
    final gate = Completer<void>();
    final dio = Dio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (r, h) async {
        requests.add(r);
        if (r.method == 'GET') await gate.future;
        h.resolve(Response(
            requestOptions: r,
            data: r.method == 'GET'
                ? {
                    'data': [cut()],
                    'total': 1
                  }
                : cut(r.path.endsWith('cerrar') ? 'Cerrado' : 'Abierto')));
      }));
    final controller = CortesController(CortesRepository(api: FinanzasApi(dio)),
        demoMode: false);
    addTearDown(controller.dispose);
    final a = controller.load();
    final b = controller.load();
    gate.complete();
    await Future.wait([a, b]);
    expect(requests, hasLength(1));
    final created = await controller.createDemo(
        periodStart: DateTime(2026, 11, 13), actor: 'Admin');
    expect(created.id, 'real-cut');
    await controller.transitionDemo(
        id: created.id, action: 'generar', actor: 'Admin', comment: 'Generar');
    final closed = await controller.transitionDemo(
        id: created.id,
        action: 'cerrar',
        actor: 'Financiero',
        comment: 'Cerrar');
    expect(closed.id, 'real-cut');
    expect(closed.status, 'Cerrado');
    expect(requests.where((r) => r.method == 'GET'), hasLength(1));
    expect(requests.where((r) => r.method == 'POST'), hasLength(3));
    expect(controller.state.requireValue!.single.id, 'real-cut');
  });

  test('429 remains an error; manual retry before Retry-After sends no HTTP',
      () async {
    var count = 0;
    final dio = Dio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (r, h) {
        count++;
        h.reject(DioException(
            requestOptions: r,
            response: Response(
                requestOptions: r,
                statusCode: 429,
                headers: Headers.fromMap({
                  'retry-after': ['120']
                }))));
      }));
    final controller = CortesController(CortesRepository(api: FinanzasApi(dio)),
        demoMode: false);
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.state.hasError, isTrue);
    expect(
        controller.state.error.toString(), contains('Demasiadas solicitudes'));
    await controller.load();
    await controller.load();
    expect(count, 1);
    expect(controller.state.hasError, isTrue);
  });

  test('500 is not empty and no automatic retry occurs', () async {
    var count = 0;
    final dio = Dio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (r, h) {
        count++;
        h.reject(DioException(
            requestOptions: r,
            response: Response(requestOptions: r, statusCode: 500)));
      }));
    final controller = CortesController(CortesRepository(api: FinanzasApi(dio)),
        demoMode: false);
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.state.hasError, isTrue);
    expect(count, 1);
  });

  test('only a valid empty list produces empty state', () async {
    final dio = Dio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (r, h) {
        h.resolve(Response(
            requestOptions: r, data: {'data': <dynamic>[], 'total': 0}));
      }));
    final controller = CortesController(CortesRepository(api: FinanzasApi(dio)),
        demoMode: false);
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.state.requireValue, isEmpty);
  });

  test('failed detail refresh cannot lose a successful POST or resend it',
      () async {
    var posts = 0;
    final dio = Dio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (r, h) {
        if (r.method == 'POST') {
          posts++;
          h.resolve(Response(requestOptions: r, data: cut()));
        } else if (r.path == '/finanzas/cortes') {
          h.resolve(Response(
              requestOptions: r, data: {'data': <dynamic>[], 'total': 0}));
        } else {
          h.reject(DioException(
              requestOptions: r,
              response: Response(requestOptions: r, statusCode: 500)));
        }
      }));
    final repo = CortesRepository(api: FinanzasApi(dio));
    final controller = CortesController(repo, demoMode: false);
    addTearDown(controller.dispose);
    await controller.load();
    final created = await controller.createDemo(
        periodStart: DateTime(2026, 11, 13), actor: 'Admin');
    await expectLater(repo.loadDetail(created.id), throwsStateError);
    expect(controller.state.requireValue!.single.id, created.id);
    expect(posts, 1);
  });
}
