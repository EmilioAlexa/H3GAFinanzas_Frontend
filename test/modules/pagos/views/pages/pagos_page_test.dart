import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/app/theme/app_theme.dart';
import 'package:h3ga_finanzas/core/storage/token_storage.dart';
import 'package:h3ga_finanzas/modules/auth/auth.dart';
import 'package:h3ga_finanzas/modules/pagos/pagos.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  await initializeDateFormatting('es_MX');
  testWidgets(
      'payment list renders demo records on compact and expanded widths',
      (tester) async {
    for (final size in [
      const Size(390, 844),
      const Size(768, 1024),
      const Size(1280, 900),
    ]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith((ref) => _TestAuthController()),
            pagosControllerProvider.overrideWith((ref, role) =>
                PagosController(PagosRepository(), role, demoMode: true)),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: PagosPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pagos'), findsOneWidget);
      expect(find.text('PG-2025-0428'), findsWidgets);
      expect(tester.takeException(), isNull, reason: 'viewport $size');
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

class _TestAuthController extends AuthController {
  _TestAuthController()
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
