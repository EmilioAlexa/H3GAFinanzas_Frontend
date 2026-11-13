import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/app/theme/app_theme.dart';
import 'package:h3ga_finanzas/modules/reportes/controllers/reportes_controller.dart';
import 'package:h3ga_finanzas/modules/reportes/models/report_type_model.dart';
import 'package:h3ga_finanzas/modules/reportes/repositories/reportes_repository.dart';
import 'package:h3ga_finanzas/modules/reportes/views/pages/reportes_page.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es_MX'));

  testWidgets('reports overview adapts and renders charts on compact and wide',
      (tester) async {
    for (final size in [
      const Size(390, 844),
      const Size(768, 1024),
      const Size(1280, 900)
    ]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportesRepositoryProvider.overrideWith(
              (ref) => const ReportesRepository(demoMode: true),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: ReportesPage()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Ingresos por periodo'), findsWidgets);
      expect(find.text('Exportar reporte'), findsOneWidget);
      expect(find.text('Pagos al IMSS'), findsNWidgets(2));
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.byType(PieChart), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'viewport $size');
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('IMSS detail shows only admin report content', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportesRepositoryProvider.overrideWith(
            (ref) => const ReportesRepository(demoMode: true),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: ReportesPage(reportType: ReportType.imss),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Pagos al IMSS'), findsOneWidget);
    expect(find.text('H3-M40-0317'), findsOneWidget);
    expect(find.textContaining('ficticios'), findsNothing);
    expect(tester.takeException(), isNull);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
