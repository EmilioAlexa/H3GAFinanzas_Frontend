import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/core/network/api_error_model.dart';
import 'package:h3ga_finanzas/modules/clientes/models/cliente_model.dart';
import 'package:h3ga_finanzas/modules/clientes/repositories/clientes_repository.dart';

void main() {
  test('fechas civiles no cambian de día y fechas omitidas no se envían', () {
    final client = ClienteModel.fromJson({
      'id': 'test',
      'nombre': 'Ana',
      'apellido_paterno': 'Prueba',
      'fecha_ingreso': '2026-01-02T00:00:00.000Z',
      'fecha_nacimiento': '1990-02-28',
    });
    expect(client.fechaIngreso?.day, 2);
    expect(client.fechaNacimiento?.day, 28);
    expect(client.toApiPayload().containsKey('fecha_ingreso'), false);
    expect(client.toApiPayload()['fecha_nacimiento'], '1990-02-28');
    const withoutDates =
        ClienteModel(id: 'test', nombre: 'Ana', apellidoPaterno: 'Prueba');
    expect(withoutDates.toApiPayload().containsKey('fecha_nacimiento'), false);
    final administrative = ClienteModel.fromJson({
      'id': 'test-2',
      'nombre': 'Ana',
      'apellido_paterno': 'Prueba',
      'domicilio': 'Calle Uno',
      'referido_por': 'Maria Referidora',
      'observaciones_generales': 'Dato empresarial',
    });
    expect(administrative.direccion, 'Calle Uno');
    expect(administrative.referidoPor, 'Maria Referidora');
    expect(administrative.observaciones, 'Dato empresarial');
    expect(administrative.toApiPayload(), containsPair('domicilio', 'Calle Uno'));
    expect(administrative.toApiPayload(),
        containsPair('referido_por', 'Maria Referidora'));
    expect(administrative.toApiPayload(),
        containsPair('observaciones_generales', 'Dato empresarial'));
  });
  test('errores HTTP muestran mensajes seguros', () {
    final request = RequestOptions(path: '/clientes/id');
    for (final status in [400, 403, 404, 409, 500]) {
      final error = DioException(
          requestOptions: request,
          response: Response(
              requestOptions: request,
              statusCode: status,
              data: {'message': 'private SQL'}));
      final mapped = ApiErrorModel.fromObject(error);
      expect(mapped.statusCode, status);
      expect(mapped.message, isNot(contains('private SQL')));
    }
  });
  const id = '00000000-0000-4000-8000-000000000001';
  const client = {
    'id': id,
    'nombre': 'Ana',
    'apellido_paterno': 'Prueba',
    'pausado': false
  };
  late Dio dio;
  late ClientesRepository repository;
  late List<RequestOptions> requests;
  var conflict = false;
  setUp(() {
    requests = [];
    conflict = false;
    dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      requests.add(options);
      if (options.method == 'DELETE' && conflict) {
        handler.reject(DioException(
            requestOptions: options,
            response: Response(
                requestOptions: options,
                statusCode: 409,
                data: {'codigo': 'CLIENTE_CON_DEPENDENCIAS'}),
            type: DioExceptionType.badResponse));
        return;
      }
      Object? data = client;
      if (options.path == '/clientes' && options.method == 'GET') {
        data = {
          'data': [client],
          'pagination': {'page': 2, 'total': 21, 'totalPages': 2}
        };
      } else if (options.path.endsWith('/dependencias')) {
        data = {'apto_para_eliminacion': true, 'bloqueantes': <Object>[]};
      } else if (options.path.endsWith('/historial')) {
        data = <Object>[];
      } else if (options.method == 'DELETE') {
        data = null;
      }
      handler.resolve(Response(
          requestOptions: options,
          statusCode: options.method == 'DELETE' ? 204 : 200,
          data: data));
    }));
    repository = ClientesRepository(demoMode: false, dio: dio);
  });

  test('consulta paginada, detalle y escritura respetan DTO', () async {
    final page = await repository.page(page: 2, query: ' Ana ');
    expect(page.total, 21);
    expect(page.data.single.pausado, false);
    expect(
        requests.first.queryParameters, {'page': 2, 'limit': 20, 'q': 'Ana'});
    final detail = await repository.detail(id);
    await repository.create(detail, referidorId: id);
    expect((requests.last.data as Map).keys.toSet(), {
      'nombre',
      'apellido_paterno',
      'apellido_materno',
      'telefono',
      'correo_electronico',
      'curp',
      'rfc',
      'domicilio',
      'referido_por',
      'observaciones_generales',
      'referido_por_cliente_id'
    });
    await repository.update(detail);
    expect((requests.last.data as Map).containsKey('referido_por_cliente_id'),
        false);
  });

  test('pausa, referidor e historial usan las rutas y cuerpos reales',
      () async {
    await repository.setPaused(id, true);
    expect(requests.last.data, {'pausado': true});
    await repository.setReferidor(id, null, 'Cambio solicitado');
    expect(requests.last.data,
        {'referidor_cliente_id': null, 'motivo': 'Cambio solicitado'});
    expect(await repository.referidorHistory(id), isEmpty);
    expect(requests.last.path, '/clientes/$id/referidor/historial');
  });

  test('dependencias y DELETE 204 y 409 se propagan', () async {
    expect((await repository.dependencies(id))['apto_para_eliminacion'], true);
    await repository.delete(id);
    conflict = true;
    await expectLater(
        repository.delete(id),
        throwsA(isA<DioException>()
            .having((e) => e.response?.statusCode, 'status', 409)));
  });
}
