import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_notice.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../../auth/auth.dart';
import '../../controllers/contratos_controller.dart';
import '../../controllers/servicios_controller.dart';
import '../../models/contrato_model.dart';
import '../../models/servicio_model.dart';

class ServicioDetallePage extends ConsumerWidget {
  const ServicioDetallePage({required this.servicioClave, super.key});

  final String servicioClave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceState = ref.watch(serviciosControllerProvider);
    final auth = ref.watch(authControllerProvider);
    return serviceState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => AppStatePanel(
        icon: Icons.cloud_off_outlined,
        title: 'No se pudo cargar el servicio',
        message: 'Inténtalo de nuevo.',
        action: TextButton.icon(
          onPressed: () =>
              ref.read(serviciosControllerProvider.notifier).load(),
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      ),
      data: (services) {
        if (services == null) {
          return const AppStatePanel(
            icon: Icons.business_center_outlined,
            title: 'Servicio sin conectar',
            message: 'Este detalle requiere el catálogo conectado.',
          );
        }
        final service =
            services.where((item) => item.clave == servicioClave).firstOrNull;
        if (service == null) {
          return const AppStatePanel(
            icon: Icons.search_off_outlined,
            title: 'Servicio no encontrado',
            message: 'Regresa al catálogo de Servicios.',
          );
        }
        return auth.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => const AppStatePanel(
            icon: Icons.lock_outline,
            title: 'No se pudo cargar la sesión',
            message: 'Vuelve a iniciar sesión.',
          ),
          data: (session) {
            if (session == null) {
              return const AppStatePanel(
                icon: Icons.lock_outline,
                title: 'Inicia sesión para continuar',
                message: 'El servicio requiere una sesión activa.',
              );
            }
            final contractsState =
                ref.watch(contratosControllerProvider(session.role));
            return contractsState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => AppStatePanel(
                icon: Icons.cloud_off_outlined,
                title: 'No se pudieron cargar los contratos',
                message: 'Inténtalo de nuevo.',
                action: TextButton.icon(
                  onPressed: () => ref
                      .read(contratosControllerProvider(session.role).notifier)
                      .load(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ),
              data: (contracts) => contracts == null
                  ? const AppStatePanel(
                      icon: Icons.description_outlined,
                      title: 'Seguimiento sin conectar',
                      message:
                          'Los contratos de este servicio no están disponibles en modo real.',
                    )
                  : _content(context, service, contracts),
            );
          },
        );
      },
    );
  }

  Widget _content(
    BuildContext context,
    ServicioModel service,
    List<ContratoModel> contracts,
  ) {
    final items =
        contracts.where((item) => item.servicioId == service.id).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextButton.icon(
            onPressed: () => context.go('/servicios'),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Servicios'),
            style: TextButton.styleFrom(alignment: Alignment.centerLeft),
          ),
          AppPageHeader(
            eyebrow: 'Seguimiento de servicio · demo',
            title: service.nombre,
            description: service.descripcionDemo,
            actions: [
              FilledButton.icon(
                onPressed: () => context.go('/contratos'),
                icon: const Icon(Icons.description_outlined),
                label: const Text('Ver contratos'),
              ),
            ],
          ),
          const AppNotice(
            type: AppNoticeType.warning,
            text:
                'El backend no define endpoints ni campos de seguimiento especializados para M10, M40, M40 Retroactiva o APD. Esta vista muestra solo contratos y campos respaldados por OpenAPI.',
          ),
          const SizedBox(height: AppTheme.space4),
          if (items.isEmpty)
            const AppStatePanel(
              icon: Icons.description_outlined,
              title: 'Sin contratos de muestra',
              message:
                  'No hay contratos asignados a este servicio en esta sesión demo.',
            )
          else
            for (final contract in items)
              Card(
                margin: const EdgeInsets.only(bottom: AppTheme.space3),
                child: ListTile(
                  title: Text(contract.folio),
                  subtitle: Text(
                    '${contract.clienteNombre} · ${contract.estadoNombre}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/contratos/${contract.id}'),
                ),
              ),
        ],
      ),
    );
  }
}
