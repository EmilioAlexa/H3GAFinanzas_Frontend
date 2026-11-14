import '../../../core/demo/demo_dataset.dart';
import '../../../core/demo/demo_metric.dart';
import '../../../core/demo/demo_record.dart';
import '../models/contrato_model.dart';
import '../models/servicio_model.dart';

abstract final class ContratosDemoFixtures {
  static const services = <ServicioModel>[
    ServicioModel(
      id: 10,
      clave: 'm10',
      nombre: 'Modalidad 10',
      descripcionDemo:
          'Seguimiento de inscripción y mensualidades del servicio.',
    ),
    ServicioModel(
      id: 40,
      clave: 'm40',
      nombre: 'Modalidad 40',
      descripcionDemo:
          'Control por periodo, salario de cotización y pagos mensuales.',
    ),
    ServicioModel(
      id: 41,
      clave: 'm40-retroactiva',
      nombre: 'M40 Retroactiva',
      descripcionDemo: 'Servicio con obligación de pago única.',
    ),
    ServicioModel(
      id: 50,
      clave: 'apd',
      nombre: 'APD',
      descripcionDemo: 'Seguimiento operativo de recursos, cobro y validación.',
    ),
  ];

  static final contracts = <ContratoModel>[
    ContratoModel(
      id: 'demo-contract-1',
      clienteId: 'demo-client-1',
      servicioId: 40,
      asesorId: 'demo-advisor-1',
      folio: 'M40202500001',
      fechaContrato: DateTime(2024, 11, 14),
      estadoContratoId: 1,
      cantidadPagos: 12,
      observaciones: 'Seguimiento al corriente.',
      creadoEn: DateTime(2024, 11, 14, 10),
      clienteNombre: 'Elena Robles Vargas',
      servicioNombre: 'Modalidad 40',
      asesorNombre: 'Daniela Cruz',
      estadoNombre: 'Activo',
      assignedToCurrentAdvisor: true,
    ),
    ContratoModel(
      id: 'demo-contract-2',
      clienteId: 'demo-client-2',
      servicioId: 10,
      asesorId: 'demo-advisor-2',
      folio: 'H3-M10-0391',
      fechaContrato: DateTime(2025, 3, 8),
      estadoContratoId: 1,
      cantidadPagos: 6,
      observaciones: null,
      creadoEn: DateTime(2025, 3, 8, 9),
      clienteNombre: 'Carlos Mendoza Ruiz',
      servicioNombre: 'Modalidad 10',
      asesorNombre: 'Jorge Silva',
      estadoNombre: 'Activo',
    ),
    ContratoModel(
      id: 'demo-contract-3',
      clienteId: 'demo-client-3',
      servicioId: 50,
      asesorId: 'demo-advisor-1',
      folio: 'H3-APD-0182',
      fechaContrato: DateTime(2025, 4, 2),
      estadoContratoId: 2,
      cantidadPagos: null,
      observaciones: 'El flujo APD requiere seguimiento desde pagos.',
      creadoEn: DateTime(2025, 4, 2, 12),
      clienteNombre: 'Sofía Ramírez León',
      servicioNombre: 'APD',
      asesorNombre: 'Daniela Cruz',
      estadoNombre: 'En proceso',
      assignedToCurrentAdvisor: true,
    ),
    ContratoModel(
      id: 'demo-contract-4',
      clienteId: 'demo-client-4',
      servicioId: 41,
      asesorId: 'demo-advisor-3',
      folio: 'H3-R40-0087',
      fechaContrato: DateTime(2025, 5, 16),
      estadoContratoId: 3,
      cantidadPagos: 1,
      observaciones: null,
      creadoEn: DateTime(2025, 5, 16, 11),
      clienteNombre: 'Javier Torres Luna',
      servicioNombre: 'M40 Retroactiva',
      asesorNombre: 'Mónica Ruiz',
      estadoNombre: 'Pago pendiente',
    ),
    ContratoModel(
      id: 'demo-contract-5',
      clienteId: 'demo-client-5',
      servicioId: 40,
      asesorId: 'demo-advisor-2',
      folio: 'H3-M40-0201',
      fechaContrato: DateTime(2024, 8, 1),
      estadoContratoId: 4,
      cantidadPagos: 12,
      observaciones: null,
      creadoEn: DateTime(2024, 8, 1, 9),
      clienteNombre: 'María Salgado Pérez',
      servicioNombre: 'Modalidad 40',
      asesorNombre: 'Jorge Silva',
      estadoNombre: 'Pausado',
    ),
  ];

  static const dataset = DemoDataset(
    module: 'contratos',
    metrics: [
      DemoMetric(label: 'Contratos de muestra', value: '5'),
      DemoMetric(label: 'Servicios', value: '4'),
    ],
    records: [
      DemoRecord(
        id: 'demo-contract-1',
        title: 'M40202500001',
        subtitle: 'Elena Robles Vargas · Modalidad 40',
        status: 'Activo',
      ),
      DemoRecord(
        id: 'demo-contract-2',
        title: 'H3-M10-0391',
        subtitle: 'Carlos Mendoza Ruiz · Modalidad 10',
        status: 'Activo',
      ),
      DemoRecord(
        id: 'demo-contract-3',
        title: 'H3-APD-0182',
        subtitle: 'Sofía Ramírez León · APD',
        status: 'En proceso',
      ),
      DemoRecord(
        id: 'demo-contract-4',
        title: 'H3-R40-0087',
        subtitle: 'Javier Torres Luna · M40 Retroactiva',
        status: 'Pago pendiente',
      ),
      DemoRecord(
        id: 'demo-contract-5',
        title: 'H3-M40-0201',
        subtitle: 'María Salgado Pérez · Modalidad 40',
        status: 'Pausado',
      ),
    ],
    notes: [
      'Los identificadores, folios, estados y relaciones son ficticios para la maqueta.',
      'No se muestran importes, tipo de venta ni seguimiento especializado no disponibles en el DTO.',
    ],
  );
}
