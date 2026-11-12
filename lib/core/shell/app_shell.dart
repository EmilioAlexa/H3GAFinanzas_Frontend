import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/config/env.dart';
import '../../app/theme/app_theme.dart';
import '../../modules/auth/auth.dart';
import '../demo/demo_mode_banner.dart';
import '../responsive/responsive.dart';
import '../responsive/window_size_class.dart';
import 'shell_item.dart';
import 'shell_navigation.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.session, required this.child, super.key});

  final AuthSessionModel session;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Responsive.classify(constraints.maxWidth);
        final items = visibleShellItems(session.role);
        final currentPath = GoRouterState.of(context).uri.path;
        final selectedIndex = items.indexWhere(
          (item) =>
              item.path == currentPath ||
              currentPath.startsWith('${item.path}/'),
        );
        final safeSelectedIndex = selectedIndex < 0 ? 0 : selectedIndex;

        return Scaffold(
          appBar: AppBar(
            title: Text(_titleFor(items, currentPath)),
            automaticallyImplyLeading: size == WindowSizeClass.compacto,
            actions: [
              IconButton(
                tooltip: 'Cerrar sesión',
                onPressed: () => _logout(ref),
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          drawer: size == WindowSizeClass.compacto
              ? Drawer(
                  child: SafeArea(
                    child: _fullNavigation(
                      context,
                      ref,
                      items,
                      currentPath,
                      session,
                      compact: true,
                    ),
                  ),
                )
              : null,
          body: Row(
            children: [
              if (size == WindowSizeClass.expandido)
                SizedBox(
                  width: 264,
                  child: _fullNavigation(
                    context,
                    ref,
                    items,
                    currentPath,
                    session,
                    compact: false,
                  ),
                ),
              if (size == WindowSizeClass.medio)
                _navigationRail(context, items, safeSelectedIndex),
              Expanded(
                child: Column(
                  children: [
                    if (AppEnv.demoMode) const DemoModeBanner(),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _titleFor(List<ShellItem> items, String path) {
    for (final item in items) {
      if (item.path == path || path.startsWith('${item.path}/')) {
        return item.label;
      }
    }
    return 'H3GA Finanzas';
  }

  Widget _navigationRail(
    BuildContext context,
    List<ShellItem> items,
    int selectedIndex,
  ) =>
      NavigationRail(
        backgroundColor: AppTheme.surface,
        selectedIndex: selectedIndex,
        labelType: NavigationRailLabelType.none,
        scrollable: true,
        leading: const Padding(
          padding:
              EdgeInsets.only(top: AppTheme.space3, bottom: AppTheme.space4),
          child: Icon(Icons.account_balance_outlined, color: AppTheme.primary),
        ),
        destinations: [
          for (final item in items)
            NavigationRailDestination(
              icon: Tooltip(
                message: item.label,
                child: Icon(item.icon),
              ),
              selectedIcon: Icon(item.icon),
              label: Text(item.label),
            ),
        ],
        onDestinationSelected: (index) => context.go(items[index].path),
      );

  Widget _fullNavigation(
    BuildContext context,
    WidgetRef ref,
    List<ShellItem> items,
    String currentPath,
    AuthSessionModel user, {
    required bool compact,
  }) {
    final groupedItems = <ShellSection, List<ShellItem>>{};
    for (final item in items) {
      groupedItems.putIfAbsent(item.section, () => []).add(item);
    }

    return ColoredBox(
      color: AppTheme.surface,
      child: Column(
        children: [
          _brandHeader(context, compact),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.space2),
              children: [
                for (final section in ShellSection.values)
                  if (groupedItems[section]?.isNotEmpty ?? false) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.space4,
                        AppTheme.space3,
                        AppTheme.space3,
                        AppTheme.space1,
                      ),
                      child: Text(
                        _sectionLabel(section).toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.muted,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.7,
                            ),
                      ),
                    ),
                    for (final item in groupedItems[section]!)
                      _navigationItem(
                        context,
                        item,
                        selected: item.path == currentPath,
                        compact: compact,
                      ),
                  ],
              ],
            ),
          ),
          const Divider(height: 1),
          _userArea(context, ref, user, compact: compact),
        ],
      ),
    );
  }

  Widget _brandHeader(BuildContext context, bool compact) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.space4,
          AppTheme.space4,
          AppTheme.space3,
          AppTheme.space3,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              child: Image.asset(
                'assets/images/h3ga_logo.png',
                width: 42,
                height: 42,
                fit: BoxFit.cover,
                semanticLabel: 'Logotipo H3GA',
              ),
            ),
            const SizedBox(width: AppTheme.space3),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('H3GA', style: TextStyle(fontWeight: FontWeight.w700)),
                  Text('Finanzas'),
                ],
              ),
            ),
            if (compact)
              IconButton(
                tooltip: 'Cerrar navegación',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close),
              ),
          ],
        ),
      );

  Widget _navigationItem(
    BuildContext context,
    ShellItem item, {
    required bool selected,
    required bool compact,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space2),
        child: ListTile(
          minLeadingWidth: AppTheme.space6,
          selected: selected,
          selectedColor: AppTheme.primary,
          selectedTileColor: AppTheme.accentSoft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusField),
          ),
          leading: Icon(item.icon, semanticLabel: item.label),
          title: Text(item.label),
          onTap: () {
            if (compact) Navigator.of(context).maybePop();
            context.go(item.path);
          },
        ),
      );

  Widget _userArea(
    BuildContext context,
    WidgetRef ref,
    AuthSessionModel user, {
    required bool compact,
  }) {
    final roleText = switch (user.role) {
      UserRole.administrador => 'Administrador',
      UserRole.administradorFinanciero => 'Administrador financiero',
      UserRole.asesor => 'Asesor',
    };

    return Padding(
      padding: const EdgeInsets.all(AppTheme.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.accentSoft,
                foregroundColor: AppTheme.primary,
                child: Text(_initials(user.name)),
              ),
              const SizedBox(width: AppTheme.space2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      roleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (AppEnv.demoMode) ...[
            const SizedBox(height: AppTheme.space2),
            DropdownButtonFormField<UserRole>(
              key: ValueKey(user.role),
              initialValue: user.role,
              decoration: const InputDecoration(
                labelText: 'Perfil de demostración',
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(
                  value: UserRole.administrador,
                  child: Text('Administrador'),
                ),
                DropdownMenuItem(
                  value: UserRole.administradorFinanciero,
                  child: Text('Admin. financiero'),
                ),
                DropdownMenuItem(value: UserRole.asesor, child: Text('Asesor')),
              ],
              onChanged: (role) {
                if (role != null) {
                  ref
                      .read(authControllerProvider.notifier)
                      .changeDemoRole(role);
                }
              },
            ),
          ],
          const SizedBox(height: AppTheme.space1),
          TextButton.icon(
            onPressed: () {
              if (compact) Navigator.of(context).maybePop();
              _logout(ref);
            },
            icon: const Icon(Icons.logout),
            label: const Align(
              alignment: Alignment.centerLeft,
              child: Text('Cerrar sesión'),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  String _sectionLabel(ShellSection section) => switch (section) {
        ShellSection.general => 'General',
        ShellSection.seguimiento => 'Seguimiento',
        ShellSection.finanzas => 'Finanzas',
        ShellSection.administracion => 'Administración',
      };

  void _logout(WidgetRef ref) =>
      ref.read(authControllerProvider.notifier).logout();
}
