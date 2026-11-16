typedef ClienteDemoMetadata = ({
  String status,
  String? advisorName,
  String? service,
  bool assignedToCurrentAdvisor,
});

class ClienteModel {
  const ClienteModel({
    required this.id,
    required this.nombre,
    required this.apellidoPaterno,
    this.apellidoMaterno,
    this.telefono,
    this.correoElectronico,
    this.curp,
    this.rfc,
    this.asesorId,
    this.fechaIngreso,
    this.fechaNacimiento,
    this.direccion,
    this.referidoPor,
    this.observaciones,
    this.demoMetadata,
  });

  final String id;
  final String nombre;
  final String apellidoPaterno;
  final String? apellidoMaterno;
  final String? telefono;
  final String? correoElectronico;
  final String? curp;
  final String? rfc;
  final String? asesorId;
  final DateTime? fechaIngreso;
  final DateTime? fechaNacimiento;
  final String? direccion;
  final String? referidoPor;
  final String? observaciones;

  /// Campos de la muestra Figma que no son parte de los DTO actuales.
  final ClienteDemoMetadata? demoMetadata;

  String get nombreCompleto => [
        nombre,
        apellidoPaterno,
        if (apellidoMaterno != null && apellidoMaterno!.isNotEmpty)
          apellidoMaterno!,
      ].join(' ');

  Map<String, Object?> toApiPayload() => {
        'nombre': nombre,
        'apellido_paterno': apellidoPaterno,
        'apellido_materno': apellidoMaterno,
        'telefono': telefono,
        'correo_electronico': correoElectronico,
        'curp': curp,
        'rfc': rfc,
        'fecha_ingreso': fechaIngreso?.toIso8601String(),
        'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
        'direccion': direccion,
        'referido_por': referidoPor,
        'observaciones': observaciones,
      };
}
