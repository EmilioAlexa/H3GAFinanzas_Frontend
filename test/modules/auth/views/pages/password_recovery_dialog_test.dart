import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/modules/auth/repositories/password_recovery_repository.dart';
import 'package:h3ga_finanzas/modules/auth/views/pages/password_recovery_dialog.dart';

void main() {
  testWidgets('does not announce success before a successful server reset',
      (tester) async {
    final dio = Dio();
    var resetCalls = 0;
    var rejectReset = true;
    dio.interceptors.add(InterceptorsWrapper(onRequest: (r, h) {
      if (r.path.endsWith('reset-password')) {
        resetCalls++;
        if (rejectReset) {
          h.reject(DioException(
              requestOptions: r,
              response: Response(
                  requestOptions: r,
                  statusCode: 400,
                  data: {'message': 'Codigo invalido o expirado'})));
          return;
        }
      }
      h.resolve(Response(requestOptions: r, data: {'message': 'OK'}));
    }));
    await tester.pumpWidget(ProviderScope(
        overrides: [
          passwordRecoveryRepositoryProvider
              .overrideWithValue(PasswordRecoveryRepository(dio))
        ],
        child:
            const MaterialApp(home: Scaffold(body: PasswordRecoveryDialog()))));
    await tester.enterText(
        find.byType(TextFormField).first, 'test@example.test');
    await tester.tap(find.textContaining('Restablecer').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.pump();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(resetCalls, 0);
    await tester.enterText(find.byType(TextFormField).at(0), 'example-secret');
    await tester.enterText(find.byType(TextFormField).at(1), 'example-secret');
    await tester.ensureVisible(find.text('Cambiar contrase\u00f1a'));
    await tester.tap(find.text('Cambiar contrase\u00f1a'));
    await tester.pumpAndSettle();
    expect(resetCalls, 1);
    expect(
        find.text(
            'El codigo es invalido o expiro. Cancela y solicita uno nuevo.'),
        findsOneWidget);
    rejectReset = false;
    await tester.tap(find.text('Cambiar contrase\u00f1a'));
    await tester.pumpAndSettle();
    expect(resetCalls, 2);
    expect(find.textContaining('se cambi'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
