import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../../core/network/finanzas_api.dart';
import '../fixtures/cortes_demo_fixtures.dart';
import '../models/cut_history_model.dart';
import '../models/cut_model.dart';
import '../models/cut_movement_model.dart';

class CortesRepository {
  CortesRepository({this.api});
  final FinanzasApi? api;
  DateTime? _retryAt;
  Future<T> _read<T>(Future<T> Function() operation) async {
    if (_retryAt != null && DateTime.now().isBefore(_retryAt!)) {
      throw StateError(
          'Demasiadas solicitudes. Reintenta después de $_retryAt.');
    }
    try {
      return await operation();
    } on DioException catch (error) {
      if (error.response?.statusCode == 429) {
        final header = error.response?.headers.value('retry-after');
        final seconds = int.tryParse(header ?? '');
        _retryAt = seconds != null
            ? DateTime.now().add(Duration(seconds: seconds < 0 ? 0 : seconds))
            : DateTime.tryParse(header ?? '');
        if (_retryAt == null && header != null) {
          try {
            _retryAt = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", 'en_US')
                .parseUtc(header);
          } on FormatException {
            /* Fall back to a conservative manual cooldown. */
          }
        }
        _retryAt ??= DateTime.now().add(const Duration(seconds: 60));
        throw StateError(
            'Demasiadas solicitudes. Reintenta después de $_retryAt.');
      }
      throw StateError(error.response == null
          ? 'No se pudo conectar para consultar cortes. Reintenta manualmente.'
          : 'No se pudieron consultar cortes (HTTP ${error.response?.statusCode}). Reintenta manualmente.');
    }
  }

  Future<List<CutModel>> loadReal() async {
    final rows = await _read(() => api!.list('/finanzas/cortes'));
    final cuts = rows.map((r) => mapCut(r)).toList();
    _cuts
      ..clear()
      ..addAll(cuts);
    return list();
  }

  CutModel accept(Map<String, dynamic> row) {
    final cut = mapCut(row);
    final index = _cuts.indexWhere((c) => c.id == cut.id);
    if (index < 0) {
      _cuts.insert(0, cut);
    } else {
      _cuts[index] = cut;
    }
    return cut;
  }

  Future<CutModel> loadDetail(String id) => _read(() => _loadDetail(id));
  Future<CutModel> _loadDetail(String id) async {
    final row = await api!.detail('/finanzas/cortes/$id');
    final preparing = apiText(apiMap(row['estados_corte'])['nombre'])
        .startsWith('En prepara');
    final preparation = preparing
        ? await api!.detail('/finanzas/cortes/$id/preparacion')
        : null;
    final history = await api!.list('/finanzas/cortes/$id/historial');
    final cut = mapCut(row, preparation: preparation, history: history);
    final index = _cuts.indexWhere((c) => c.id == id);
    if (index >= 0) _cuts[index] = cut;
    return cut;
  }

  CutModel mapCut(Map<String, dynamic> r,
      {Map<String, dynamic>? preparation,
      List<Map<String, dynamic>> history = const []}) {
    final summary = apiMap(r['resumen']);
    final preview = preparation ??
        <String, dynamic>{
          'incluidos': {
            'cantidad': summary['cantidad_pagos'],
            'total_ingresos': summary['total_ingresos'],
            'pagos': (r['detalle_corte'] as List? ?? const [])
                .map((d) => apiMap(d)['pagos'])
                .toList()
          },
          'excluidos': {
            'cantidad': 0,
            'total_referencial': '0',
            'pagos': const <dynamic>[]
          }
        };
    final included = apiMap(preview['incluidos']);
    final excluded = apiMap(preview['excluidos']);
    final movements = <CutMovementModel>[];
    for (final group in [included, excluded]) {
      for (final raw in group['pagos'] as List? ?? const []) {
        final wrapper = apiMap(raw);
        final payment =
            wrapper['pago'] == null ? wrapper : apiMap(wrapper['pago']);
        final contract = apiMap(payment['contratos']);
        final client = apiMap(contract['clientes']);
        movements.add(CutMovementModel(
            id: apiText(payment['id']),
            paymentFolio: apiText(payment['folio_recibo'] ?? payment['id']),
            clientName: [
              client['nombre'],
              client['apellido_paterno'],
              client['apellido_materno']
            ].whereType<String>().join(' '),
            serviceName: apiText(apiMap(contract['servicios'])['nombre']),
            paymentMethod: apiText(apiMap(payment['formas_pago'])['nombre']),
            paymentDate: DateTime.parse(apiText(payment['fecha_pago'])),
            amount: Decimal.parse(apiText(payment['monto'])),
            included: identical(group, included),
            exclusionReason: wrapper['motivo'] as String?));
      }
    }
    return CutModel(
        id: apiText(r['id']),
        folio: apiText(r['folio']),
        periodStart: DateTime.parse(apiText(r['fecha_inicio'])),
        periodEndExclusive: DateTime.parse(apiText(r['fecha_fin'])),
        createdAt: DateTime.parse(apiText(r['creado_en'])),
        responsible: apiText(apiMap(
            r['usuarios_cortes_financieros_creado_porTousuarios'])['nombre']),
        status: apiText(apiMap(r['estados_corte'])['nombre']),
        totalAmount: Decimal.parse(apiText(summary['total_ingresos'])),
        commissionAmount: Decimal.parse(apiText(summary['total_comisiones'])),
        includedCount: included['cantidad'] as int,
        excludedCount: excluded['cantidad'] as int,
        includedAmount: Decimal.parse(apiText(included['total_ingresos'])),
        excludedAmount: Decimal.parse(apiText(excluded['total_referencial'])),
        movements: movements,
        history: history
            .map((h) => CutHistoryModel(
                status: apiText(apiMap(h['estado_nuevo'])['nombre']),
                actor: apiText(apiMap(h['usuarios'])['nombre']),
                at: DateTime.parse(apiText(h['fecha_cambio'])),
                comment: h['comentario'] as String?))
            .toList());
  }

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
