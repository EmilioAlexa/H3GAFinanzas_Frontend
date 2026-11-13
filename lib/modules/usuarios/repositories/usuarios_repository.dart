import '../models/usuario_model.dart';
import 'usuarios_repository_exception.dart';

class UsuariosRepository {
  UsuariosRepository({List<UsuarioModel>? initialUsers})
      : _users = List.of(initialUsers ?? demoUsers);

  final List<UsuarioModel> _users;

  static const roles = <({String id, String nombre})>[
    (id: 'demo-role-admin', nombre: 'Administrador'),
    (id: 'demo-role-finanzas', nombre: 'Administrador Financiero'),
    (id: 'demo-role-asesor', nombre: 'Asesor'),
  ];

  List<UsuarioModel> listDemo() => List.unmodifiable(_users);

  Future<UsuarioModel> createDemo({
    required String nombre,
    required String apellidoPaterno,
    required String? apellidoMaterno,
    required String correo,
    required String rolId,
    required String contrasena,
  }) async {
    if (_users
        .any((user) => user.correo.toLowerCase() == correo.toLowerCase())) {
      throw const UsuariosRepositoryException('Ese correo ya está registrado.');
    }
    if (contrasena.length < 8) {
      throw const UsuariosRepositoryException(
        'La contraseña debe tener al menos 8 caracteres.',
      );
    }
    final role = roles.where((item) => item.id == rolId).firstOrNull;
    if (role == null) {
      throw const UsuariosRepositoryException('Selecciona un rol válido.');
    }
    final user = UsuarioModel(
      id: 'demo-user-${DateTime.now().microsecondsSinceEpoch}',
      nombre: nombre.trim(),
      apellidoPaterno: apellidoPaterno.trim(),
      apellidoMaterno: _optional(apellidoMaterno),
      correo: correo.trim(),
      rolId: role.id,
      rolNombre: role.nombre,
      activo: true,
      fechaCreacion: DateTime.now(),
      ultimoAccesoDemo: 'Sin accesos',
    );
    _users.insert(0, user);
    return user;
  }

  Future<UsuarioModel> updateDemo(
    String id, {
    required String nombre,
    required String apellidoPaterno,
    required String? apellidoMaterno,
    required String correo,
  }) async {
    final index = _users.indexWhere((user) => user.id == id);
    if (index < 0) {
      throw const UsuariosRepositoryException('Usuario no encontrado.');
    }
    if (_users.any((user) =>
        user.id != id && user.correo.toLowerCase() == correo.toLowerCase())) {
      throw const UsuariosRepositoryException('Ese correo ya está registrado.');
    }
    final updated = _users[index].copyWith(
      nombre: nombre.trim(),
      apellidoPaterno: apellidoPaterno.trim(),
      apellidoMaterno: _optional(apellidoMaterno),
      correo: correo.trim(),
    );
    _users[index] = updated;
    return updated;
  }

  Future<UsuarioModel> changeRoleDemo(String id, String rolId) async {
    final role = roles.where((item) => item.id == rolId).firstOrNull;
    final index = _users.indexWhere((user) => user.id == id);
    if (index < 0 || role == null) {
      throw const UsuariosRepositoryException('Usuario o rol no válido.');
    }
    _users[index] =
        _users[index].copyWith(rolId: role.id, rolNombre: role.nombre);
    return _users[index];
  }

  Future<UsuarioModel> changeStatusDemo(String id, bool active) async {
    final index = _users.indexWhere((user) => user.id == id);
    if (index < 0) {
      throw const UsuariosRepositoryException('Usuario no encontrado.');
    }
    _users[index] = _users[index].copyWith(activo: active);
    return _users[index];
  }

  static String? _optional(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();

  static final demoUsers = <UsuarioModel>[
    UsuarioModel(
        id: 'demo-user-1',
        nombre: 'Lucía',
        apellidoPaterno: 'Méndez',
        apellidoMaterno: 'Soto',
        correo: 'lucia.mendez@h3ga.local',
        rolId: 'demo-role-admin',
        rolNombre: 'Administrador',
        activo: true,
        fechaCreacion: DateTime(2026, 1, 14),
        ultimoAccesoDemo: 'Hoy · 09:42'),
    UsuarioModel(
        id: 'demo-user-2',
        nombre: 'Joyce',
        apellidoPaterno: 'Mabel',
        correo: 'joyce.mabel@h3ga.local',
        rolId: 'demo-role-finanzas',
        rolNombre: 'Administrador Financiero',
        activo: true,
        fechaCreacion: DateTime(2026, 2, 10),
        ultimoAccesoDemo: 'Hoy · 08:15'),
    UsuarioModel(
        id: 'demo-user-3',
        nombre: 'Daniela',
        apellidoPaterno: 'Cruz',
        correo: 'daniela.cruz@h3ga.local',
        rolId: 'demo-role-asesor',
        rolNombre: 'Asesor',
        activo: true,
        fechaCreacion: DateTime(2026, 3, 2),
        ultimoAccesoDemo: 'Ayer · 18:26'),
    UsuarioModel(
        id: 'demo-user-4',
        nombre: 'Jorge',
        apellidoPaterno: 'Silva',
        correo: 'jorge.silva@h3ga.local',
        rolId: 'demo-role-asesor',
        rolNombre: 'Asesor',
        activo: true,
        fechaCreacion: DateTime(2026, 3, 18),
        ultimoAccesoDemo: 'Sin accesos'),
    UsuarioModel(
        id: 'demo-user-5',
        nombre: 'Mónica',
        apellidoPaterno: 'Ruiz',
        correo: 'monica.ruiz@h3ga.local',
        rolId: 'demo-role-asesor',
        rolNombre: 'Asesor',
        activo: false,
        fechaCreacion: DateTime(2026, 4, 6),
        ultimoAccesoDemo: '12 may. · 16:04'),
    UsuarioModel(
        id: 'demo-user-6',
        nombre: 'Ricardo',
        apellidoPaterno: 'Treviño',
        correo: 'ricardo.trevino@h3ga.local',
        rolId: 'demo-role-asesor',
        rolNombre: 'Asesor',
        activo: true,
        fechaCreacion: DateTime(2026, 5, 1),
        ultimoAccesoDemo: 'Hoy · 07:58'),
    UsuarioModel(
        id: 'demo-user-7',
        nombre: 'Paola',
        apellidoPaterno: 'Garza',
        correo: 'paola.garza@h3ga.local',
        rolId: 'demo-role-asesor',
        rolNombre: 'Asesor',
        activo: true,
        fechaCreacion: DateTime(2026, 5, 12),
        ultimoAccesoDemo: 'Ayer · 19:10'),
  ];
}
