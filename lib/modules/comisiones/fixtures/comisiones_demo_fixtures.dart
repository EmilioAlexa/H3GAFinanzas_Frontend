import 'package:decimal/decimal.dart';

import '../../../core/demo/demo_dataset.dart';
import '../../../core/demo/demo_metric.dart';
import '../../../core/demo/demo_record.dart';
import '../models/commission_concept_model.dart';
import '../models/commission_line_model.dart';
import '../models/commission_payment_model.dart';
import '../models/commission_snapshot_model.dart';
import '../models/dispersion_receiver_model.dart';

abstract final class ComisionesDemoFixtures {
  static const dataset = DemoDataset(
    module: 'comisiones',
    metrics: [
      DemoMetric(label: 'Pagos con comisión demo', value: '4'),
      DemoMetric(
          label: 'Estados de dispersión', value: 'Pendiente / Dispersada'),
    ],
    records: [
      DemoRecord(
          id: 'demo-commission-payment-1',
          title: 'PG-2025-0428',
          subtitle: 'Elena Robles Vargas · M40202500001',
          status: 'Dispersada'),
      DemoRecord(
          id: 'demo-commission-payment-2',
          title: 'PG-2025-0501',
          subtitle: 'Natalia Vázquez Soto · H3-M40-0317',
          status: 'Dispersada'),
      DemoRecord(
          id: 'demo-commission-payment-3',
          title: 'PG-2025-0502',
          subtitle: 'Carlos Mendoza Ruiz · H3-M10-0391',
          status: 'Pendiente de dispersión'),
      DemoRecord(
          id: 'demo-commission-payment-4',
          title: 'PG-2025-0503',
          subtitle: 'Rosa Elena Pacheco · H3-APD-0189',
          status: 'Pendiente de dispersión'),
    ],
    notes: [
      'Montos, contratos, receptores e IDs de conceptos son muestras locales; Empresa se calcula como remanente.',
    ],
  );

  static const concepts = <CommissionConceptModel>[
    CommissionConceptModel(id: 1, name: 'Asesor', external: false),
    CommissionConceptModel(id: 2, name: 'Director', external: false),
    CommissionConceptModel(id: 3, name: 'Gerente', external: false),
    CommissionConceptModel(
        id: 4, name: 'IMSS', external: false, onlyImssServices: true),
    CommissionConceptModel(id: 5, name: 'Referidor', external: true),
    CommissionConceptModel(id: 6, name: 'Bróker', external: true),
  ];

  static const receivers = <DispersionReceiverModel>[
    DispersionReceiverModel(
        id: 'demo-receiver-advisor-1',
        conceptId: 1,
        concept: 'Asesor',
        name: 'Daniela Cruz',
        active: true,
        external: false,
        userId: '00000000-0000-4000-8000-000000000011',
        role: 'Asesora'),
    DispersionReceiverModel(
        id: 'demo-receiver-advisor-2',
        conceptId: 1,
        concept: 'Asesor',
        name: 'Jorge Silva',
        active: true,
        external: false,
        userId: '00000000-0000-4000-8000-000000000012',
        role: 'Asesor'),
    DispersionReceiverModel(
        id: 'demo-receiver-director',
        conceptId: 2,
        concept: 'Director',
        name: 'Ricardo Treviño',
        active: true,
        external: false,
        userId: '00000000-0000-4000-8000-000000000013',
        role: 'Director comercial'),
    DispersionReceiverModel(
        id: 'demo-receiver-manager',
        conceptId: 3,
        concept: 'Gerente',
        name: 'Paola Garza',
        active: true,
        external: false,
        userId: '00000000-0000-4000-8000-000000000014',
        role: 'Gerente comercial'),
    DispersionReceiverModel(
        id: 'demo-receiver-imss',
        conceptId: 4,
        concept: 'IMSS',
        name: 'IMSS · Cuenta institucional',
        active: true,
        external: false,
        userId: '00000000-0000-4000-8000-000000000015',
        role: 'Institucional'),
    DispersionReceiverModel(
        id: 'demo-receiver-referrer',
        conceptId: 5,
        concept: 'Referidor',
        name: 'Luis Cantú',
        active: true,
        external: true,
        role: 'Referidor externo'),
    DispersionReceiverModel(
        id: 'demo-receiver-broker',
        conceptId: 6,
        concept: 'Bróker',
        name: 'Grupo Asesor Norte',
        active: true,
        external: true,
        role: 'Bróker'),
  ];

