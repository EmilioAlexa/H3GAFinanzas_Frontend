import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/modules/auth/models/user_role_model.dart';
import 'package:h3ga_finanzas/modules/busqueda/controllers/global_search_controller.dart';
import 'package:h3ga_finanzas/modules/busqueda/models/global_search_hit_model.dart';
import 'package:h3ga_finanzas/modules/busqueda/repositories/global_search_repository.dart';

class ControlledSearch extends GlobalSearchRepository {
  ControlledSearch() : super(dio: Dio(), demoMode: false);
  final calls = <String, Completer<List<GlobalSearchHitModel>>>{};
  @override
  Future<List<GlobalSearchHitModel>> search(String query, UserRole role) =>
      (calls[query] = Completer<List<GlobalSearchHitModel>>()).future;
}

void main() {
  test('descarta una búsqueda que terminó después de una consulta nueva', () async {
    final repo = ControlledSearch();
    final controller = GlobalSearchController(repo, UserRole.asesor);
    final first = controller.searchNow('primera');
    final second = controller.searchNow('segunda');
    repo.calls['segunda']!.complete([]);
    await second;
    repo.calls['primera']!.complete([]);
    expect(await first, isEmpty);
    controller.dispose();
  });
  test('consulta rutas paginadas con filtros disponibles', () async {
    final paths = <String>[];
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api'));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      paths.add(options.path);
      expect(options.queryParameters['q'], 'Ana');
      expect(options.queryParameters['page'], 1);
      handler.resolve(Response(requestOptions: options, data: {'data': <Object>[]}));
    }));
    expect(await GlobalSearchRepository(dio: dio, demoMode: false).search('Ana', UserRole.asesor), isEmpty);
    expect(paths, hasLength(3));
    expect(paths.any((path) => path.endsWith('/clientes')), true);
    expect(paths.any((path) => path.endsWith('/finanzas/contratos')), true);
    expect(paths.any((path) => path.endsWith('/finanzas/pagos')), true);
  });
}
