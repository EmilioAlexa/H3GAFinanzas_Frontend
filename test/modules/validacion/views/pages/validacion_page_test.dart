import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/app/theme/app_theme.dart';
import 'package:h3ga_finanzas/core/storage/token_storage.dart';
import 'package:h3ga_finanzas/modules/auth/auth.dart';
import 'package:h3ga_finanzas/modules/pagos/pagos.dart';
import 'package:h3ga_finanzas/modules/validacion/validacion.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  await initializeDateFormatting('es_MX');

  testWidgets('validation queue adapts on compact and expanded screens',
      (tester) async {
    for (final size in [const Size(390, 844), const Size(1280, 900)]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider
                .overrideWith((ref) => _ValidationAuthController()),
            pagosControllerProvider.overrideWith((ref, role) =>
                PagosController(PagosRepository(), role, demoMode: true)),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: ValidacionPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bandeja de validación'), findsOneWidget);
      expect(find.text('Carlos Mendoza Ruiz'), findsWidgets);
      expect(tester.takeException(), isNull, reason: 'viewport $size');
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

class _ValidationAuthController extends AuthController {
  _ValidationAuthController()
      : super(
          AuthRepository(Dio(), const TokenStorage(FlutterSecureStorage())),
          demoMode: true,
          demoRole: UserRole.administradorFinanciero,
        ) {
    state = const AsyncData(
      AuthSessionModel(
        id: 'test-finance-admin',
        name: 'Admin financiero prueba',
        email: 'finance-admin@example.test',
        role: UserRole.administradorFinanciero,
      ),
    );
  }
}
