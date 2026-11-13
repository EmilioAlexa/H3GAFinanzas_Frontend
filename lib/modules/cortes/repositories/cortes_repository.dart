import 'package:decimal/decimal.dart';

import '../fixtures/cortes_demo_fixtures.dart';
import '../models/cut_history_model.dart';
import '../models/cut_model.dart';

class CortesRepository {
  final List<CutModel> _cuts = List.of(CortesDemoFixtures.cuts);
  var _sequence = 23;

  List<CutModel> list() => List.unmodifiable(_cuts);

  CutModel? find(String id) {
    for (final cut in _cuts) {
      if (cut.id == id) return cut;
    }
    return null;
  }

  CutModel? findByPeriod(DateTime start) {
    for (final cut in _cuts) {
      if (cut.periodStart == start && cut.status != 'Cancelado') return cut;
    }
    return null;
  }

  CutModel createDemo({required DateTime periodStart, required String actor}) {
    if (periodStart.weekday != DateTime.friday) {
      throw StateError('El inicio del periodo debe ser viernes.');
    }
    if (findByPeriod(periodStart) != null) {
      throw StateError('Ya existe un corte activo para ese periodo.');
    }
    final id = 'demo-cut-${DateTime.now().microsecondsSinceEpoch}';
    final created = CutModel(
      id: id,
      folio: 'CF-${periodStart.year}-${_sequence.toString().padLeft(3, '0')}',
      periodStart: periodStart,
      periodEndExclusive: periodStart.add(const Duration(days: 7)),
      createdAt: DateTime.now(),
      responsible: actor,
      status: 'En preparación',
      totalAmount: Decimal.zero,
      commissionAmount: Decimal.zero,
      includedCount: 0,
      excludedCount: 0,
      includedAmount: Decimal.zero,
      excludedAmount: Decimal.zero,
      movements: const [],
      history: [
        CutHistoryModel(
          status: 'En preparación',
          actor: actor,
          at: DateTime.now(),
          comment: 'Corte demo creado. No reserva pagos reales.',
        ),
      ],
    );
    _sequence++;
    _cuts.insert(0, created);
    return created;
  }

  CutModel transitionDemo({
    required String id,
    required String action,
    required String actor,
    required String comment,
  }) {
    if (comment.length > 500) {
      throw StateError('El comentario no puede superar 500 caracteres.');
    }
    final index = _cuts.indexWhere((cut) => cut.id == id);
    if (index < 0) throw StateError('El corte demo ya no está disponible.');
    final current = _cuts[index];
    final nextStatus = switch (action) {
      'generar' when current.status == 'En preparación' => 'Abierto',
      'cerrar' when current.status == 'Abierto' => 'Cerrado',
      'cancelar'
          when current.status == 'En preparación' ||
              current.status == 'Abierto' =>
        'Cancelado',
      _ => throw StateError('La acción no está disponible para este estado.'),
    };
    final updated = current.copyWith(
      status: nextStatus,
      history: [
        ...current.history,
        CutHistoryModel(
          status: nextStatus,
          actor: actor,
          at: DateTime.now(),
          comment: comment.trim().isEmpty ? null : comment.trim(),
        ),
      ],
    );
    _cuts[index] = updated;
    return updated;
  }
}
