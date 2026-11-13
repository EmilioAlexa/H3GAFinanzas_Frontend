import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/modules/auth/auth.dart';
import 'package:h3ga_finanzas/modules/pagos/pagos.dart';

void main() {
  test('financial administrator can send an initial payment for authorization',
      () {
    final repository = PagosRepository();

    final updated = repository.changeReviewStateDemo(
      paymentId: 'demo-payment-2',
      role: UserRole.administradorFinanciero,
      action: 'enviar_a_autorizacion',
      comment: 'Evidencia revisada',
      actor: 'Admin financiero demo',
    );

    expect(updated.estado, 'Pendiente de autorización');
    expect(updated.historial.last, contains('Evidencia revisada'));
    expect(
      () => repository.changeReviewStateDemo(
        paymentId: updated.id,
        role: UserRole.administradorFinanciero,
        action: 'validar',
        comment: '',
        actor: 'Admin financiero demo',
      ),
      throwsStateError,
    );
  });

  test('only administrator can validate and matching evidence is required', () {
    final repository = PagosRepository();

    expect(
      () => repository.changeReviewStateDemo(
        paymentId: 'demo-payment-3',
        role: UserRole.administrador,
        action: 'validar',
        comment: '',
        actor: 'Admin demo',
      ),
      throwsStateError,
    );

    final updated = repository.changeReviewStateDemo(
      paymentId: 'demo-payment-4',
      role: UserRole.administrador,
      action: 'validar',
      comment: 'Autorizado después de revisar',
      actor: 'Admin demo',
    );
    expect(updated.estado, 'Validado');
    expect(updated.historial.last, contains('Autorizado después de revisar'));
  });

  test('administrator can reject without evidence; advisor cannot decide', () {
    final repository = PagosRepository();

    final rejected = repository.changeReviewStateDemo(
      paymentId: 'demo-payment-3',
      role: UserRole.administrador,
      action: 'rechazar',
      comment: 'Solicitar comprobante legible',
      actor: 'Admin demo',
    );
    expect(rejected.estado, 'Rechazado');

    expect(
      () => repository.changeReviewStateDemo(
        paymentId: 'demo-payment-2',
        role: UserRole.asesor,
        action: 'rechazar',
        comment: '',
        actor: 'Asesor demo',
      ),
      throwsStateError,
    );
  });
}
