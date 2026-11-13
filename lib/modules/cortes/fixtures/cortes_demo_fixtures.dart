import 'package:decimal/decimal.dart';

import '../../../core/demo/demo_dataset.dart';
import '../../../core/demo/demo_metric.dart';
import '../../../core/demo/demo_record.dart';
import '../models/cut_commission_line_model.dart';
import '../models/cut_distribution_model.dart';
import '../models/cut_history_model.dart';
import '../models/cut_model.dart';
import '../models/cut_movement_model.dart';

abstract final class CortesDemoFixtures {
  static const dataset = DemoDataset(
    module: 'cortes',
    metrics: [
      DemoMetric(label: 'Corte actual', value: '23–29 may. 2025'),
      DemoMetric(label: 'Pagos incluidos', value: '72'),
      DemoMetric(label: 'Por revisar', value: '4'),
    ],
    records: [
      DemoRecord(
        id: 'demo-cut-1',
        title: 'Corte 23–29 mayo 2025',
        subtitle: 'Semana financiera · viernes a jueves',
        status: 'Abierto',
        amount: '\$682,450.00',
      ),
      DemoRecord(
        id: 'demo-cut-2',
        title: 'Corte 16–22 mayo 2025',
        subtitle: '94 pagos incluidos',
        status: 'Cerrado',
        amount: '\$1,284,500.00',
      ),
      DemoRecord(
        id: 'demo-cut-3',
        title: 'Corte 09–15 mayo 2025',
        subtitle: '88 pagos incluidos',
        status: 'Cerrado',
        amount: '\$998,200.00',
      ),
      DemoRecord(
        id: 'demo-cut-4',
        title: 'Corte 02–08 mayo 2025',
        subtitle: '82 pagos · reservas liberadas',
        status: 'Cancelado',
        amount: '\$872,650.00',
      ),
    ],
    notes: [
      'Montos, cortes, personas e IDs son datos locales de demostración.',
      'Los periodos financieros se muestran de viernes a jueves en America/Cancun.',
    ],
  );

  static final cuts = <CutModel>[
    CutModel(
      id: 'demo-cut-1',
      folio: 'CF-2025-022',
      periodStart: DateTime(2025, 5, 23),
      periodEndExclusive: DateTime(2025, 5, 30),
      createdAt: DateTime(2025, 5, 23),
      responsible: 'Lucía Méndez',
      status: 'Abierto',
      totalAmount: Decimal.parse('682450'),
      commissionAmount: Decimal.parse('82140'),
      includedCount: 72,
      excludedCount: 4,
      includedAmount: Decimal.parse('654100'),
      excludedAmount: Decimal.parse('28350'),
      advisorCount: 18,
      movements: _previewMovements,
      history: [
        CutHistoryModel(
          status: 'En preparación',
          actor: 'Lucía Méndez',
          at: DateTime(2025, 5, 23, 9),
          comment: 'Corte semanal creado.',
        ),
        CutHistoryModel(
          status: 'Abierto',
          actor: 'Lucía Méndez',
          at: DateTime(2025, 5, 23, 10),
          comment: 'Corte generado para revisión.',
        ),
      ],
    ),
    CutModel(
      id: 'demo-cut-2',
      folio: 'CF-2025-021',
      periodStart: DateTime(2025, 5, 16),
      periodEndExclusive: DateTime(2025, 5, 23),
      createdAt: DateTime(2025, 5, 23),
      responsible: 'Lucía Méndez',
      status: 'Cerrado',
      totalAmount: Decimal.parse('1284500'),
      commissionAmount: Decimal.parse('164820'),
      includedCount: 94,
      excludedCount: 0,
      includedAmount: Decimal.parse('1284500'),
      excludedAmount: Decimal.zero,
      advisorCount: 28,
      movements: _previewMovements,
      history: [
        CutHistoryModel(
          status: 'En preparación',
          actor: 'Lucía Méndez',
          at: DateTime(2025, 5, 23, 9),
        ),
        CutHistoryModel(
          status: 'Abierto',
          actor: 'Lucía Méndez',
          at: DateTime(2025, 5, 23, 10),
        ),
        CutHistoryModel(
          status: 'Cerrado',
          actor: 'Joyce Mabel',
          at: DateTime(2025, 5, 23, 16),
          comment: 'Cierre confirmado.',
        ),
      ],
    ),
    CutModel(
      id: 'demo-cut-3',
      folio: 'CF-2025-020',
      periodStart: DateTime(2025, 5, 9),
      periodEndExclusive: DateTime(2025, 5, 16),
      createdAt: DateTime(2025, 5, 16),
      responsible: 'Roberto Gil',
      status: 'Cerrado',
      totalAmount: Decimal.parse('998200'),
      commissionAmount: Decimal.parse('120400'),
      includedCount: 88,
      excludedCount: 0,
      includedAmount: Decimal.parse('998200'),
      excludedAmount: Decimal.zero,
      advisorCount: 22,
      movements: _previewMovements,
      history: [
        CutHistoryModel(
          status: 'En preparación',
          actor: 'Roberto Gil',
          at: DateTime(2025, 5, 16, 10),
        ),
        CutHistoryModel(
          status: 'Abierto',
          actor: 'Roberto Gil',
          at: DateTime(2025, 5, 16, 11),
        ),
        CutHistoryModel(
          status: 'Cerrado',
          actor: 'Joyce Mabel',
          at: DateTime(2025, 5, 16, 15),
        ),
      ],
    ),
    CutModel(
      id: 'demo-cut-4',
      folio: 'CF-2025-019',
      periodStart: DateTime(2025, 5, 2),
      periodEndExclusive: DateTime(2025, 5, 9),
      createdAt: DateTime(2025, 5, 9),
      responsible: 'Lucía Méndez',
      status: 'Cancelado',
      totalAmount: Decimal.parse('872650'),
      commissionAmount: Decimal.parse('90200'),
      includedCount: 82,
      excludedCount: 0,
      includedAmount: Decimal.parse('872650'),
      excludedAmount: Decimal.zero,
      advisorCount: 20,
      movements: _previewMovements,
      history: [
        CutHistoryModel(
          status: 'En preparación',
          actor: 'Lucía Méndez',
          at: DateTime(2025, 5, 9, 9),
        ),
        CutHistoryModel(
          status: 'Cancelado',
          actor: 'Lucía Méndez',
          at: DateTime(2025, 5, 9, 11),
          comment: 'Cancelación administrativa.',
        ),
      ],
    ),
  ];

