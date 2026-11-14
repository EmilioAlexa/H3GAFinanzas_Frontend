import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/app/theme/app_theme.dart';
import 'package:h3ga_finanzas/core/storage/token_storage.dart';
import 'package:h3ga_finanzas/modules/auth/auth.dart';
import 'package:h3ga_finanzas/modules/contratos/contratos.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  await initializeDateFormatting('es_MX');
  testWidgets('contracts list adapts to compact, medium, and expanded widths',
      (tester) async {
    for (final size in [
      const Size(390, 844),
      const Size(768, 900),
      const Size(1280, 900),
    ]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(
              (ref) => _ContratosAuthController(),
            ),
            contratosRepositoryProvider.overrideWith(
              (ref) => ContratosRepository(demoMode: true),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: ContratosPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Contratos'), findsOneWidget);
      expect(find.text('M40202500001'), findsWidgets);
      expect(tester.takeException(), isNull, reason: 'viewport $size');
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('service catalog displays the four demo service categories',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 900);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contratosRepositoryProvider.overrideWith(
            (ref) => ContratosRepository(demoMode: true),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: ServiciosPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Servicios'), findsOneWidget);
    expect(find.text('Modalidad 10'), findsOneWidget);
    expect(find.text('Modalidad 40'), findsOneWidget);
    expect(find.text('M40 Retroactiva'), findsOneWidget);
    expect(find.text('APD'), findsWidgets);
    expect(tester.takeException(), isNull);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('contract detail contains only contract DTO data',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => _ContratosAuthController(),
          ),
          contratosRepositoryProvider.overrideWith(
            (ref) => ContratosRepository(demoMode: true),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: ContratoDetallePage(contratoId: 'demo-contract-1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Información del contrato'), findsOneWidget);
    expect(find.text('Elena Robles Vargas'), findsOneWidget);
    expect(find.text('Cantidad de pagos'), findsOneWidget);
    expect(find.text('Resumen económico'), findsNothing);
    expect(tester.takeException(), isNull);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('new contract form uses DTO fields and has no monetary inputs',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => _ContratosAuthController(),
          ),
          contratosRepositoryProvider.overrideWith(
            (ref) => ContratosRepository(demoMode: true),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: ContratoFormPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Crear contrato'), findsNWidgets(2));
    expect(find.text('Folio'), findsOneWidget);
    expect(find.text('Cliente'), findsOneWidget);
    expect(find.text('Servicio'), findsOneWidget);
    expect(find.text('Monto mensual'), findsNothing);
    expect(tester.takeException(), isNull);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

class _ContratosAuthController extends AuthController {
  _ContratosAuthController()
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
