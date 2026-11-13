import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/modules/auth/views/pages/login_page.dart';

void main() {
  testWidgets('shows login fields and action', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginPage())),
    );
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Usuario'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);

    await tester.ensureVisible(find.text('¿Olvidaste tu contraseña?'));
    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await tester.pumpAndSettle();
    expect(find.text('Recuperar contraseña'), findsOneWidget);
    expect(find.textContaining('Modo demostración'), findsOneWidget);
  });

  testWidgets('renders without overflow at compact, medium and expanded widths',
      (tester) async {
    for (final size in [
      const Size(390, 844),
      const Size(768, 1024),
      const Size(1280, 900),
    ]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginPage())),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bienvenido de vuelta'), findsOneWidget);
      expect(
        tester.getRect(
          find.text('Ingrese sus credenciales para acceder al sistema'),
        ).right,
        lessThanOrEqualTo(size.width),
        reason: 'login intro must stay within viewport $size',
      );
      expect(tester.takeException(), isNull, reason: 'viewport $size');
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