  static final _previewMovements = <CutMovementModel>[
    CutMovementModel(
      id: 'demo-movement-1',
      paymentFolio: 'PG-2025-0428',
      clientName: 'Elena Robles Vargas',
      serviceName: 'Modalidad 40',
      paymentMethod: 'Transferencia',
      paymentDate: DateTime(2025, 5, 24),
      amount: Decimal.fromInt(10000),
      included: true,
    ),
    CutMovementModel(
      id: 'demo-movement-2',
      paymentFolio: 'PG-2025-0432',
      clientName: 'Sofía Ramírez',
      serviceName: 'APD',
      paymentMethod: 'Transferencia',
      paymentDate: DateTime(2025, 5, 25),
      amount: Decimal.parse('42500'),
      included: true,
    ),
    CutMovementModel(
      id: 'demo-movement-3',
      paymentFolio: 'PG-2025-0436',
      clientName: 'Ana López',
      serviceName: 'Modalidad 10',
      paymentMethod: 'Depósito',
      paymentDate: DateTime(2025, 5, 27),
      amount: Decimal.parse('7200'),
      included: true,
    ),
    CutMovementModel(
      id: 'demo-movement-excluded-1',
      paymentFolio: 'PG-2025-0437',
      clientName: 'Carlos Mendoza',
      serviceName: 'Modalidad 40',
      paymentMethod: 'Transferencia',
      paymentDate: DateTime(2025, 5, 27),
      amount: Decimal.parse('6900'),
      included: false,
      exclusionReason: 'Evidencia pendiente',
    ),
    CutMovementModel(
      id: 'demo-movement-excluded-2',
      paymentFolio: 'PG-2025-0438',
      clientName: 'Javier Torres',
      serviceName: 'APD',
      paymentMethod: 'Depósito',
      paymentDate: DateTime(2025, 5, 28),
      amount: Decimal.parse('12800'),
      included: false,
      exclusionReason: 'Referencia inconsistente',
    ),
    CutMovementModel(
      id: 'demo-movement-excluded-3',
      paymentFolio: 'PG-2025-0440',
      clientName: 'María Salgado',
      serviceName: 'Modalidad 10',
      paymentMethod: 'Efectivo',
      paymentDate: DateTime(2025, 5, 30),
      amount: Decimal.parse('8650'),
      included: false,
      exclusionReason: 'Fuera del periodo',
    ),
  ];

  static final distributions = <CutDistributionModel>[
    CutDistributionModel(
      paymentFolio: 'PG-2025-0428',
      clientName: 'Elena Robles Vargas',
      serviceName: 'Modalidad 40',
      paymentMethod: 'Transferencia',
      amount: Decimal.parse('10000'),
      lines: [
        CutCommissionLineModel(
          destination: 'Asesor',
          percentage: Decimal.parse('15'),
          amount: Decimal.parse('1500'),
        ),
        CutCommissionLineModel(
          destination: 'Director',
          percentage: Decimal.parse('5'),
          amount: Decimal.parse('500'),
        ),
        CutCommissionLineModel(
          destination: 'Gerente',
          percentage: Decimal.parse('5'),
          amount: Decimal.parse('500'),
        ),
        CutCommissionLineModel(
          destination: 'IMSS',
          percentage: Decimal.parse('50'),
          amount: Decimal.parse('5000'),
        ),
      ],
    ),
    CutDistributionModel(
      paymentFolio: 'PG-2025-0501',
      clientName: 'Natalia Vázquez Soto',
      serviceName: 'Modalidad 40',
      paymentMethod: 'Transferencia',
      amount: Decimal.parse('10000'),
      lines: [
        CutCommissionLineModel(
          destination: 'Asesor',
          percentage: Decimal.parse('12'),
          amount: Decimal.parse('1200'),
        ),
        CutCommissionLineModel(
          destination: 'Director',
          percentage: Decimal.parse('5'),
          amount: Decimal.parse('500'),
        ),
        CutCommissionLineModel(
          destination: 'Gerente',
          percentage: Decimal.parse('5'),
          amount: Decimal.parse('500'),
        ),
        CutCommissionLineModel(
          destination: 'IMSS',
          percentage: Decimal.parse('50'),
          amount: Decimal.parse('5000'),
        ),
      ],
    ),
  ];
}
