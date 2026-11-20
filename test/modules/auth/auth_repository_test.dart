import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/core/network/api_client.dart';
import 'package:h3ga_finanzas/core/network/api_error_model.dart';
import 'package:h3ga_finanzas/core/storage/token_storage.dart';
import 'package:h3ga_finanzas/modules/auth/controllers/auth_controller.dart';
import 'package:h3ga_finanzas/modules/auth/models/user_role_model.dart';
import 'package:h3ga_finanzas/modules/auth/repositories/auth_repository.dart';

class MemoryTokenStorage extends TokenStorage {
  MemoryTokenStorage() : super(const FlutterSecureStorage());

  String? token;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> saveToken(String value) async => token = value;

  @override
  Future<void> clear() async => token = null;
}

void main() {
  late HttpServer server;
  late MemoryTokenStorage storage;
  late Dio client;
  late AuthRepository repository;
  late List<String> paths;
  late int unauthorizedCallbacks;
  late List<String?> loginAuthorization;
  var expireSession = false;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    storage = MemoryTokenStorage();
    paths = [];
    unauthorizedCallbacks = 0;
    loginAuthorization = [];
    expireSession = false;
    server.listen((request) async {
      paths.add(request.uri.path);
      request.response.headers.contentType = ContentType.json;
      if (request.uri.path == '/api/auth/login') {
        loginAuthorization
            .add(request.headers.value(HttpHeaders.authorizationHeader));
        final body = jsonDecode(await utf8.decoder.bind(request).join())
            as Map<String, dynamic>;
        expect(body.keys.toSet(), {'correo_electronico', 'contrasena'});
        if (body['correo_electronico'] != 'admin@example.test' ||
            body['contrasena'] != 'clave-segura') {
          request.response.statusCode = 401;
          request.response
              .write(jsonEncode({'message': 'Credenciales inválidas'}));
        } else {
          request.response.statusCode = 201;
          request.response
              .write(jsonEncode({'access_token': 'token-de-prueba'}));
        }
      } else if (request.uri.path == '/api/auth/me') {
        if (expireSession ||
            request.headers.value(HttpHeaders.authorizationHeader) !=
                'Bearer token-de-prueba') {
          request.response.statusCode = 401;
          request.response.write(jsonEncode({'message': 'No autorizado'}));
        } else {
          request.response.write(jsonEncode({
            'id': '00000000-0000-4000-8000-000000000001',
            'nombre': 'Persona',
            'apellido_paterno': 'Prueba',
            'correo_electronico': 'admin@example.test',
            'roles': {'nombre': 'administrador'},
          }));
        }
      } else if (request.uri.path == '/api/protegido') {
        request.response.statusCode = 403;
        request.response.write(jsonEncode({'message': 'Prohibido'}));
      } else {
        request.response.statusCode = 404;
      }
      await request.response.close();
    });
    client = createApiClient(
      baseUrl: 'http://127.0.0.1:${server.port}/api',
      storage: storage,
      onUnauthorized: () => unauthorizedCallbacks++,
    );
    repository = AuthRepository(client, storage);
  });

  tearDown(() async {
    client.close(force: true);
    await server.close(force: true);
  });

  test('login, JWT, /me, restauración y logout usan /api una sola vez',
      () async {
    final session = await repository.login(
      email: 'admin@example.test',
      password: 'clave-segura',
    );
    expect(session.role, UserRole.administrador);
    expect(storage.token, isNotNull);
    expect(
        (await AuthRepository(client, storage).currentUser()).id, session.id);
    expect(paths, ['/api/auth/login', '/api/auth/me', '/api/auth/me']);
    await repository.logout();
    expect(storage.token, isNull);
    await expectLater(
        repository.currentUser(), throwsA(isA<FormatException>()));
    expect(paths.length, 3);
    expect(unauthorizedCallbacks, 0);
  });

  test('JWT vencido produce 401, limpia almacenamiento y avisa', () async {
    storage.token = 'token-de-prueba';
    expireSession = true;
    try {
      await repository.currentUser();
      fail('Se esperaba un 401');
    } on DioException catch (error) {
      expect(ApiErrorModel.fromObject(error).message,
          'Tu sesión expiró. Inicia sesión nuevamente.');
    }
    expect(storage.token, isNull);
    expect(unauthorizedCallbacks, 1);
  });

  test('el controlador restaura la sesión y cierra sesión', () async {
    storage.token = 'token-de-prueba';
    final controller = AuthController(repository,
        demoMode: false, demoRole: UserRole.administrador);
    await controller.restoreSession();
    expect(controller.state.asData?.value?.role, UserRole.administrador);
    await controller.logout();
    expect(controller.state.asData?.value, isNull);
    expect(storage.token, isNull);
    controller.dispose();
  });

  test('403 informa falta de permiso sin cerrar la sesión', () async {
    storage.token = 'token-de-prueba';
    try {
      await client.get<void>('/protegido');
      fail('Se esperaba un 403');
    } on DioException catch (error) {
      expect(error.response?.statusCode, 403);
      expect(ApiErrorModel.fromObject(error).message,
          'No tienes permiso para realizar esta acción.');
    }
    expect(storage.token, 'token-de-prueba');
    expect(unauthorizedCallbacks, 0);
  });

  test('login rechazado no invalida una sesión previa', () async {
    storage.token = 'sesion-previa';
    try {
      await repository.login(
          email: 'admin@example.test', password: 'incorrecta');
      fail('Se esperaba un 401');
    } on DioException catch (error) {
      expect(error.response?.statusCode, 401);
      expect(ApiErrorModel.fromObject(error).message,
          'Correo o contraseña incorrectos.');
    }
    expect(loginAuthorization, [null]);
    expect(storage.token, 'sesion-previa');
    expect(unauthorizedCallbacks, 0);
  });
}
