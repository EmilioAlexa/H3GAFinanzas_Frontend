class ServicioModel {
  const ServicioModel({
    required this.id,
    required this.clave,
    required this.nombre,
    required this.descripcionDemo,
  });

  final int id;
  final String clave;
  final String nombre;

  /// Presentation copy from Figma. It is not part of the service DTO.
  final String descripcionDemo;
}
