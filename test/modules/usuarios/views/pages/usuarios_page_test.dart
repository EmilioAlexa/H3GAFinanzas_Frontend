import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/app/theme/app_theme.dart';
import 'package:h3ga_finanzas/core/widgets/app_dialog.dart';
import 'package:h3ga_finanzas/modules/usuarios/controllers/usuarios_controller.dart';
import 'package:h3ga_finanzas/modules/usuarios/repositories/usuarios_repository.dart';
import 'package:h3ga_finanzas/modules/usuarios/views/pages/usuarios_page.dart';

void main() {
  testWidgets('user administration adapts to compact and expanded layouts',
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
            usuariosDemoModeProvider.overrideWith((ref) => true),
            usuariosRepositoryProvider.overrideWith(
              (ref) => UsuariosRepository(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: UsuariosPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Usuarios y accesos'), findsOneWidget);
      expect(find.text('Lucía Méndez Soto'), findsOneWidget);
      expect(find.text('Suspendido'), findsWidgets);
      expect(tester.takeException(), isNull, reason: 'viewport $size');
      await tester.tap(find.widgetWithText(FilledButton, 'Registrar usuario'));
      await tester.pumpAndSettle();
      expect(find.byType(AppDialog), findsOneWidget);
      final panel = tester.getRect(find.byType(Dialog));
      expect(panel.center.dx, closeTo(size.width / 2, 1));
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Cancelar').last);
      await tester.pumpAndSettle();
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
