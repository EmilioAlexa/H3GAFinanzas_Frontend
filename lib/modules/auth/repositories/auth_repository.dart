import 'package:dio/dio.dart';
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
    );
    final body = response.data!;
    final token = body['access_token']! as String;
    await _storage.saveToken(token);
    return currentUser();
  }

  Future<AuthSessionModel> currentUser() async {
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
