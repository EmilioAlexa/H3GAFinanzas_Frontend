import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/responsive/window_size_class.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_notice.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../controllers/servicios_controller.dart';
import '../../models/servicio_model.dart';

class ServiciosPage extends ConsumerWidget {
  const ServiciosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(serviciosControllerProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => AppStatePanel(
        icon: Icons.cloud_off_outlined,
        title: 'No se pudo cargar el catálogo',
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
            title: 'Sin servicios disponibles',
            message: 'No fue posible consultar el catálogo de servicios.',
          );
        }
        return _content(context, services, {
          for (final service in services)
            service.id: switch (service.id) {
              10 => 184,
              40 => 248,
              41 => 37,
              50 => 96,
              _ => 0,
            },
        });
      },
    );
  }

  Widget _content(BuildContext context, List<ServicioModel> services,
          Map<int, int?> counts) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppPageHeader(
              eyebrow: 'Catálogo operativo',
              title: 'Servicios',
              description: 'Servicios disponibles y seguimiento especializado.',
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final size = Responsive.of(context);
                final columns = size == WindowSizeClass.compacto
                    ? 1
                    : size == WindowSizeClass.medio
                        ? 2
                        : Responsive.usesDenseLayout(
                            MediaQuery.sizeOf(context).width,
                          )
                            ? 3
                            : 4;
                final spacing = AppTheme.space4;
                final cardWidth =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final service in services)
                      SizedBox(
                        width: cardWidth,
                        child:
                            _serviceCard(context, service, counts[service.id]),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppTheme.space4),
            const AppNotice(
              text:
                  'Condiciones económicas flexibles. Los montos y esquemas de pago se determinan por contrato.',
            ),
          ],
        ),
      );

  Widget _serviceCard(
          BuildContext context, ServicioModel service, int? count) =>
      Container(
        padding: const EdgeInsets.all(AppTheme.space5),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.line),
          borderRadius: BorderRadius.circular(AppTheme.radius),
          boxShadow: AppTheme.elevation,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.all(AppTheme.space3),
                decoration: BoxDecoration(
                  color: service.clave == 'm40-retroactiva'
                      ? AppTheme.goldSoft
                      : AppTheme.secondarySoft,
                  borderRadius: BorderRadius.circular(AppTheme.radiusField),
                ),
                child: Text(
                    service.clave == 'm40-retroactiva'
                        ? 'R40'
                        : service.clave.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: AppTheme.space3),
            const Align(
              alignment: Alignment.centerLeft,
              child: AppBadge(label: 'Activo', tone: AppBadgeTone.success),
            ),
            const SizedBox(height: AppTheme.space3),
            Text(service.nombre, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.space2),
            Text(service.descripcionDemo,
                style: Theme.of(context).textTheme.bodyMedium),
            const Divider(height: AppTheme.space6),
            Row(children: [
              Expanded(
                  child: Text(
                      count == null ? '? contratos' : '$count contratos',
                      style: const TextStyle(
                          color: AppTheme.muted, fontSize: 11))),
              TextButton.icon(
                onPressed: () => context.go('/servicios/${service.clave}'),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Consultar'),
              ),
            ]),
          ],
        ),
      );
}
