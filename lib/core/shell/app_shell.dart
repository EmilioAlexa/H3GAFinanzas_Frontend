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
  Widget build(BuildContext context, WidgetRef ref) => LayoutBuilder(
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
            appBar: size == WindowSizeClass.compacto
                ? AppBar(
                    title: const Row(children: [
                      Icon(Icons.search, color: AppTheme.muted),
                      SizedBox(width: AppTheme.space2),
                      Expanded(
                        child: Text(
                          'Buscar clientes, contratos o pagos...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AppTheme.faint, fontSize: 14),
                        ),
                      ),
                    ]),
                    actions: [
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: AppTheme.space2),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(Icons.notifications_none_outlined,
                                color: AppTheme.muted),
                            Positioned(
                              right: -1,
                              top: -1,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppTheme.dangerBase,
                                  shape: BoxShape.circle,
                                ),
                                child: SizedBox(width: 7, height: 7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: AppTheme.space3),
                        child: CircleAvatar(
                          radius: 17,
                          backgroundColor: AppTheme.secondarySoft,
                          foregroundColor: AppTheme.primary,
                          child: Text(_initials(session.name)),
                        ),
                      ),
                    ],
                  )
                : null,
            drawer: size == WindowSizeClass.compacto
                ? Drawer(
                    backgroundColor: AppTheme.primary,
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
            bottomNavigationBar: size == WindowSizeClass.compacto
                ? _mobileNavigation(context, items, currentPath)
                : null,
            body: Row(children: [
              if (size == WindowSizeClass.expandido)
                SizedBox(
                  width: 252,
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
                child: Column(children: [
                  if (size != WindowSizeClass.compacto)
                    _desktopTopBar(context, ref, session),
                  if (AppEnv.demoMode) const DemoModeBanner(),
                  Expanded(child: child),
                ]),
              ),
            ]),
          );
        },
      );

  Widget _navigationRail(
    BuildContext context,
    List<ShellItem> items,
    int selectedIndex,
  ) =>
      NavigationRail(
        backgroundColor: AppTheme.primary,
        selectedIndex: selectedIndex,
        labelType: NavigationRailLabelType.none,
        scrollable: true,
        indicatorColor: AppTheme.secondary.withValues(alpha: .14),
        selectedIconTheme: const IconThemeData(color: AppTheme.secondary),
        unselectedIconTheme: IconThemeData(
          color: AppTheme.white.withValues(alpha: .66),
        ),
        leading: const Padding(
          padding: EdgeInsets.only(
            top: AppTheme.space3,
            bottom: AppTheme.space4,
          ),
          child: Image(
            image: AssetImage('assets/images/h3ga_logo.png'),
            width: 38,
            height: 38,
            semanticLabel: 'H3GA Finanzas',
          ),
        ),
        destinations: [
          for (final item in items)
            NavigationRailDestination(
              icon: Tooltip(message: item.label, child: Icon(item.icon)),
              selectedIcon: Icon(item.icon),
              label: Text(item.label),
            ),
        ],
        onDestinationSelected: (index) => context.go(items[index].path),
      );

  Widget _mobileNavigation(
    BuildContext context,
    List<ShellItem> items,
    String currentPath,
  ) {
    const primaryPaths = ['/dashboard', '/clientes', '/servicios', '/pagos'];
    final selected = primaryPaths.indexWhere(
        (path) => currentPath == path || currentPath.startsWith('$path/'));
    return BottomNavigationBar(
      currentIndex: selected < 0 ? 4 : selected,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Clientes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.business_center_outlined),
          activeIcon: Icon(Icons.business_center),
          label: 'Servicios',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.credit_card_outlined),
          activeIcon: Icon(Icons.credit_card),
          label: 'Pagos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu),
          activeIcon: Icon(Icons.menu),
          label: 'Más',
        ),
      ],
      onTap: (index) {
        if (index < primaryPaths.length) {
          context.go(primaryPaths[index]);
          return;
        }
        _showMoreNavigation(context, items);
      },
    );
  }

  Future<void> _showMoreNavigation(
    BuildContext context,
    List<ShellItem> items,
  ) =>
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: AppTheme.surface,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: AppTheme.space4),
            children: [
              for (final section in ShellSection.values)
                for (final item in items.where((item) =>
                    item.section == section &&
                    !const ['/dashboard', '/clientes', '/servicios', '/pagos']
                        .contains(item.path)))
                  ListTile(
                    leading: Icon(item.icon),
                    title: Text(item.label),
                    onTap: () {
                      Navigator.pop(context);
                      context.go(item.path);
                    },
                  ),
            ],
          ),
        ),
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
      color: AppTheme.primary,
      child: Column(children: [
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
                            color: AppTheme.white.withValues(alpha: .43),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                    ),
                  ),
                  for (final item in groupedItems[section]!)
                    _navigationItem(
                      context,
                      item,
                      selected: item.path == currentPath ||
                          currentPath.startsWith('${item.path}/'),
                      compact: compact,
                    ),
                ],
            ],
          ),
        ),
        _userArea(context, ref, user, compact: compact),
      ]),
    );
  }

  Widget _brandHeader(BuildContext context, bool compact) => Container(
        height: 74,
        padding: const EdgeInsets.fromLTRB(
          AppTheme.space4,
          AppTheme.space3,
          AppTheme.space3,
          AppTheme.space3,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppTheme.white.withValues(alpha: .08)),
          ),
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            child: Image.asset(
              'assets/images/h3ga_logo.png',
              width: 42,
              height: 42,
              fit: BoxFit.contain,
              semanticLabel: 'Logotipo H3GA',
            ),
          ),
          const SizedBox(width: AppTheme.space3),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'H3GA',
                  style: TextStyle(
                    color: AppTheme.white,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Georgia',
                    fontSize: 19,
                    letterSpacing: .7,
                  ),
                ),
                Text(
                  'FINANZAS',
                  style: TextStyle(
                    color: AppTheme.secondary,
                    fontSize: 10,
                    letterSpacing: 2.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (compact)
            IconButton(
              tooltip: 'Cerrar navegación',
              color: AppTheme.white,
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close),
            ),
        ]),
      );

  Widget _navigationItem(
    BuildContext context,
    ShellItem item, {
    required bool selected,
    required bool compact,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space2),
        child: Container(
          height: 43,
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.secondary.withValues(alpha: .15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusField),
            border: Border(
              left: BorderSide(
                color: selected ? AppTheme.secondary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusField),
            onTap: () {
              if (compact) Navigator.of(context).maybePop();
              context.go(item.path);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space3),
              child: Row(children: [
                Icon(
                  item.icon,
                  size: 20,
                  semanticLabel: item.label,
                  color: selected
                      ? AppTheme.secondary
                      : AppTheme.white.withValues(alpha: .65),
                ),
                const SizedBox(width: AppTheme.space3),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? AppTheme.white
                          : AppTheme.white.withValues(alpha: .76),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (item.path == '/validacion')
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppTheme.gold,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '8',
                      style: TextStyle(
                        color: AppTheme.black,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ]),
            ),
          ),
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
      UserRole.administradorFinanciero => 'Admin. financiero',
      UserRole.asesor => 'Asesor',
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space3,
        AppTheme.space2,
        AppTheme.space3,
        AppTheme.space3,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.white.withValues(alpha: .08)),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextButton.icon(
          onPressed: () {
            if (compact) Navigator.of(context).maybePop();
            _logout(ref);
          },
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.white.withValues(alpha: .78),
            alignment: Alignment.centerLeft,
            minimumSize: const Size(48, 44),
          ),
          icon: const Icon(Icons.logout, size: 19),
          label: const Text('Cerrar sesión'),
        ),
        const SizedBox(height: AppTheme.space2),
        Divider(color: AppTheme.white.withValues(alpha: .08), height: 1),
        Padding(
          padding: const EdgeInsets.only(top: AppTheme.space3),
          child: Row(children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: AppTheme.secondary,
              foregroundColor: AppTheme.black,
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
                    style: const TextStyle(
                      color: AppTheme.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    roleText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.white.withValues(alpha: .58),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (AppEnv.demoMode)
              PopupMenuButton<UserRole>(
                tooltip: 'Cambiar perfil de demostración',
                icon: Icon(
                  Icons.expand_more,
                  color: AppTheme.white.withValues(alpha: .68),
                ),
                onSelected: (role) => ref
                    .read(authControllerProvider.notifier)
                    .changeDemoRole(role),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: UserRole.administrador,
                    child: Text('Administrador'),
                  ),
                  PopupMenuItem(
                    value: UserRole.administradorFinanciero,
                    child: Text('Admin. financiero'),
                  ),
                  PopupMenuItem(value: UserRole.asesor, child: Text('Asesor')),
                ],
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _desktopTopBar(
    BuildContext context,
    WidgetRef ref,
    AuthSessionModel user,
  ) {
    final roleText = switch (user.role) {
      UserRole.administrador => 'Administrador',
      UserRole.administradorFinanciero => 'Admin. financiero',
      UserRole.asesor => 'Asesor',
    };
    return Container(
      height: 65,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space6),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: .96),
        border: const Border(bottom: BorderSide(color: AppTheme.line)),
        boxShadow: const [AppTheme.shadowXs],
      ),
      child: Row(children: [
        const Icon(Icons.search, color: AppTheme.faint),
        const SizedBox(width: AppTheme.space3),
        const Expanded(
          child: Text(
            'Buscar clientes, contratos o pagos...',
            style: TextStyle(color: AppTheme.faint, fontSize: 15),
          ),
        ),
        const IconButton(
          tooltip: 'Notificaciones',
          onPressed: null,
          icon: Icon(Icons.notifications_none_outlined),
        ),
        const SizedBox(width: AppTheme.space3),
        const VerticalDivider(indent: 14, endIndent: 14),
        const SizedBox(width: AppTheme.space3),
        CircleAvatar(
          radius: 17,
          backgroundColor: AppTheme.secondarySoft,
          foregroundColor: AppTheme.primary,
          child: Text(_initials(user.name)),
        ),
        const SizedBox(width: AppTheme.space3),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.name,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('Perfil de demostración · $roleText',
                style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
          ],
        ),
        if (AppEnv.demoMode)
          PopupMenuButton<UserRole>(
            tooltip: 'Cambiar perfil de demostración',
            onSelected: (role) =>
                ref.read(authControllerProvider.notifier).changeDemoRole(role),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: UserRole.administrador,
                child: Text('Administrador'),
              ),
              PopupMenuItem(
                value: UserRole.administradorFinanciero,
                child: Text('Admin. financiero'),
              ),
              PopupMenuItem(value: UserRole.asesor, child: Text('Asesor')),
            ],
          ),
      ]),
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
