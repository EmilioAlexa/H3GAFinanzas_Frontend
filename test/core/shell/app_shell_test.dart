import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:h3ga_finanzas/app/theme/app_theme.dart';
import 'package:h3ga_finanzas/core/shell/app_shell.dart';
import 'package:h3ga_finanzas/modules/auth/auth.dart';

void main() {
  testWidgets('shell uses sidebar on web and bottom navigation on compact',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const AppShell(
            session: AuthSessionModel(
              id: 'local-admin',
              name: 'Lic. Anita',
              email: 'usuario@h3ga.mx',
              role: UserRole.administrador,
            ),
            child: ColoredBox(color: AppTheme.canvas),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    Future<void> pump(Size size) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
    }

    await pump(const Size(1280, 900));
    expect(find.byKey(const Key('expanded-sidebar')), findsOneWidget);
    expect(find.byKey(const Key('desktop-shell-header')), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);

    await pump(const Size(390, 844));
    expect(find.byKey(const Key('expanded-sidebar')), findsNothing);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Más'), findsOneWidget);
    expect(tester.takeException(), isNull);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
