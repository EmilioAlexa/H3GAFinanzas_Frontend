import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../modules/auth/auth.dart';
import '../responsive/responsive.dart';
import '../responsive/window_size_class.dart';
import 'shell_item.dart';

const shellItems = <ShellItem>[
  ShellItem('Dashboard', '/dashboard', {}),
  ShellItem('Clientes', '/clientes', {}),
  ShellItem('Contratos', '/contratos', {}),
  ShellItem('Pagos', '/pagos', {}),
  ShellItem('Validación', '/validacion', {}),
  ShellItem('Comisiones', '/comisiones', {}),
  ShellItem('Cortes', '/cortes', {
    UserRole.administrador,
    UserRole.administradorFinanciero,
  }),
  ShellItem('Prenómina', '/prenomina', {
    UserRole.administrador,
    UserRole.administradorFinanciero,
  }),
  ShellItem('Reportes', '/reportes', {
    UserRole.administrador,
    UserRole.administradorFinanciero,
  }),
  ShellItem('Usuarios', '/usuarios', {UserRole.administrador}),
];

class AppShell extends ConsumerWidget {
  const AppShell({required this.session, required this.child, super.key});
  final AuthSessionModel session;
  final Widget child;

  List<ShellItem> get _items => shellItems
      .where((item) => item.roles.isEmpty || item.roles.contains(session.role))
      .toList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Responsive.classify(constraints.maxWidth);
        final items = _items;
        final selected = items.indexWhere(
          (item) => item.path == GoRouterState.of(context).uri.path,
        );
        final selectedIndex = selected < 0 ? 0 : selected;
        return Scaffold(
          appBar: AppBar(
            title: const Text('H3GA Finanzas'),
            actions: [
              IconButton(
                tooltip: 'Cerrar sesión',
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).logout(),
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          drawer: size == WindowSizeClass.compacto
              ? Drawer(child: _navigation(context, items, selectedIndex))
              : null,
          body: Row(
            children: [
              if (size == WindowSizeClass.expandido)
                SizedBox(
                  width: 240,
                  child: _navigation(context, items, selectedIndex),
                ),
              if (size == WindowSizeClass.medio)
                NavigationRail(
                  selectedIndex: selectedIndex,
                  labelType: NavigationRailLabelType.selected,
                  destinations: [
                    for (final item in items)
                      NavigationRailDestination(
                        icon: const Icon(Icons.circle_outlined),
                        label: Text(item.label),
                      ),
                  ],
                  onDestinationSelected: (index) =>
                      context.go(items[index].path),
                ),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }

  Widget _navigation(
    BuildContext context,
    List<ShellItem> items,
    int selectedIndex,
  ) =>
      ListView(
        children: [
          for (var index = 0; index < items.length; index++)
            ListTile(
              title: Text(items[index].label),
              selected: selectedIndex == index,
              onTap: () {
                Navigator.of(context).maybePop();
                context.go(items[index].path);
              },
            ),
        ],
      );
}
