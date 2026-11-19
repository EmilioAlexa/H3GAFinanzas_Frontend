import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/core/network/api_client.dart';
import 'package:h3ga_finanzas/core/storage/token_storage.dart';
import 'package:h3ga_finanzas/modules/auth/controllers/auth_controller.dart';
import 'package:h3ga_finanzas/modules/auth/models/auth_session_model.dart';
import 'package:h3ga_finanzas/modules/auth/repositories/auth_repository.dart';
import 'package:h3ga_finanzas/modules/auth/views/pages/login_page.dart';

class RejectedLoginRepository extends AuthRepository {
  RejectedLoginRepository()
      : super(Dio(), const TokenStorage(FlutterSecureStorage()));

  @override
  Future<AuthSessionModel> login(
      {required String email, required String password}) async {
    final request = RequestOptions(
        path: '/auth/login',
        method: 'POST',
        extra: {publicLoginRequestKey: true});
    throw DioException(
      requestOptions: request,
      response: Response(requestOptions: request, statusCode: 401),
      type: DioExceptionType.badResponse,
    );
  }
}

void main() {
  testWidgets(
      'login rechazado muestra credenciales incorrectas sin sesión expirada',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(RejectedLoginRepository())
      ],
      child: const MaterialApp(home: LoginPage()),
    ));
    await tester.enterText(
        find.byType(TextFormField).at(0), 'persona@example.test');
    await tester.enterText(find.byType(TextFormField).at(1), 'incorrecta');
    await tester.ensureVisible(find.text('Iniciar sesión'));
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
    expect(find.textContaining('sesión expiró'), findsNothing);
  });

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
    expect(find.textContaining('demostración'), findsNothing);
    expect(find.text('Rol para probar la navegación'), findsNothing);
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
        tester
            .getRect(
              find.text('Ingrese sus credenciales para acceder al sistema'),
            )
            .right,
        lessThanOrEqualTo(size.width),
        reason: 'login intro must stay within viewport $size',
      );
      expect(tester.takeException(), isNull, reason: 'viewport $size');
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
