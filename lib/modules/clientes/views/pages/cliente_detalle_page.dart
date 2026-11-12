import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/env.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/responsive/window_size_class.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_notice.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../../auth/auth.dart';
import '../../controllers/clientes_controller.dart';
import '../../models/cliente_model.dart';

class ClienteDetallePage extends ConsumerWidget {
  const ClienteDetallePage({required this.clienteId, super.key});

  final String clienteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return auth.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const AppStatePanel(
        icon: Icons.person_off_outlined,
        title: 'No se pudo cargar la sesión',
        message: 'Vuelve a iniciar sesión para consultar el cliente.',
      ),
      data: (session) {
        if (session == null) {
          return const AppStatePanel(
            icon: Icons.lock_outline,
            title: 'Inicia sesión para continuar',
            message: 'El detalle requiere una sesión activa.',
          );
        }
        return ref.watch(clientesControllerProvider(session.role)).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => AppStatePanel(
                icon: Icons.cloud_off_outlined,
                title: 'No se pudo cargar el cliente',
                message: 'Inténtalo de nuevo.',
                action: TextButton.icon(
                  onPressed: () => ref
                      .read(clientesControllerProvider(session.role).notifier)
                      .load(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ),
              data: (clients) {
                if (clients == null) {
                  return const AppStatePanel(
                    icon: Icons.people_outline,
                    title: 'Detalle sin conectar',
                    message: 'La API de Clientes todavía no está conectada.',
                  );
                }
                final matches = clients.where((item) => item.id == clienteId);
                if (matches.isEmpty) {
                  return const AppStatePanel(
                    icon: Icons.person_search_outlined,
                    title: 'Cliente no disponible',
                    message:
                        'No existe en la muestra o está fuera del alcance de esta sesión.',
                  );
                }
                return _page(context, matches.first, session.role);
              },
            );
      },
    );
  }

  Widget _page(BuildContext context, ClienteModel client, UserRole role) {
    final metadata = client.demoMetadata;
    final canEdit = AppEnv.demoMode &&
        (role == UserRole.administrador ||
            (role == UserRole.asesor &&
                (metadata?.assignedToCurrentAdvisor ?? false)));
    final initials = _initials(client.nombreCompleto);

    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space6,
              AppTheme.space3,
              AppTheme.space6,
              AppTheme.space3,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => context.go('/clientes'),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Clientes'),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppTheme.accentSoft,
                      foregroundColor: AppTheme.primary,
                      child: Text(initials),
                    ),
                    const SizedBox(width: AppTheme.space4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppEnv.demoMode
                                ? 'Cliente · Muestra Figma'
                                : 'Cliente',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: AppTheme.secondaryDark,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: AppTheme.space1),
                          Text(
                            client.nombreCompleto,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: AppTheme.space2),
                          Wrap(
                            spacing: AppTheme.space2,
                            runSpacing: AppTheme.space1,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (metadata != null)
                                AppBadge(
                                  label: '${metadata.status} · demo',
                                  tone: metadata.status == 'Activo'
                                      ? AppBadgeTone.success
                                      : AppBadgeTone.warning,
                                ),
                              if (metadata?.advisorName != null)
                                Text(
                                  'Asesor · demo: ${metadata!.advisorName}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppTheme.muted),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (canEdit)
                      FilledButton.icon(
                        onPressed: () => context.go(
                          '/clientes/${client.id}/editar',
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar'),
                      ),
                  ],
                ),
                if (AppEnv.demoMode) ...[
                  const SizedBox(height: AppTheme.space3),
                  const AppNotice(
                    type: AppNoticeType.info,
                    text:
                        'Los campos marcados “demo” son referencias de Figma; '
                        'la API de Clientes no proporciona esos metadatos.',
                  ),
                ],
              ],
            ),
          ),
          const Material(
            color: AppTheme.surface,
            child: TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Resumen'),
                Tab(text: 'Servicios y contratos'),
                Tab(text: 'Pagos'),
                Tab(text: 'Historial'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _summary(context, client, metadata),
                _relatedModule(
                  context,
                  title: 'Servicios y contratos',
                  message:
                      'Esta etapa muestra el directorio. Los contratos relacionados se conectarán en A5.',
                  route: '/contratos',
                  actionLabel: 'Ir a contratos',
                ),
                _relatedModule(
                  context,
                  title: 'Pagos del cliente',
                  message:
                      'El historial de pagos se conectará al implementar A6.',
                  route: '/pagos',
                  actionLabel: 'Ir a pagos',
                ),
                const AppStatePanel(
                  icon: Icons.history,
                  title: 'Historial no disponible',
                  message:
                      'OpenAPI no define una ruta de actividad o historial para Clientes.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summary(
    BuildContext context,
    ClienteModel client,
    ClienteDemoMetadata? metadata,
  ) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final size = Responsive.classify(constraints.maxWidth);
          final info = _informationCard(context, client, metadata);
          final references = _referencesCard(context, metadata);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.space6),
            child: size == WindowSizeClass.expandido
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: info),
                      const SizedBox(width: AppTheme.space4),
                      Expanded(child: references),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      info,
                      const SizedBox(height: AppTheme.space4),
                      references,
                    ],
                  ),
          );
        },
      );

  Widget _informationCard(
    BuildContext context,
    ClienteModel client,
    ClienteDemoMetadata? metadata,
  ) =>
      _panel(
        context,
        title: 'Información personal',
        child: Wrap(
          spacing: AppTheme.space6,
          runSpacing: AppTheme.space5,
          children: [
            _field('Nombre', client.nombre),
            _field('Apellido paterno', client.apellidoPaterno),
            _field('Apellido materno', client.apellidoMaterno),
            _field('Teléfono', client.telefono),
            _field('Correo electrónico', client.correoElectronico),
            _field('CURP', client.curp),
            _field('RFC', client.rfc),
            if (metadata?.service != null)
              _field('Servicio · demo', metadata!.service),
          ],
        ),
      );

  Widget _referencesCard(
    BuildContext context,
    ClienteDemoMetadata? metadata,
  ) =>
      Column(
        children: [
          _panel(
            context,
            title: 'Accesos rápidos',
            child: Column(
              children: [
                _quickLink(
                  context,
                  icon: Icons.description_outlined,
                  label: 'Contratos',
                  route: '/contratos',
                ),
                const Divider(),
                _quickLink(
                  context,
                  icon: Icons.credit_card_outlined,
                  label: 'Pagos',
                  route: '/pagos',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          _panel(
            context,
            title: 'Resumen financiero',
            child: const Text(
              'El API de Clientes no devuelve contratos, pagos ni saldos. '
              'Consulta esos módulos para ver la información cuando estén conectados.',
            ),
          ),
          if (metadata?.advisorName != null) ...[
            const SizedBox(height: AppTheme.space4),
            _panel(
              context,
              title: 'Asignación de demo',
              child: Text('Asesor de referencia: ${metadata!.advisorName}'),
            ),
          ],
        ],
      );

  Widget _relatedModule(
    BuildContext context, {
    required String title,
    required String message,
    required String route,
    required String actionLabel,
  }) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space6),
          child: AppStatePanel(
            icon: Icons.open_in_new,
            title: title,
            message: message,
            action: OutlinedButton.icon(
              onPressed: () => context.go(route),
              icon: const Icon(Icons.arrow_forward),
              label: Text(actionLabel),
            ),
          ),
        ),
      );

  Widget _quickLink(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
  }) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go(route),
      );

  Widget _panel(
    BuildContext context, {
    required String title,
    required Widget child,
  }) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.space5),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: AppTheme.line),
          boxShadow: AppTheme.elevation,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Divider(height: AppTheme.space6),
            Material(type: MaterialType.transparency, child: child),
          ],
        ),
      );

  Widget _field(String label, String? value) => SizedBox(
        width: 240,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.muted)),
            const SizedBox(height: AppTheme.space1),
            Text(
              value == null || value.isEmpty ? 'No registrado' : value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );

  String _initials(String name) {
    final parts = name.split(' ');
    if (parts.length < 2) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}'
        .toUpperCase();
  }
}