  static final payments = <CommissionPaymentModel>[
    CommissionPaymentModel(
      id: 'demo-commission-payment-1',
      paymentFolio: 'PG-2025-0428',
      contractId: 'demo-contract-1',
      contractFolio: 'M40202500001',
      clientName: 'Elena Robles Vargas',
      serviceName: 'Modalidad 40',
      advisorName: 'Daniela Cruz',
      paymentAmount: Decimal.parse('10000'),
      paymentDate: DateTime(2025, 5, 24),
      paymentMethod: 'Transferencia',
      assignedToCurrentAdvisor: true,
      snapshot: [
        _snapshot('demo-com-1-advisor', 1, 'Asesor', 'Daniela Cruz', '15',
            '1500', 'Dispersada'),
        _snapshot('demo-com-1-director', 2, 'Director', 'Ricardo Treviño', '5',
            '500', 'Dispersada'),
        _snapshot('demo-com-1-manager', 3, 'Gerente', 'Paola Garza', '5', '500',
            'Dispersada'),
        _snapshot('demo-com-1-imss', 4, 'IMSS', 'IMSS · Cuenta institucional',
            '50', '5000', 'Dispersada'),
      ],
      configuration: _config([
        _line(1, 'Asesor', 'demo-receiver-advisor-1', 'Daniela Cruz', '15'),
        _line(2, 'Director', 'demo-receiver-director', 'Ricardo Treviño', '5'),
        _line(3, 'Gerente', 'demo-receiver-manager', 'Paola Garza', '5'),
        _line(4, 'IMSS', 'demo-receiver-imss', 'IMSS · Cuenta institucional',
            '50'),
      ]),
      configurationHistory: [
        'Reglas aplicadas al validar el pago · 23/05/2025'
      ],
    ),
    CommissionPaymentModel(
      id: 'demo-commission-payment-2',
      paymentFolio: 'PG-2025-0501',
      contractId: 'demo-contract-5',
      contractFolio: 'H3-M40-0317',
      clientName: 'Natalia Vázquez Soto',
      serviceName: 'Modalidad 40',
      advisorName: 'Daniela Cruz',
      paymentAmount: Decimal.parse('10000'),
      paymentDate: DateTime(2025, 5, 21),
      paymentMethod: 'Transferencia',
      assignedToCurrentAdvisor: true,
      snapshot: [
        _snapshot('demo-com-2-advisor', 1, 'Asesor', 'Daniela Cruz', '12',
            '1200', 'Dispersada'),
        _snapshot('demo-com-2-referrer', 5, 'Referidor', 'Luis Cantú', '12',
            '1200', 'Dispersada'),
        _snapshot('demo-com-2-imss', 4, 'IMSS', 'IMSS · Cuenta institucional',
            '50', '5000', 'Dispersada'),
      ],
      configuration: _config([
        _line(1, 'Asesor', 'demo-receiver-advisor-1', 'Daniela Cruz', '12'),
        _line(5, 'Referidor', 'demo-receiver-referrer', 'Luis Cantú', '12'),
        _line(4, 'IMSS', 'demo-receiver-imss', 'IMSS · Cuenta institucional',
            '50'),
      ]),
      configurationHistory: [
        'Reglas aplicadas al validar el pago · 20/05/2025'
      ],
    ),
    CommissionPaymentModel(
      id: 'demo-commission-payment-3',
      paymentFolio: 'PG-2025-0502',
      contractId: 'demo-contract-2',
      contractFolio: 'H3-M10-0391',
      clientName: 'Carlos Mendoza Ruiz',
      serviceName: 'Modalidad 10',
      advisorName: 'Jorge Silva',
      paymentAmount: Decimal.parse('10000'),
      paymentDate: DateTime(2025, 5, 22),
      paymentMethod: 'Depósito',
      assignedToCurrentAdvisor: false,
      snapshot: [
        _snapshot('demo-com-3-advisor', 1, 'Asesor', 'Jorge Silva', '10',
            '1000', 'Pendiente de dispersión'),
        _snapshot('demo-com-3-director', 2, 'Director', 'Ricardo Treviño', '5',
            '500', 'Pendiente de dispersión'),
        _snapshot('demo-com-3-manager', 3, 'Gerente', 'Paola Garza', '5', '500',
            'Pendiente de dispersión'),
        _snapshot('demo-com-3-imss', 4, 'IMSS', 'IMSS · Cuenta institucional',
            '50', '5000', 'Pendiente de dispersión'),
      ],
      configuration: _config([
        _line(1, 'Asesor', 'demo-receiver-advisor-2', 'Jorge Silva', '10'),
        _line(2, 'Director', 'demo-receiver-director', 'Ricardo Treviño', '5'),
        _line(3, 'Gerente', 'demo-receiver-manager', 'Paola Garza', '5'),
        _line(4, 'IMSS', 'demo-receiver-imss', 'IMSS · Cuenta institucional',
            '50'),
      ]),
      configurationHistory: ['Esquema demo vigente · 19/05/2025'],
    ),
    CommissionPaymentModel(
      id: 'demo-commission-payment-4',
      paymentFolio: 'PG-2025-0503',
      contractId: 'demo-contract-3',
      contractFolio: 'H3-APD-0182',
      clientName: 'Sofía Ramírez León',
      serviceName: 'APD',
      advisorName: 'Daniela Cruz',
      paymentAmount: Decimal.parse('10000'),
      paymentDate: DateTime(2025, 5, 23),
      paymentMethod: 'Efectivo',
      assignedToCurrentAdvisor: true,
      snapshot: [
        _snapshot('demo-com-4-advisor', 1, 'Asesor', 'Daniela Cruz', '8', '800',
            'Pendiente de dispersión'),
        _snapshot('demo-com-4-broker', 6, 'Bróker', 'Grupo Asesor Norte', '8',
            '800', 'Pendiente de dispersión'),
      ],
      configuration: _config([
        _line(1, 'Asesor', 'demo-receiver-advisor-1', 'Daniela Cruz', '8'),
        _line(6, 'Bróker', 'demo-receiver-broker', 'Grupo Asesor Norte', '8'),
      ]),
      configurationHistory: ['Esquema APD demo vigente · 18/05/2025'],
    ),
  ];

  static CommissionSnapshotModel _snapshot(
          String id,
          int conceptId,
          String concept,
          String receiver,
          String percentage,
          String amount,
          String status) =>
      CommissionSnapshotModel(
        id: id,
        conceptId: conceptId,
        concept: concept,
        receiverName: receiver,
        percentage: Decimal.parse(percentage),
        amount: Decimal.parse(amount),
        status: status,
        history: [
          status == 'Dispersada' ? 'Dispersada · demo' : 'Generada · demo'
        ],
      );

  static CommissionLineModel _line(int conceptId, String concept,
          String receiverId, String receiver, String percentage) =>
      CommissionLineModel(
        conceptId: conceptId,
        concept: concept,
        receiverId: receiverId,
        receiverName: receiver,
        percentage: Decimal.parse(percentage),
      );

  static List<CommissionLineModel> _config(List<CommissionLineModel> rows) =>
      rows;
}
