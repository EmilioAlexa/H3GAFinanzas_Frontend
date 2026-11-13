import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/responsive/window_size_class.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_metric_card.dart';
import '../../../../core/widgets/app_notice.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../../auth/auth.dart';
import '../../controllers/cortes_controller.dart';
import '../../models/cut_model.dart';
import '../../models/cut_movement_model.dart';
import '../../utils/cut_period_formatter.dart';

class CortePreparacionPage extends ConsumerWidget {
  const CortePreparacionPage({required this.cutId, super.key});
  final String cutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    if (session == null || session.role == UserRole.asesor) {
      return const AppStatePanel(
        icon: Icons.lock_outline,
        title: 'Acceso restringido',
        message: 'Solo administración consulta la preparación de cortes.',
      );
    }
    return ref.watch(cortesControllerProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => const AppStatePanel(
            icon: Icons.cloud_off_outlined,
            title: 'No se pudo cargar la preparación',
            message: 'Vuelve al listado e inténtalo de nuevo.',
          ),
          data: (cuts) {
            final cut = ref.read(cortesControllerProvider.notifier).find(cutId);
            if (cuts == null) {
              return const AppStatePanel(
                icon: Icons.link_off,
                title: 'Preparación sin conectar',
                message: 'La vista previa real se integra en B8.',
              );
            }
            if (cut == null) {
              return const AppStatePanel(
                icon: Icons.search_off_outlined,
                title: 'Corte no disponible',
                message: 'El corte no existe en el conjunto demo.',
              );
            }
            return _content(context, ref, session, cut);
          },
        );
  }

  Widget _content(
    BuildContext context,
    WidgetRef ref,
    AuthSessionModel session,
    CutModel cut,
  ) {
    final included = cut.movements.where((item) => item.included).toList();
    final excluded = cut.movements.where((item) => !item.included).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextButton.icon(
          onPressed: () => context.go('/cortes'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Cortes financieros'),
          style: TextButton.styleFrom(alignment: Alignment.centerLeft),
        ),
        AppPageHeader(
          eyebrow: 'Preparación de corte · ${cut.folio}',
          title: CutPeriodFormatter.label(
            cut.periodStart,
            cut.periodEndExclusive,
          ),
          description: 'Periodo viernes a jueves · Información de demostración',
          actions: [
            AppBadge(label: cut.status, tone: AppBadgeTone.warning),
          ],
        ),
        const AppNotice(
          text:
              'Vista previa de ejemplo. La API calcula los pagos elegibles, exclusiones y comisiones en cada periodo; estos importes no vienen del backend.',
        ),
        const SizedBox(height: AppTheme.space4),
        _metrics(cut),
        const SizedBox(height: AppTheme.space4),
        LayoutBuilder(builder: (context, constraints) {
          final expanded = Responsive.classify(constraints.maxWidth) ==
              WindowSizeClass.expandido;
          final includedPanel = _movementPanel(
            context,
            title: 'Movimientos incluidos',
            description: 'Pagos validados dentro del periodo',
            movements: included,
            count: cut.includedCount,
            tone: AppBadgeTone.success,
            included: true,
          );
          final excludedPanel = _movementPanel(
            context,
            title: 'Movimientos excluidos',
            description: 'Requieren atención antes de avanzar',
            movements: excluded,
            count: cut.excludedCount,
            tone: AppBadgeTone.warning,
            included: false,
          );
          if (expanded) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: includedPanel),
                const SizedBox(width: AppTheme.space4),
                SizedBox(width: 360, child: excludedPanel),
              ],
            );
          }
          return Column(children: [
            includedPanel,
            const SizedBox(height: AppTheme.space4),
            excludedPanel,
          ]);
        }),
        const SizedBox(height: AppTheme.space4),
        if (cut.status == 'En preparación')
          _actionBanner(context, ref, session, cut),
        if (cut.status != 'En preparación')
          AppNotice(
            text: cut.status == 'Abierto'
                ? 'El corte ya está abierto. Revisa el detalle para cerrarlo o cancelarlo.'
                : 'Este corte ya no está en preparación. Su estado actual es ${cut.status}.',
          ),
      ]),
    );
  }

  Widget _metrics(CutModel cut) => LayoutBuilder(
        builder: (context, constraints) {
          final count = constraints.maxWidth >= 900
              ? 4
              : constraints.maxWidth >= 560
                  ? 2
                  : 1;
          final cardWidth = (constraints.maxWidth - (count - 1) * 12) / count;
          final cards = [
            AppMetricCard(
              label: 'Ingresos validados',
              value: MoneyFormatter.format(cut.totalAmount),
              detail: '${cut.includedCount + cut.excludedCount} movimientos',
              icon: Icons.bar_chart_outlined,
            ),
            AppMetricCard(
              label: 'Incluidos',
              value: '${cut.includedCount}',
              detail: MoneyFormatter.format(cut.includedAmount),
              icon: Icons.check_circle_outline,
              tone: AppMetricTone.info,
            ),
            AppMetricCard(
              label: 'Excluidos',
              value: '${cut.excludedCount}',
              detail: MoneyFormatter.format(cut.excludedAmount),
              icon: Icons.warning_amber_outlined,
              tone: AppMetricTone.warning,
            ),
            AppMetricCard(
              label: 'Comisiones relacionadas',
              value: MoneyFormatter.format(cut.commissionAmount),
              detail: '${cut.advisorCount} asesores',
              icon: Icons.business_center_outlined,
              tone: AppMetricTone.accent,
            ),
          ];
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final card in cards) SizedBox(width: cardWidth, child: card),
            ],
          );
        },
      );

  Widget _movementPanel(
    BuildContext context, {
    required String title,
    required String description,
    required List<CutMovementModel> movements,
    required int count,
    required AppBadgeTone tone,
    required bool included,
  }) =>
      Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: AppTheme.line),
          boxShadow: AppTheme.elevation,
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.space4),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                )),
                    const SizedBox(height: AppTheme.space1),
                    Text(description,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppTheme.muted)),
                  ],
                ),
              ),
              AppBadge(
                  label: '$count ${included ? 'incluidos' : 'excluidos'}',
                  tone: tone),
            ]),
          ),
          const Divider(height: 1),
          if (movements.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppTheme.space6),
              child: Text(
                included
                    ? 'No hay movimientos incluidos en este corte demo.'
                    : 'No hay exclusiones para mostrar.',
                style: const TextStyle(color: AppTheme.muted),
              ),
            )
          else
            for (final movement in movements) _movementTile(movement, included),
        ]),
      );

  Widget _movementTile(CutMovementModel movement, bool included) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space4,
          vertical: AppTheme.space3,
        ),
        child: Row(children: [
          Container(
            constraints: const BoxConstraints(minWidth: 58, minHeight: 42),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(AppTheme.space2),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSecondary,
              borderRadius: BorderRadius.circular(AppTheme.radiusField),
            ),
            child: Text(CutPeriodFormatter.dateChip(movement.paymentDate),
                style: const TextStyle(
                  color: AppTheme.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                )),
          ),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  movement.included
                      ? movement.clientName
                      : movement.exclusionReason ?? 'Excluido',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(
                '${movement.paymentFolio} · ${movement.serviceName}${included ? '' : ' · ${movement.clientName}'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.muted, fontSize: 12),
              ),
            ]),
          ),
          const SizedBox(width: AppTheme.space2),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(MoneyFormatter.format(movement.amount),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            if (!included)
              const Text('Revisión',
                  style: TextStyle(color: AppTheme.muted, fontSize: 11)),
          ]),
        ]),
      );

  Widget _actionBanner(
    BuildContext context,
    WidgetRef ref,
    AuthSessionModel session,
    CutModel cut,
  ) =>
      Container(
        padding: const EdgeInsets.all(AppTheme.space4),
        decoration: BoxDecoration(
          color: AppTheme.secondarySoft,
          border: Border.all(color: AppTheme.secondaryTint),
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          spacing: AppTheme.space4,
          runSpacing: AppTheme.space3,
          children: [
            const SizedBox(
              width: 380,
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.warning_amber_outlined,
                    color: AppTheme.secondaryDark),
                SizedBox(width: AppTheme.space3),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Confirmación demostrativa',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        SizedBox(height: AppTheme.space1),
                        Text(
                            'Generar abrirá el corte en esta maqueta. No se registrará información real.'),
                      ]),
                ),
              ]),
            ),
            FilledButton.icon(
              onPressed: () => _confirmTransition(
                context,
                ref,
                session,
                cut,
                action: 'generar',
                title: 'Generar corte demo',
                description:
                    'El estado pasará a Abierto solo en esta maqueta; no se guardará en el backend.',
                successMessage: 'Corte demo abierto.',
              ),
              icon: const Icon(Icons.check),
              label: const Text('Confirmar preparación'),
            ),
            TextButton.icon(
              onPressed: () => _confirmTransition(
                context,
                ref,
                session,
                cut,
                action: 'cancelar',
                title: 'Cancelar corte',
                description:
                    'El corte demo quedará cancelado. En el backend se liberarían las reservas del periodo.',
                successMessage: 'Corte demo cancelado.',
              ),
              icon: const Icon(Icons.close),
              label: const Text('Cancelar corte'),
            ),
          ],
        ),
      );

  Future<void> _confirmTransition(
    BuildContext context,
    WidgetRef ref,
    AuthSessionModel session,
    CutModel cut, {
    required String action,
    required String title,
    required String description,
    required String successMessage,
  }) async {
    final comment = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(description),
          const SizedBox(height: AppTheme.space3),
          TextField(
            controller: comment,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Comentario opcional',
              alignLabelWithHint: true,
            ),
            minLines: 2,
            maxLines: 4,
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (!context.mounted) {
      comment.dispose();
      return;
    }
    if (confirmed == true) {
      try {
        ref.read(cortesControllerProvider.notifier).transitionDemo(
              id: cut.id,
              action: action,
              actor: session.name,
              comment: comment.text,
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(successMessage)),
          );
          context.go('/cortes/${cut.id}');
        }
      } on StateError catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.message.toString())),
          );
        }
      }
    }
    comment.dispose();
  }
}
