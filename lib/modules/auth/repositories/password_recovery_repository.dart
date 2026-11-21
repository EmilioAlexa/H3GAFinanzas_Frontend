import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

final passwordRecoveryRepositoryProvider =
    Provider((ref) => PasswordRecoveryRepository(ref.watch(apiClientProvider)));

class PasswordRecoveryRepository {
  PasswordRecoveryRepository(this.dio);
  final Dio dio;
  Options get _public => Options(extra: {publicLoginRequestKey: true});
  Future<void> request(String email) async {
    await dio.post<dynamic>('/auth/forgot-password',
        data: {'correo_electronico': email}, options: _public);
  }

  Future<void> reset(String email, String code, String password) async {
    await dio.post<dynamic>('/auth/reset-password',
        data: {
          'correo_electronico': email,
          'codigo': code,
          'nueva_contrasena': password
        },
        options: _public);
  }
}
