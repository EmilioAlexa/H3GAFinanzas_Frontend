import '../../core/shell/shell_navigation.dart';
import '../../modules/auth/auth.dart';

Set<UserRole> allowedRolesForLocation(String path) {
  if (path == '/validacion' || path.startsWith('/validacion/')) {
    return {UserRole.administrador, UserRole.administradorFinanciero};
  }
  if (path == '/clientes/nuevo') return {UserRole.asesor};
  if (RegExp(r'^/clientes/[^/]+/editar$').hasMatch(path)) {
    return {UserRole.administrador, UserRole.asesor};
  }
  if (path == '/comisiones/receptores' ||
      RegExp(r'^/comisiones/contratos/[^/]+/configuracion$').hasMatch(path)) {
    return {UserRole.administrador, UserRole.administradorFinanciero};
  }
  if (path == '/cortes' || RegExp(r'^/cortes/[^/]+').hasMatch(path)) {
    return {UserRole.administrador, UserRole.administradorFinanciero};
  }
  return allowedRolesForRoute(path);
}
