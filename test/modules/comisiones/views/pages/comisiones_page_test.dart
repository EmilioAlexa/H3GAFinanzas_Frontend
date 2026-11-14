import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/app/theme/app_theme.dart';
import 'package:h3ga_finanzas/core/storage/token_storage.dart';
import 'package:h3ga_finanzas/modules/auth/auth.dart';
import 'package:h3ga_finanzas/modules/comisiones/controllers/comisiones_controller.dart';
import 'package:h3ga_finanzas/modules/comisiones/repositories/comisiones_repository.dart';
import 'package:h3ga_finanzas/modules/comisiones/views/pages/comisiones_page.dart';

void main() {
  testWidgets('commission list has no layout overflow at all three widths',
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
            authControllerProvider
                .overrideWith((ref) => _AdminAuthController()),
            comisionesControllerProvider.overrideWith((ref, role) =>
                ComisionesController(ComisionesRepository(), role,
                    demoMode: true)),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: ComisionesPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Comisiones por destino'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'viewport $size');
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

class _AdminAuthController extends AuthController {
  _AdminAuthController()
      : super(
          AuthRepository(Dio(), const TokenStorage(FlutterSecureStorage())),
          demoMode: true,
          demoRole: UserRole.administrador,
        ) {
    state = const AsyncData(
      AuthSessionModel(
        id: 'a13-admin',
        name: 'Administración de prueba',
        email: 'admin@example.test',
        role: UserRole.administrador,
      ),
    );
  }
}
