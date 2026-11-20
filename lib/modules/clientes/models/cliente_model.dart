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
    this.pausado,
    this.referidoPorClienteId,
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
  final bool? pausado;
  final String? referidoPorClienteId;

  factory ClienteModel.fromJson(Map<String, dynamic> json) => ClienteModel(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        apellidoPaterno: json['apellido_paterno'] as String,
        apellidoMaterno: json['apellido_materno'] as String?,
        telefono: json['telefono'] as String?,
        correoElectronico: json['correo_electronico'] as String?,
        curp: json['curp'] as String?,
        rfc: json['rfc'] as String?,
        asesorId: json['asesor_id'] as String?,
        fechaIngreso: _fechaCivil(json['fecha_ingreso']),
        fechaNacimiento: _fechaCivil(json['fecha_nacimiento']),
        pausado: json['pausado'] as bool?,
        direccion: json['domicilio'] as String?,
        referidoPor: json['referido_por'] as String?,
        referidoPorClienteId: json['referido_por_cliente_id'] as String?,
        observaciones: json['observaciones_generales'] as String?,
      );

  static DateTime? _fechaCivil(Object? value) {
    if (value == null) return null;
    final text = value as String;
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})(?:$|T)').firstMatch(text);
    if (match == null) throw const FormatException('Fecha de cliente inválida');
    return DateTime(
        int.parse(match[1]!), int.parse(match[2]!), int.parse(match[3]!));
  }

  static String _fechaApi(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

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
        if (fechaNacimiento != null)
          'fecha_nacimiento': _fechaApi(fechaNacimiento!),
        'domicilio': direccion,
        'referido_por': referidoPor,
        'observaciones_generales': observaciones,
      };
}
