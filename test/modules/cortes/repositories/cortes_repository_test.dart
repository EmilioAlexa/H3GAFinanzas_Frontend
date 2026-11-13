import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/modules/cortes/repositories/cortes_repository.dart';

void main() {
  test('new periods must start on Friday and cannot overlap an active cut', () {
    final repository = CortesRepository();
    expect(
      () => repository.createDemo(
        periodStart: DateTime(2026, 11, 12),
        actor: 'Admin demo',
      ),
      throwsStateError,
    );
    expect(
      () => repository.createDemo(
        periodStart: DateTime(2025, 5, 23),
        actor: 'Admin demo',
      ),
      throwsStateError,
    );
  });

  test('corte follows preparation, open, close and terminal states', () {
    final repository = CortesRepository();
    final created = repository.createDemo(
      periodStart: DateTime(2026, 11, 13),
      actor: 'Admin demo',
    );
    expect(created.status, 'En preparación');
    expect(created.periodEndExclusive, DateTime(2026, 11, 20));

    final open = repository.transitionDemo(
      id: created.id,
      action: 'generar',
      actor: 'Admin demo',
      comment: 'Revisado',
    );
    expect(open.status, 'Abierto');
    expect(open.history.last.comment, 'Revisado');

    final closed = repository.transitionDemo(
      id: created.id,
      action: 'cerrar',
      actor: 'Finanzas demo',
      comment: '',
    );
    expect(closed.status, 'Cerrado');
    expect(
      () => repository.transitionDemo(
        id: created.id,
        action: 'cancelar',
        actor: 'Admin demo',
        comment: '',
      ),
      throwsStateError,
    );
  });

  test('period may be reused after its previous cut is cancelled', () {
    final repository = CortesRepository();
    repository.transitionDemo(
      id: 'demo-cut-1',
      action: 'cancelar',
      actor: 'Admin demo',
      comment: 'Corrección de periodo',
    );
    final replacement = repository.createDemo(
      periodStart: DateTime(2025, 5, 23),
      actor: 'Admin demo',
    );
    expect(replacement.status, 'En preparación');
  });
}
