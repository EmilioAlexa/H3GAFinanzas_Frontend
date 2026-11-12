import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/app/theme/app_theme.dart';
import 'package:h3ga_finanzas/core/storage/token_storage.dart';
import 'package:h3ga_finanzas/modules/auth/auth.dart';
import 'package:h3ga_finanzas/modules/clientes/clientes.dart';

void main() {
  testWidgets('client list adapts without overflow on compact and expanded',
      (tester) async {
    for (final size in [const Size(390, 844), const Size(1280, 900)]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(
              (ref) => _ClientesAuthController(),
            ),
            clientesRepositoryProvider.overrideWith(
              (ref) => ClientesRepository(demoMode: true),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: ClientesPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Clientes'), findsOneWidget);
      expect(find.text('Elena Robles Vargas'), findsWidgets);
      expect(find.text('ROVE680214MDFBLN08'), findsNothing);
      expect(tester.takeException(), isNull, reason: 'viewport $size');
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('search filters by supported name fields', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => _ClientesAuthController(),
          ),
          clientesRepositoryProvider.overrideWith(
            (ref) => ClientesRepository(demoMode: true),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: ClientesPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('clientes-search')), 'Elena');
    await tester.pumpAndSettle();

    expect(find.text('Elena Robles Vargas'), findsOneWidget);
    expect(find.text('Carlos Mendoza Ruiz'), findsNothing);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

class _ClientesAuthController extends AuthController {
  _ClientesAuthController()
      : super(
          AuthRepository(Dio(), const TokenStorage(FlutterSecureStorage())),
          demoMode: true,
          demoRole: UserRole.administrador,
        ) {
    state = const AsyncData(
      AuthSessionModel(
        id: 'test-admin',
        name: 'Admin de prueba',
        email: 'admin@example.test',
        role: UserRole.administrador,
      ),
    );
  }
}
