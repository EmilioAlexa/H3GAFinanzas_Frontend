import '../../modules/auth/auth.dart';

String? routeGuard({
  required String location,
  required AuthSessionModel? session,
  required bool loading,
  required Set<UserRole> allowedRoles,
}) {
  if (location == '/login') {
    return session == null ? null : '/dashboard';
  }
  if (loading) {
    return null;
  }
  if (session == null) {
    return '/login';
  }
  if (allowedRoles.isNotEmpty && !allowedRoles.contains(session.role)) {
    return '/dashboard';
  }
  return null;
}
