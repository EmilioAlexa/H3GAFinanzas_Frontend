import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/auth_session_model.dart';
import '../models/user_role_model.dart';

class AuthRepository {
  const AuthRepository(this._dio, this._storage);
  final Dio _dio;
  final TokenStorage _storage;

  Future<AuthSessionModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/auth/login',
      data: {'correo_electronico': email, 'contrasena': password},
      options: Options(extra: {publicLoginRequestKey: true}),
    );
    final body = response.data!;
    final token = body['access_token']! as String;
    await _storage.saveToken(token);
    try {
      return await currentUser();
    } catch (_) {
      await _storage.clear();
      rethrow;
    }
  }

  Future<AuthSessionModel> currentUser() async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) {
      throw const FormatException('No hay una sesión guardada.');
    }
    final response = await _dio.get<Map<String, Object?>>('/auth/me');
    final body = response.data!;
    final roles = body['roles']! as Map<String, Object?>;
    final role = UserRoleName.parse(roles['nombre'] as String?);
    if (role == null) {
      throw const FormatException(
        'El rol recibido por la API no está soportado.',
      );
    }
    return AuthSessionModel(
      id: body['id']! as String,
      name:
          '${body['nombre']! as String} ${body['apellido_paterno']! as String}',
      email: body['correo_electronico']! as String,
      role: role,
    );
  }

  Future<void> logout() => _storage.clear();
}
