import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../app/config/env.dart';
import '../storage/token_storage.dart';

/// Marks public authentication requests that must not use or invalidate a JWT.
const publicLoginRequestKey = 'publicLoginRequest';

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => const TokenStorage(FlutterSecureStorage()),
);
final unauthorizedCallbackProvider = Provider<void Function()>((ref) => () {});
final apiClientProvider = Provider<Dio>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return createApiClient(
    baseUrl: AppEnv.apiBaseUrl,
    storage: storage,
    onUnauthorized: ref.read(unauthorizedCallbackProvider),
  );
});

Dio createApiClient({
  required String baseUrl,
  required TokenStorage storage,
  required void Function() onUnauthorized,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      headers: {'Accept': 'application/json'},
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (options.extra[publicLoginRequestKey] == true) {
          handler.next(options);
          return;
        }
        final token = await storage.readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 &&
            error.requestOptions.extra[publicLoginRequestKey] != true) {
          await storage.clear();
          onUnauthorized();
        }
        handler.next(error);
      },
    ),
  );
  return dio;
}
