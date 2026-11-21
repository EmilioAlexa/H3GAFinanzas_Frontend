import 'package:decimal/decimal.dart';

import '../../../core/network/finanzas_api.dart';
import '../fixtures/prenomina_demo_fixtures.dart';
import '../models/prenomina_model.dart';
import '../models/prenomina_movement_model.dart';

class PrenominaRepository {
  PrenominaRepository({this.api});
  final FinanzasApi? api;
  Future<List<PrenominaModel>> loadReal() async {
    final records = await api!.list('/finanzas/prenominas');
    final recipients = <PrenominaModel>[];
    for (final record in records) {
      final row = await api!.detail('/finanzas/prenominas/${record['id']}');
      final cut = apiMap(row['cortes_financieros']);
      for (final raw in row['detalle_prenomina'] as List) {
        final detail = apiMap(raw);
        final concept =
            apiText(apiMap(detail['conceptos_dispersion'])['nombre']);
        // Referidor identity is deliberately not consumed under stage 5 scope.

        recipients.add(PrenominaModel(
            id: '${row['id']}/${detail['id']}',
            payrollId: apiText(row['id']),
            backendTotal: Decimal.parse(
                apiText(detail['monto_referencial'] ?? detail['monto_total'])),
            cutId: apiText(row['corte_id']),
            cutName: apiText(cut['numero_corte']),
            period: '${cut['fecha_inicio']} / ${cut['fecha_fin']}',
            recipientId: apiText(
                detail['receptor_dispersion_id'] ?? detail['beneficiario_id']),
            recipient: concept == 'Referidor'
                ? 'Referidor (concepto general; snapshot historico)'
                : apiText(detail['receptor_nombre_snapshot']),
            position: concept,
            status: apiText(apiMap(row['estados_prenomina'])['nombre']),
            movements: (detail['comisiones'] as List? ?? const []).map((raw) {
              final c = apiMap(raw);
              final payment = apiMap(c['pagos']);
              return PrenominaMovementModel(
                  id: apiText(c['id']),
                  payment: apiText(c['pago_id']),
                  contract: apiText(apiMap(payment['contratos'])['folio']),
                  saleType: concept,
                  percentage: Decimal.parse(apiText(c['valor_aplicado'])),
                  baseAmount: Decimal.parse(apiText(c['monto_base'])),
                  commissionAmount: Decimal.parse(apiText(c['monto_comision'])),
                  status: 'Incluida');
            }).toList()));
      }
    }
    _recipients = recipients;
    return listDemo();
  }

  List<PrenominaModel> _recipients =
      List<PrenominaModel>.of(PrenominaDemoFixtures.recipients);

  List<PrenominaModel> listDemo() => List.unmodifiable(_recipients);

  List<PrenominaModel> recipientsForCut(String cutId) =>
      List.unmodifiable(_recipients.where((item) => item.cutId == cutId));

  PrenominaModel? findDemo(String id) {
    for (final item in _recipients) {
      if (item.id == id) return item;
    }
    return null;
  }

  void generateDemo(String cutId) {
    final matching = _recipients.where((item) => item.cutId == cutId);
    if (matching.isEmpty) throw StateError('No hay movimientos para generar.');
    if (matching.every((item) => item.status == 'Preparada')) {
      throw StateError('Este corte ya tiene una prenómina demo.');
    }
    _recipients = [
      for (final item in _recipients)
        if (item.cutId == cutId)
          PrenominaModel(
            id: item.id,
            cutId: item.cutId,
            cutName: item.cutName,
            period: item.period,
            recipientId: item.recipientId,
            recipient: item.recipient,
            position: item.position,
            status: 'Preparada',
            movements: item.movements
                .map((movement) => movement.status == 'En preparación'
                    ? movement.copyWithStatus('Incluida')
                    : movement)
                .toList(),
          )
        else
          item,
    ];
  }
}
