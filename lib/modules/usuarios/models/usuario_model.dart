class UsuarioModel {
  const UsuarioModel({
    required this.id,
    required this.nombre,
    required this.apellidoPaterno,
    this.apellidoMaterno,
    required this.correo,
    required this.rolId,
    required this.rolNombre,
    required this.activo,
    required this.fechaCreacion,
    this.ultimoAccesoDemo,
  });

  final String id;
  final String nombre;
  final String apellidoPaterno;
  final String? apellidoMaterno;
  final String correo;
  final String rolId;
  final String rolNombre;
  final bool activo;
  final DateTime fechaCreacion;
  final String? ultimoAccesoDemo;

  factory UsuarioModel.fromApi(Map<String, dynamic> json) {
    final role = json['roles'] is Map
        ? (json['roles'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final roleId = role['id'] ?? json['rol_id'];
    final date = json['fecha_creacion'];
    final createdAt = date is String ? DateTime.tryParse(date) : null;
    if (createdAt == null) {
      throw const FormatException(
        'La respuesta de usuario no contiene una fecha_creacion válida.',
      );
    }
    return UsuarioModel(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      apellidoPaterno: json['apellido_paterno'] as String? ?? '',
      apellidoMaterno: json['apellido_materno'] as String?,
      correo: json['correo_electronico'] as String? ?? '',
      rolId: roleId?.toString() ?? '',
      rolNombre: role['nombre'] as String? ?? '',
      activo: json['activo'] as bool? ?? false,
      fechaCreacion: createdAt,
    );
  }

  String get nombreCompleto => [nombre, apellidoPaterno, apellidoMaterno]
      .whereType<String>()
      .where((parte) => parte.trim().isNotEmpty)
      .join(' ');

  String get iniciales {
    final partes = nombreCompleto.split(' ');
    return partes.take(2).map((parte) => parte[0].toUpperCase()).join();
  }

  UsuarioModel copyWith({
    String? nombre,
    String? apellidoPaterno,
    String? apellidoMaterno,
    String? correo,
    String? rolId,
    String? rolNombre,
    bool? activo,
  }) =>
      UsuarioModel(
        id: id,
        nombre: nombre ?? this.nombre,
        apellidoPaterno: apellidoPaterno ?? this.apellidoPaterno,
        apellidoMaterno: apellidoMaterno ?? this.apellidoMaterno,
        correo: correo ?? this.correo,
        rolId: rolId ?? this.rolId,
        rolNombre: rolNombre ?? this.rolNombre,
        activo: activo ?? this.activo,
        fechaCreacion: fechaCreacion,
        ultimoAccesoDemo: ultimoAccesoDemo,
      );
}
