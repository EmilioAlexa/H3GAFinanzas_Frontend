import 'package:decimal/decimal.dart';

import '../../../core/demo/demo_dataset.dart';
import '../../../core/demo/demo_metric.dart';
import '../../../core/demo/demo_record.dart';
import '../models/prenomina_cut_model.dart';
import '../models/prenomina_model.dart';
import '../models/prenomina_movement_model.dart';

abstract final class PrenominaDemoFixtures {
  static const dataset = DemoDataset(
    module: 'prenomina',
    metrics: [
      DemoMetric(label: 'Periodo', value: '16–22 may.'),
      DemoMetric(label: 'Receptores', value: '4'),
      DemoMetric(label: 'Total estimado', value: '\$7,980'),
    ],
    records: [
      DemoRecord(
        id: 'demo-daniela',
        title: 'Daniela Cruz',
        subtitle: '2 movimientos · 2 contratos',
        status: 'En preparación',
        amount: '\$2,700',
      ),
      DemoRecord(
        id: 'demo-jorge',
        title: 'Jorge Silva',
        subtitle: '2 movimientos · 2 contratos',
        status: 'En preparación',
        amount: '\$3,000',
      ),
      DemoRecord(
        id: 'demo-monica',
        title: 'Mónica Ruiz',
        subtitle: '1 movimiento · 1 contrato',
        status: 'En preparación',
        amount: '\$1,080',
      ),
      DemoRecord(
        id: 'demo-external',
        title: 'Ricardo Treviño',
        subtitle: '1 movimiento · 1 contrato',
        status: 'En preparación',
        amount: '\$1,200',
      ),
    ],
    notes: ['Movimientos y montos de muestra; no representan nómina real.'],
  );

  static Decimal _money(String value) => Decimal.parse(value);

  static final List<PrenominaModel> recipients = [
    PrenominaModel(
      id: 'demo-daniela',
      cutId: 'demo-cut-021',
      cutName: 'CF-2025-021',
      period: '16–22 mayo 2025',
      recipientId: 'demo-user-1',
      recipient: 'Daniela Cruz',
      position: 'Asesora',
      status: 'En preparación',
      movements: [
        PrenominaMovementModel(
          id: 'demo-movement-1',
          payment: 'PG-2025-0428',
          contract: 'M40202500001',
          saleType: 'Cambaceo',
          percentage: _money('15'),
          baseAmount: _money('10000'),
          commissionAmount: _money('1500'),
          status: 'En preparación',
        ),
        PrenominaMovementModel(
          id: 'demo-movement-2',
          payment: 'PG-2025-0501',
          contract: 'H3-M40-0317',
          saleType: 'Referidor',
          percentage: _money('12'),
          baseAmount: _money('10000'),
          commissionAmount: _money('1200'),
          status: 'Incluida',
        ),
      ],
    ),
    PrenominaModel(
      id: 'demo-jorge',
      cutId: 'demo-cut-021',
      cutName: 'CF-2025-021',
      period: '16–22 mayo 2025',
      recipientId: 'demo-user-2',
      recipient: 'Jorge Silva',
      position: 'Asesor',
      status: 'En preparación',
      movements: [
        PrenominaMovementModel(
          id: 'demo-movement-3',
          payment: 'PG-2025-0431',
          contract: 'APD-2025-0108',
          saleType: 'Referido',
          percentage: _money('10'),
          baseAmount: _money('12000'),
          commissionAmount: _money('1200'),
          status: 'En preparación',
        ),
        PrenominaMovementModel(
          id: 'demo-movement-4',
          payment: 'PG-2025-0490',
          contract: 'M10-2025-0081',
          saleType: 'Cambaceo',
          percentage: _money('15'),
          baseAmount: _money('12000'),
          commissionAmount: _money('1800'),
          status: 'En preparación',
        ),
      ],
    ),
    PrenominaModel(
      id: 'demo-monica',
      cutId: 'demo-cut-021',
      cutName: 'CF-2025-021',
      period: '16–22 mayo 2025',
      recipientId: 'demo-user-3',
      recipient: 'Mónica Ruiz',
      position: 'Asesora',
      status: 'En preparación',
      movements: [
        PrenominaMovementModel(
          id: 'demo-movement-5',
          payment: 'PG-2025-0444',
          contract: 'M40-2025-0101',
          saleType: 'Referidor',
          percentage: _money('12'),
          baseAmount: _money('9000'),
          commissionAmount: _money('1080'),
          status: 'En preparación',
        ),
      ],
    ),
    PrenominaModel(
      id: 'demo-external',
      cutId: 'demo-cut-021',
      cutName: 'CF-2025-021',
      period: '16–22 mayo 2025',
      recipientId: 'demo-recipient-1',
      recipient: 'Ricardo Treviño',
      position: 'Referidor externo',
      status: 'En preparación',
      movements: [
        PrenominaMovementModel(
          id: 'demo-movement-6',
          payment: 'PG-2025-0452',
          contract: 'APD-2025-0115',
          saleType: 'Referido',
          percentage: _money('8'),
          baseAmount: _money('15000'),
          commissionAmount: _money('1200'),
          status: 'En preparación',
        ),
      ],
    ),
  ];

  static final List<PrenominaCutModel> cuts = [
    PrenominaCutModel(
      id: 'demo-cut-021',
      name: 'CF-2025-021',
      period: '16–22 mayo 2025',
      status: 'En preparación',
      people: 4,
      operations: 6,
      total: _money('7980'),
      generated: false,
    ),
    PrenominaCutModel(
      id: 'demo-cut-020',
      name: 'CF-2025-020',
      period: '09–15 mayo 2025',
      status: 'Generada',
      people: 5,
      operations: 4,
      total: _money('9100'),
      generated: true,
    ),
    PrenominaCutModel(
      id: 'demo-cut-019',
      name: 'CF-2025-019',
      period: '02–08 mayo 2025',
      status: 'Generada',
      people: 4,
      operations: 5,
      total: _money('8420'),
      generated: true,
    ),
  ];
}
