import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/core/network/api_client.dart';
import 'package:h3ga_finanzas/modules/auth/repositories/password_recovery_repository.dart';

void main() {
  test('public recovery sends exact DTO and propagates reset rejection',
      () async {
    final dio = Dio();
    final requests = <RequestOptions>[];
    dio.interceptors.add(InterceptorsWrapper(onRequest: (r, h) {
      requests.add(r);
      if (r.path.endsWith('reset-password')) {
        h.reject(DioException(
            requestOptions: r,
            response: Response(requestOptions: r, statusCode: 400)));
      } else {
        h.resolve(Response(
            requestOptions: r, data: {'message': 'Solicitud procesada'}));
      }
    }));
    final repository = PasswordRecoveryRepository(dio);
    await repository.request('test@example.test');
    expect(requests.single.data, {'correo_electronico': 'test@example.test'});
    expect(requests.single.extra[publicLoginRequestKey], true);
    await expectLater(
        repository.reset('test@example.test', '123456', 'example-secret'),
        throwsA(isA<DioException>()));
    expect(requests.last.data, {
      'correo_electronico': 'test@example.test',
      'codigo': '123456',
      'nueva_contrasena': 'example-secret'
    });
    expect(requests.last.extra[publicLoginRequestKey], true);
  });
}
