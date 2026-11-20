import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/env.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/export/document_export_service.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_data_column.dart';
import '../../../../core/widgets/app_metric_card.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_responsive_collection.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../../auth/auth.dart';
import '../../controllers/contratos_controller.dart';
import '../../controllers/servicios_controller.dart';
import '../../models/contrato_model.dart';
import '../../models/servicio_model.dart';
import '../../repositories/contratos_repository.dart';

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
            title: 'Servicio no disponible',
            message: 'No fue posible consultar este servicio.',
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
        final detailState = AppEnv.demoMode
            ? null
            : ref.watch(servicioDetailProvider(service.id));
        if (detailState != null && detailState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (detailState != null && detailState.hasError) {
          return AppStatePanel(
              icon: Icons.cloud_off_outlined,
              title: 'No se pudo cargar el detalle',
              message: 'Inténtalo de nuevo.',
              action: TextButton(
                  onPressed: () =>
                      ref.invalidate(servicioDetailProvider(service.id)),
                  child: const Text('Reintentar')));
        }
        final selectedService = detailState?.valueOrNull ?? service;
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
                      title: 'Sin seguimientos disponibles',
                      message: 'No fue posible consultar los contratos.',
                    )
                  : _content(context, selectedService, contracts),
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
    final items = contracts.where((e) => e.servicioId == service.id).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBackButton(
            label: 'Servicios',
            onPressed: () => context.go('/servicios'),
          ),
          AppPageHeader(
            eyebrow: 'Seguimiento de servicio',
            title: service.nombre,
            description: service.descripcionDemo,
            actions: [
              FilledButton.icon(
                onPressed: () => _exportService(context, service, items),
                icon: const Icon(Icons.download_outlined),
                label: const Text('Exportar'),
              ),
            ],
          ),
          _serviceMetrics(service),
          const SizedBox(height: AppTheme.space4),
          if (items.isEmpty)
            const AppStatePanel(
              icon: Icons.description_outlined,
              title: 'Sin contratos ',
              message:
                  'No hay contratos asignados a este servicio en esta sesión.',
            )
          else
            Container(
              decoration: BoxDecoration(
                  color: AppTheme.surface,
                  border: Border.all(color: AppTheme.line),
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  boxShadow: AppTheme.elevation),
              child: AppResponsiveCollection<ContratoModel>(
                rows: items,
                columns: [
                  AppDataColumn(
                      label: 'Cliente / folio',
                      value: (item) => Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.clienteNombre),
                                Text(item.folio,
                                    style: const TextStyle(
                                        fontSize: 10, color: AppTheme.muted))
                              ])),
                  AppDataColumn(
                      label: 'Inicio',
                      value: (item) =>
                          Text(MoneyFormatter.formatDate(item.fechaContrato))),
                  AppDataColumn(
                      label: 'Mensualidades',
                      value: (item) =>
                          Text(item.cantidadPagos?.toString() ?? '?')),
                  AppDataColumn(
                      label: 'Estado',
                      value: (item) => Text(item.estadoNombre)),
                ],
                onRowTap: (item) => context.go('/contratos/${item.id}'),
                compactCardBuilder: (context, item) => ListTile(
                    title: Text(item.clienteNombre),
                    subtitle: Text('${item.folio} ? ${item.estadoNombre}'),
                    trailing: const Icon(Icons.chevron_right)),
              ),
            ),
          if (service.clave == 'apd') ...[
            const SizedBox(height: AppTheme.space4),
            _apdPipeline(context),
          ],
        ],
      ),
    );
  }

  Widget _serviceMetrics(ServicioModel service) {
    final values = switch (service.clave) {
      'm10' => const [
          ('Contratos activos', '184', 'Periodo actual'),
          ('Pagos esperados', r'$742,500', 'Este mes'),
          ('Con atraso', '12 contratos', 'Requieren seguimiento'),
        ],
      'm40' => const [
          ('Contratos activos', '248', 'Periodo actual'),
          ('Pagos esperados', r'$742,500', 'Este mes'),
          ('Con atraso', '12 contratos', 'Requieren seguimiento'),
        ],
      'm40-retroactiva' => const [
          ('Contratos activos', '37', 'Periodo actual'),
          ('Pagos esperados', '14', 'Pago único'),
          ('Con atraso', '3 pagos', 'Requieren seguimiento'),
        ],
      _ => const [
          ('Procesos activos', '96', 'En curso'),
          ('Recursos recibidos', r'$2.4 M', 'Periodo actual'),
          ('Cobros pendientes', r'$528,400', '12 clientes'),
        ],
    };
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 600;
      final width = compact ? 210.0 : (constraints.maxWidth - 24) / 3;
      return SingleChildScrollView(
        scrollDirection: compact ? Axis.horizontal : Axis.vertical,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var index = 0; index < values.length; index++)
              SizedBox(
                width: width,
                child: AppMetricCard(
                  label: values[index].$1,
                  value: AppEnv.demoMode ? values[index].$2 : '—',
                  detail: AppEnv.demoMode
                      ? values[index].$3
                      : 'Pendiente de integración',
                  icon: switch (index) {
                    0 => Icons.description_outlined,
                    1 => Icons.account_balance_wallet_outlined,
                    _ => Icons.warning_amber_outlined,
                  },
                  tone: index == 2
                      ? AppMetricTone.warning
                      : AppMetricTone.secondary,
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _apdPipeline(BuildContext context) => Container(
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
            Text(
              'Proceso APD',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppTheme.space4),
            const Row(
              children: [
                _PipelineStep(label: 'Contrato', complete: AppEnv.demoMode),
                _PipelineStep(label: 'Documentos', complete: AppEnv.demoMode),
                _PipelineStep(label: 'Validación', complete: AppEnv.demoMode),
                _PipelineStep(label: 'Recursos', complete: AppEnv.demoMode),
                _PipelineStep(label: 'Cobro', complete: false),
              ],
            ),
          ],
        ),
      );
}

Future<void> _exportService(
  BuildContext context,
  ServicioModel service,
  List<ContratoModel> contracts,
) async {
  final rows = [
    for (final contract in contracts)
      [
        contract.folio,
        contract.clienteNombre,
        contract.asesorNombre,
        contract.estadoNombre,
        contract.montoMensual ?? '—',
      ],
  ];
  try {
    await DocumentExportService.pdf(
      filename: 'servicio-${service.clave}.pdf',
      title: 'H3GA Finanzas · ${service.nombre}',
      subtitle: service.descripcionDemo,
      headers: const [
        'Contrato',
        'Cliente',
        'Asesor',
        'Estado',
        'Monto mensual'
      ],
      rows: rows,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Servicio exportado en PDF.')),
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('No se pudo exportar: $error')));
    }
  }
}

class _PipelineStep extends StatelessWidget {
  const _PipelineStep({required this.label, required this.complete});

  final String label;
  final bool complete;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color:
                        complete ? AppTheme.successBase : AppTheme.lineStrong,
                  ),
                ),
                Icon(
                  complete ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: complete ? AppTheme.successBase : AppTheme.muted,
                  size: 22,
                ),
                Expanded(
                  child: Divider(
                    color:
                        complete ? AppTheme.successBase : AppTheme.lineStrong,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space2),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      );
}

final servicioDetailProvider = FutureProvider.autoDispose
    .family<ServicioModel, int>(
        (ref, id) => ref.watch(contratosRepositoryProvider).serviceDetail(id));
