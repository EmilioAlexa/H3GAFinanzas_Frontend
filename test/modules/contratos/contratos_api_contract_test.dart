import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/modules/auth/auth.dart';
import 'package:h3ga_finanzas/modules/contratos/models/servicio_model.dart';
import 'package:h3ga_finanzas/modules/contratos/repositories/contratos_repository.dart';

void main() {
  const id = '00000000-0000-4000-8000-000000000001';
  const contract = {
    'id': id,
    'cliente_id': id,
    'servicio_id': 72,
    'asesor_id': id,
    'folio': 'M40202600001',
    'fecha_contrato': '2026-11-20T00:00:00.000Z',
    'estado_contrato_id': 9,
    'creado_en': '2026-11-20T15:00:00.000Z',
    'clientes': {'nombre': 'Cliente', 'apellido_paterno': 'Prueba'},
    'servicios': {'id': 72, 'nombre': 'Modalidad 40'},
    'usuarios': {'nombre': 'Asesor'},
    'estados_contratos': {'nombre': 'Estado Test'},
  };
  late Dio dio;
  late ContratosRepository repository;
  late List<RequestOptions> requests;
  setUp(() {
    requests = [];
    dio = Dio();
    repository = ContratosRepository(demoMode: false, dio: dio);
    dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
      requests.add(request);
      Object data = contract;
      if (request.path == '/finanzas/contratos' && request.method == 'GET') {
        data = {
          'data': [contract],
          'pagination': {'totalPages': 2}
        };
      } else if (request.path == '/finanzas/catalogos/servicios') {
        data = {
          'data': [
            {'id': 72, 'nombre': 'Modalidad 40', 'descripcion': 'Real'}
          ],
          'pagination': {'totalPages': 1}
        };
      } else if (request.path == '/finanzas/catalogos/estados-contrato') {
        data = {
          'data': [
            {'id': 9, 'nombre': 'Estado Test'}
          ],
          'pagination': {'totalPages': 1}
        };
      } else if (request.path == '/finanzas/catalogos/servicios/72') {
        data = {'id': 72, 'nombre': 'Modalidad 40', 'descripcion': 'Real'};
      }
      handler.resolve(Response(requestOptions: request, data: data));
    }));
  });
  test('recorre páginas y conserva relaciones, folio y finanzas ausentes',
      () async {
    final contracts = (await repository.load(UserRole.asesor))!;
    expect(contracts, hasLength(2));
    expect(requests.map((e) => e.queryParameters['page']), [1, 2]);
    expect(contracts.first.clienteNombre, 'Cliente Prueba');
    expect(contracts.first.folio, 'M40202600001');
    expect(contracts.first.totalPagar, isNull);
    expect(contracts.first.saldoPendiente, isNull);
  });
  test('alta omite folio y asesor JWT; PATCH envía solo observaciones',
      () async {
    final original = await repository.detail(id, UserRole.asesor);
    final created = await repository.create(
        Map<String, dynamic>.from(original.toCreatePayload(isAdvisor: true)));
    expect(created.folio, 'M40202600001');
    final body = requests.last.data as Map<String, dynamic>;
    expect(body, isNot(contains('folio')));
    expect(body, isNot(contains('asesor_id')));
    await repository.updateObservations(id, null, UserRole.asesor);
    expect(requests.last.method, 'PATCH');
    expect(requests.last.data, {'observaciones': null});
  });
  test(
      'catálogos y detalle usan IDs reales, modalidades no dependen de fixtures',
      () async {
    final services = (await repository.loadServices())!;
    expect(services.single.id, 72);
    expect(services.single.clave, 'm40');
    expect((await repository.serviceDetail(72)).descripcionDemo, 'Real');
    expect((await repository.loadStates()).single.id, 9);
    expect(ServicioModel.routeKey('M40R', 88), 'm40-retroactiva');
    expect(ServicioModel.routeKey('APD', 91), 'apd');
  });
  test(
      'explicit financial conditions are sent and server monthly amount is read without totals',
      () async {
    dio.interceptors.clear();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (r, h) {
      requests.add(r);
      h.resolve(Response(requestOptions: r, data: {
        ...contract,
        'seguimiento_m40': {
          'monto_mensual': '1500.25',
          'salario_diario': '300.00',
          'cantidad_meses': 6,
          'fecha_fin': '2027-05-20'
        }
      }));
    }));
    final result = await repository.create({
      'cliente_id': id,
      'servicio_id': 72,
      'fecha_contrato': '2026-11-20',
      'estado_contrato_id': 9,
      'monto_mensual': '1500.25',
      'salario_diario': '300.00',
      'periodo_contrato': '6 meses'
    });
    expect((requests.single.data as Map<String, dynamic>)['monto_mensual'],
        '1500.25');
    expect(result.montoMensual, '1500.25');
    expect(result.salarioDiario, '300.00');
    expect(result.periodoContrato, '6 meses');
    expect(result.fechaTermino, DateTime(2027, 5, 20));
    expect(result.totalPagar, isNull);
    expect(result.saldoPendiente, isNull);
  });
  test('APD sends real sale type and reads the persisted catalog name',
      () async {
    dio.interceptors.clear();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (r, h) {
      requests.add(r);
      h.resolve(Response(requestOptions: r, data: {
        ...contract,
        if (r.method == 'GET') 'capacidades': {'documentos': true},
        'servicios': {'codigo_folio': 'APD', 'nombre': 'APD'},
        'seguimiento_apd': {
          'tipo_venta_id': 77,
          'tipos_venta': {'id': 77, 'nombre': 'Marketing'}
        }
      }));
    }));
    final result = await repository.create({
      'cliente_id': id,
      'servicio_id': 72,
      'fecha_contrato': '2026-11-20',
      'estado_contrato_id': 9,
      'tipo_venta_id': 77
    });
    expect((requests.single.data as Map<String, dynamic>)['tipo_venta_id'], 77);
    expect(result.tipoVentaNombre, 'Marketing');
    expect(result.esquemaPago, 'Pago \u00fanico');
    expect(result.montoMensual, isNull);
    expect(result.totalPagar, isNull);
    final detail = await repository.detail(id, UserRole.asesor);
    expect(detail.documentsReady, isTrue);
  });
  test('error HTTP se propaga sin recuperar fixtures', () async {
    dio.interceptors.clear();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
      handler.reject(DioException(
          requestOptions: request,
          response: Response(requestOptions: request, statusCode: 403)));
    }));
    await expectLater(
        repository.load(UserRole.asesor), throwsA(isA<DioException>()));
    expect(repository.loadSynchronously(UserRole.asesor), isEmpty);
  });
}
