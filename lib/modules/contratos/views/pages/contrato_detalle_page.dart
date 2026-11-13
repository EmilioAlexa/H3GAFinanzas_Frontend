import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/env.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_notice.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../../auth/auth.dart';
import '../../controllers/contratos_controller.dart';
import '../../models/contrato_model.dart';

class ContratoDetallePage extends ConsumerWidget {
  const ContratoDetallePage({required this.contratoId, super.key});

  final String contratoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return auth.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const AppStatePanel(
        icon: Icons.lock_outline,
        title: 'No se pudo cargar la sesión',
        message: 'Vuelve a iniciar sesión para consultar el contrato.',
      ),
      data: (session) {
        if (session == null) {
          return const AppStatePanel(
            icon: Icons.lock_outline,
            title: 'Inicia sesión para continuar',
            message: 'El detalle requiere una sesión activa.',
          );
        }
        final state = ref.watch(contratosControllerProvider(session.role));
        return state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => AppStatePanel(
            icon: Icons.cloud_off_outlined,
            title: 'No se pudo cargar el contrato',
            message: 'Inténtalo de nuevo.',
            action: TextButton.icon(
              onPressed: () => ref
                  .read(contratosControllerProvider(session.role).notifier)
                  .load(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ),
          data: (contracts) {
            if (contracts == null) {
              return const AppStatePanel(
                icon: Icons.description_outlined,
                title: 'Detalle sin conectar',
                message:
                    'El detalle se conectará con GET /finanzas/contratos/{id} en la etapa B4.',
              );
            }
            final contract =
                contracts.where((item) => item.id == contratoId).firstOrNull;
            if (contract == null) {
              return const AppStatePanel(
                icon: Icons.search_off_outlined,
                title: 'Contrato no disponible',
                message: '',
              );
            }
            return _content(context, contract, session.role);
          },
        );
      },
    );
  }

  Widget _content(
    BuildContext context,
    ContratoModel contract,
    UserRole role,
  ) {
    final canEdit =
        role != UserRole.asesor || contract.assignedToCurrentAdvisor;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextButton.icon(
            onPressed: () => context.go('/contratos'),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Contratos'),
            style: TextButton.styleFrom(alignment: Alignment.centerLeft),
          ),
          AppPageHeader(
            eyebrow: 'Contrato ${contract.folio}',
            title: contract.servicioNombre,
            description:
                '${contract.clienteNombre} · Creado el ${_date(contract.creadoEn)}',
            actions: [
              if (canEdit && AppEnv.demoMode)
                OutlinedButton.icon(
                  onPressed: () =>
                      context.go('/contratos/${contract.id}/editar'),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar observaciones'),
                ),
              OutlinedButton.icon(
                onPressed: () => context.go('/pagos'),
                icon: const Icon(Icons.credit_card_outlined),
                label: const Text('Ver pagos'),
              ),
            ],
          ),
          const AppNotice(
            type: AppNoticeType.warning,
            text:
                'El contrato no contiene importes, mensualidades realizadas, documentos ni historial. El seguimiento específico M10/M40/APD no está definido en la API.',
          ),
          const SizedBox(height: AppTheme.space4),
          Wrap(
            spacing: AppTheme.space4,
            runSpacing: AppTheme.space4,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              SizedBox(
                width: 640,
                child: _infoCard(context, contract),
              ),
              SizedBox(
                width: 320,
                child: _observationsCard(context, contract),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoCard(BuildContext context, ContratoModel contract) => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Información del contrato',
                style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: AppTheme.space6),
            Wrap(
              spacing: AppTheme.space8,
              runSpacing: AppTheme.space5,
              children: [
                _field('Cliente', contract.clienteNombre),
                _field('Asesor', contract.asesorNombre),
                _field('Servicio', contract.servicioNombre),
                _field('Folio', contract.folio),
                _field('Fecha de contrato', _date(contract.fechaContrato)),
                _field('Estado contractual', contract.estadoNombre),
                _field('Cantidad de pagos',
                    contract.cantidadPagos?.toString() ?? 'No especificada'),
              ],
            ),
            const SizedBox(height: AppTheme.space4),
            AppBadge(
                label: contract.estadoNombre,
                tone: _tone(contract.estadoNombre)),
          ],
        ),
      );

  Widget _observationsCard(BuildContext context, ContratoModel contract) =>
      _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Observaciones',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.space3),
            Text(contract.observaciones?.trim().isNotEmpty == true
                ? contract.observaciones!
                : 'Sin observaciones registradas.'),
            const SizedBox(height: AppTheme.space4),
            Text('Creado el ${_date(contract.creadoEn)}',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(AppTheme.space5),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.line),
          borderRadius: BorderRadius.circular(AppTheme.radius),
          boxShadow: AppTheme.elevation,
        ),
        child: child,
      );

  Widget _field(String label, String value) => SizedBox(
        width: 240,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.muted)),
            const SizedBox(height: AppTheme.space1),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );

  AppBadgeTone _tone(String status) => switch (status) {
        'Activo' => AppBadgeTone.success,
        'En proceso' || 'Pago pendiente' => AppBadgeTone.warning,
        'Pausado' => AppBadgeTone.danger,
        _ => AppBadgeTone.neutral,
      };

  String _date(DateTime date) => '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
