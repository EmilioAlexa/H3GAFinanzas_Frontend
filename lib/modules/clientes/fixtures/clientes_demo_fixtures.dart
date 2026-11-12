import '../../../core/demo/demo_dataset.dart';
import '../../../core/demo/demo_metric.dart';
import '../../../core/demo/demo_record.dart';
import '../models/cliente_model.dart';

abstract final class ClientesDemoFixtures {
  static const clients = <ClienteModel>[
    ClienteModel(
      id: 'demo-client-1',
      nombre: 'Elena',
      apellidoPaterno: 'Robles',
      apellidoMaterno: 'Vargas',
      telefono: '55 3140 8872',
      correoElectronico: 'elena.robles@email.mx',
      curp: 'ROVE680214MDFBLN08',
      rfc: 'ROVE680214K62',
      demoMetadata: (
        status: 'Activo',
        advisorName: 'Daniela Cruz',
        service: 'Modalidad 40',
        assignedToCurrentAdvisor: true,
      ),
    ),
    ClienteModel(
      id: 'demo-client-2',
      nombre: 'Carlos',
      apellidoPaterno: 'Mendoza',
      apellidoMaterno: 'Ruiz',
      telefono: '55 8201 3490',
      correoElectronico: 'carlos.mendoza@email.mx',
      curp: 'MERC720908HDFNZR04',
      demoMetadata: (
        status: 'Activo',
        advisorName: 'Jorge Silva',
        service: 'Modalidad 10',
        assignedToCurrentAdvisor: false,
      ),
    ),
    ClienteModel(
      id: 'demo-client-3',
      nombre: 'Sofía',
      apellidoPaterno: 'Ramírez',
      apellidoMaterno: 'León',
      telefono: '55 7204 1183',
      correoElectronico: 'sofia.ramirez@email.mx',
      curp: 'RALS650320MDFMNF02',
      demoMetadata: (
        status: 'Seguimiento',
        advisorName: 'Daniela Cruz',
        service: 'APD',
        assignedToCurrentAdvisor: true,
      ),
    ),
    ClienteModel(
      id: 'demo-client-4',
      nombre: 'Javier',
      apellidoPaterno: 'Torres',
      apellidoMaterno: 'Luna',
      telefono: '55 4462 0915',
      correoElectronico: 'javier.torres@email.mx',
      curp: 'TOLJ700711HDFRNV07',
      demoMetadata: (
        status: 'Activo',
        advisorName: 'Mónica Ruiz',
        service: 'M40 Retroactiva',
        assignedToCurrentAdvisor: false,
      ),
    ),
    ClienteModel(
      id: 'demo-client-5',
      nombre: 'María',
      apellidoPaterno: 'Salgado',
      apellidoMaterno: 'Pérez',
      telefono: '55 9301 6274',
      correoElectronico: 'maria.salgado@email.mx',
      curp: 'SAPM691104MDFLNR01',
      demoMetadata: (
        status: 'Pausado',
        advisorName: 'Jorge Silva',
        service: 'Modalidad 40',
        assignedToCurrentAdvisor: false,
      ),
    ),
  ];

  static const dataset = DemoDataset(
    module: 'clientes',
    metrics: [
      DemoMetric(label: 'Clientes de muestra', value: '5'),
      DemoMetric(label: 'Activos demo', value: '3'),
      DemoMetric(label: 'En seguimiento demo', value: '1'),
    ],
    records: [
      DemoRecord(
        id: 'demo-client-1',
        title: 'Elena Robles Vargas',
        subtitle: 'elena.robles@email.mx · 55 3140 8872',
        status: 'Activo · demo',
        details: {'servicio': 'Modalidad 40 · demo'},
      ),
      DemoRecord(
        id: 'demo-client-2',
        title: 'Carlos Mendoza Ruiz',
        subtitle: 'carlos.mendoza@email.mx · 55 8201 3490',
        status: 'Activo · demo',
        details: {'servicio': 'Modalidad 10 · demo'},
      ),
      DemoRecord(
        id: 'demo-client-3',
        title: 'Sofía Ramírez León',
        subtitle: 'sofia.ramirez@email.mx · 55 7204 1183',
        status: 'Seguimiento · demo',
        details: {'servicio': 'APD · demo'},
      ),
      DemoRecord(
        id: 'demo-client-4',
        title: 'Javier Torres Luna',
        subtitle: 'javier.torres@email.mx · 55 4462 0915',
        status: 'Activo · demo',
        details: {'servicio': 'M40 Retroactiva · demo'},
      ),
      DemoRecord(
        id: 'demo-client-5',
        title: 'María Salgado Pérez',
        subtitle: 'maria.salgado@email.mx · 55 9301 6274',
        status: 'Pausado · demo',
        details: {'servicio': 'Modalidad 40 · demo'},
      ),
    ],
    notes: [
      'Todos los nombres y datos personales son ficticios para la maqueta.',
      'Asesor, servicio y estado son metadatos de Figma ausentes en el DTO de Clientes.',
    ],
  );
}
