import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/app/theme/app_theme.dart';
import 'package:h3ga_finanzas/core/storage/token_storage.dart';
import 'package:h3ga_finanzas/modules/auth/auth.dart';
import 'package:h3ga_finanzas/modules/dashboard/dashboard.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es_MX'));

  testWidgets('management dashboard adapts to compact and expanded widths',
      (tester) async {
    for (final size in [const Size(390, 844), const Size(1280, 900)]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(
              (ref) => _DashboardAuthController(UserRole.administrador),
            ),
            dashboardRepositoryProvider.overrideWith(
              (ref) => const DashboardRepository(demoMode: true),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: DashboardPage()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Ingresos por servicio'), findsOneWidget);
      expect(find.byType(BarChart), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'viewport $size');
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('advisor dashboard does not render administrative aggregates',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => _DashboardAuthController(UserRole.asesor),
          ),
          dashboardRepositoryProvider.overrideWith(
            (ref) => const DashboardRepository(demoMode: true),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: DashboardPage()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Mis clientes prioritarios'), findsOneWidget);
    expect(find.text('Ingresos por servicio'), findsNothing);
    expect(find.text('Actividad reciente'), findsNothing);
    expect(tester.takeException(), isNull);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

class _DashboardAuthController extends AuthController {
  _DashboardAuthController(UserRole role)
      : super(
          AuthRepository(Dio(), const TokenStorage(FlutterSecureStorage())),
          demoMode: true,
          demoRole: role,
        ) {
    state = AsyncData(
      AuthSessionModel(
        id: 'test-${role.name}',
        name: 'Usuario de prueba',
        email: 'test@example.test',
        role: role,
      ),
    );
  }
}
