import '../../core/shell/shell_navigation.dart';
import '../../modules/auth/auth.dart';

Set<UserRole> allowedRolesForLocation(String path) {
  if (path == '/clientes/nuevo') return {UserRole.asesor};
  if (RegExp(r'^/clientes/[^/]+/editar$').hasMatch(path)) {
    return {UserRole.administrador, UserRole.asesor};
  }
  return allowedRolesForRoute(path);
}
