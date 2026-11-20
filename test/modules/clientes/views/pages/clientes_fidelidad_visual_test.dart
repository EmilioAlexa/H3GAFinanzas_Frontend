import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/app/theme/app_theme.dart';
import 'package:h3ga_finanzas/core/storage/token_storage.dart';
import 'package:h3ga_finanzas/modules/auth/auth.dart' as current_auth;
import 'package:h3ga_finanzas/modules/clientes/clientes.dart' as current_clients;
import '../../../../../docs/frontend_Diseño_Original/core/storage/token_storage.dart' as original_storage;
import '../../../../../docs/frontend_Diseño_Original/modules/auth/auth.dart' as original_auth;
import '../../../../../docs/frontend_Diseño_Original/modules/clientes/clientes.dart' as original_clients;

class OriginalAdvisor extends original_auth.AuthController {
  OriginalAdvisor() : super(original_auth.AuthRepository(Dio(), const original_storage.TokenStorage(FlutterSecureStorage())), demoMode: true, demoRole: original_auth.UserRole.asesor) {
    state = const AsyncData(original_auth.AuthSessionModel(id: 'test-advisor', name: 'Asesor Prueba', email: 'asesor@example.test', role: original_auth.UserRole.asesor));
  }
}

class CurrentAdvisor extends current_auth.AuthController {
  CurrentAdvisor() : super(current_auth.AuthRepository(Dio(), const TokenStorage(FlutterSecureStorage())), demoMode: true, demoRole: current_auth.UserRole.asesor) {
    state = const AsyncData(current_auth.AuthSessionModel(id: 'test-advisor', name: 'Asesor Prueba', email: 'asesor@example.test', role: current_auth.UserRole.asesor));
  }
}

Dio simulatedApi() {
  final dio = Dio();
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
    handler.resolve(Response(requestOptions: options, data: {
      'data': <Object>[],
      'pagination': {'page': 1, 'limit': 20, 'total': 0, 'totalPages': 0},
    }));
  }));
  return dio;
}

void main() {
  for (final entry in <String, Size>{'movil': const Size(390, 844), 'web': const Size(1280, 900)}.entries) {
    for (final original in [true, false]) {
      testWidgets('${original ? 'original' : 'integrado'} ${entry.key}', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = entry.value;
        await tester.pumpWidget(original
            ? ProviderScope(overrides: [
                original_auth.authControllerProvider.overrideWith((ref) => OriginalAdvisor()),
                original_clients.clientesRepositoryProvider.overrideWith((ref) => original_clients.ClientesRepository(demoMode: true)),
              ], child: MaterialApp(theme: AppTheme.light, home: const Scaffold(body: original_clients.ClientesPage())))
            : ProviderScope(overrides: [
                current_auth.authControllerProvider.overrideWith((ref) => CurrentAdvisor()),
                current_clients.clientesRepositoryProvider.overrideWith((ref) => current_clients.ClientesRepository(demoMode: false, dio: simulatedApi())),
              ], child: MaterialApp(theme: AppTheme.light, home: const Scaffold(body: current_clients.ClientesPage()))));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Registrar cliente'));
        await tester.pumpAndSettle();
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/clientes_${original ? 'original' : 'integrado'}_${entry.key}.png'));
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }, skip: !const bool.fromEnvironment('DEMO_MODE'));
    }
  }
}
