import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/app/theme/app_theme.dart';
import 'package:h3ga_finanzas/modules/prenomina/controllers/prenomina_controller.dart';
import 'package:h3ga_finanzas/modules/prenomina/repositories/prenomina_repository.dart';
import 'package:h3ga_finanzas/modules/prenomina/views/pages/prenomina_page.dart';

void main() {
  testWidgets('prenómina renders responsively and shows demo recipients',
      (tester) async {
    for (final size in [const Size(390, 844), const Size(1280, 900)]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prenominaControllerProvider.overrideWith((ref) =>
                PrenominaController(PrenominaRepository(), demoMode: true)),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: PrenominaPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Prenómina'), findsOneWidget);
      expect(find.text('Daniela Cruz'), findsOneWidget);
      expect(
          find.text(
              'Información referencial. Esta aplicación prepara el concentrado; no realiza pagos de nómina.'),
          findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'viewport $size');
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
