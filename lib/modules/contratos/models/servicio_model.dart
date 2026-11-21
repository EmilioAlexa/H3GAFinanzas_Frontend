class ServicioModel {
  const ServicioModel({
    required this.id,
    required this.clave,
    required this.nombre,
    required this.descripcionDemo,
  });

  factory ServicioModel.fromJson(Map<String, dynamic> json) => ServicioModel(
        id: json['id'] as int,
        clave: routeKey(
            json['codigo_folio'] as String? ?? json['nombre'] as String,
            json['id'] as int),
        nombre: json['nombre'] as String,
        descripcionDemo: json['descripcion'] as String? ?? '',
      );

  // Routes use presentation aliases, never numeric fixture IDs.
  static String routeKey(String name, int id) {
    final normalized = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (normalized == 'apd') return 'apd';
    if (normalized == 'm10' || normalized == 'modalidad10') return 'm10';
    if (normalized == 'm40' || normalized == 'modalidad40') return 'm40';
    if (['m40r', 'm40retroactiva', 'modalidad40retroactiva']
        .contains(normalized)) {
      return 'm40-retroactiva';
    }
    return id.toString();
  }

  final int id;
  final String clave;
  final String nombre;

  /// Presentation copy from Figma. It is not part of the service DTO.
  final String descripcionDemo;
}
