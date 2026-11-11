import '../../modules/auth/auth.dart';

class ShellItem {
  const ShellItem(this.label, this.path, this.roles);
  final String label;
  final String path;
  final Set<UserRole> roles;
}
