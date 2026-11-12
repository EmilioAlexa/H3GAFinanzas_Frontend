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
            title: 'Servicios sin conectar',
            message:
                'La vista usará los servicios activos del catálogo financiero al conectar la etapa B4.',
          );
        }
        return _content(context, services);
      },
    );
  }

  Widget _content(BuildContext context, List<ServicioModel> services) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppPageHeader(
              eyebrow: 'Catálogo operativo',
              title: 'Servicios',
              description:
                  'Tipos de servicio usados para clasificar los contratos.',
            ),
            const AppNotice(
              text:
                  'Servicios y descripciones son una muestra visual. La API devuelve catálogos dinámicos y sus claves reales; el seguimiento M10/M40/APD aún no está definido.',
            ),
            const SizedBox(height: AppTheme.space4),
            LayoutBuilder(
              builder: (context, constraints) {
                final size = Responsive.classify(constraints.maxWidth);
                final columns = size == WindowSizeClass.compacto
                    ? 1
                    : size == WindowSizeClass.medio
                        ? 2
                        : Responsive.usesDenseLayout(constraints.maxWidth)
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
                        child: _serviceCard(context, service),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppTheme.space4),
            const AppNotice(
              type: AppNoticeType.warning,
              text:
                  'No se muestran precios, salarios, fechas de término, pagos hechos ni estados de seguimiento: esos campos no pertenecen al DTO del contrato.',
            ),
          ],
        ),
      );

  Widget _serviceCard(BuildContext context, ServicioModel service) => Container(
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
                  color: AppTheme.accentSoft,
                  borderRadius: BorderRadius.circular(AppTheme.radiusField),
                ),
                child: Text(service.clave.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: AppTheme.space3),
            const Align(
              alignment: Alignment.centerLeft,
              child:
                  AppBadge(label: 'Catálogo · demo', tone: AppBadgeTone.info),
            ),
            const SizedBox(height: AppTheme.space3),
            Text(service.nombre, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.space2),
            Text(service.descripcionDemo,
                style: Theme.of(context).textTheme.bodyMedium),
            const Divider(height: AppTheme.space6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => context.go('/servicios/${service.clave}'),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Consultar'),
              ),
            ),
          ],
        ),
      );
}
