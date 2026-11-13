class UsuariosRepositoryException implements Exception {
  const UsuariosRepositoryException(this.message);
  final String message;

  @override
  String toString() => message;
}
