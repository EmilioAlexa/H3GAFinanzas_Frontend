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
