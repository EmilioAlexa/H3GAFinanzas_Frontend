import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_metric_card.dart';
import '../../../../core/widgets/app_notice.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../controllers/prenomina_controller.dart';
import '../../models/prenomina_model.dart';

class PrenominaDetallePage extends ConsumerWidget {
  const PrenominaDetallePage({required this.recipientId, super.key});

  final String recipientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(prenominaControllerProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => const AppStatePanel(
        icon: Icons.error_outline,
        title: 'No se pudo abrir el detalle',
        message: 'Vuelve al listado e inténtalo de nuevo.',
      ),
      data: (items) {
        if (items == null) {
          return const AppStatePanel(
            icon: Icons.link_off_outlined,
            title: 'Detalle sin conectar',
            message: 'GET /finanzas/prenominas/{id} se integrará en B9.',
          );
        }
        final matches = items.where((item) => item.id == recipientId);
        if (matches.isEmpty) {
          return AppStatePanel(
            icon: Icons.search_off_outlined,
            title: 'No se encontró el receptor',
            message: 'Regresa al listado de prenómina.',
            action: TextButton(
              onPressed: () => context.go('/prenomina'),
              child: const Text('Volver a Prenómina'),
            ),
          );
        }
        return _detail(context, matches.first);
      },
    );
  }

  Widget _detail(BuildContext context, PrenominaModel model) {
    final included = model.movements
        .where((movement) => movement.status == 'Incluida')
        .fold(Decimal.zero, (sum, movement) => sum + movement.commissionAmount);
    final pending = model.total - included;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => context.go('/prenomina'),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Prenómina'),
          ),
        ),
        AppPageHeader(
          eyebrow: 'Desglose referencial · Corte ${model.cutName}',
          title: 'Prenómina · ${model.recipient}',
          description: model.position,
        ),
        const AppNotice(
          type: AppNoticeType.warning,
          text:
              'Detalle ilustrativo. Los movimientos y estados se reemplazarán por la respuesta del backend al integrar B9.',
        ),
        const SizedBox(height: AppTheme.space4),
        LayoutBuilder(builder: (context, constraints) {
          final compact = constraints.maxWidth < 600;
          final cards = [
            AppMetricCard(
              label: 'Importe concentrado',
              value: MoneyFormatter.format(model.total),
              detail: '${model.movements.length} movimientos',
              icon: Icons.work_outline,
            ),
            AppMetricCard(
              label: 'Incluido en prenómina',
              value: MoneyFormatter.format(included),
              detail:
                  '${model.movements.where((movement) => movement.status == 'Incluida').length} movimientos incluidos (demo)',
              icon: Icons.check_circle_outline,
              tone: AppMetricTone.info,
            ),
            AppMetricCard(
              label: 'En preparación',
              value: MoneyFormatter.format(pending),
              detail:
                  '${model.movements.where((movement) => movement.status != 'Incluida').length} movimientos',
              icon: Icons.schedule_outlined,
              tone: AppMetricTone.accent,
            ),
          ];
          return compact
              ? Column(children: [
                  for (final card in cards) ...[
                    card,
                    const SizedBox(height: AppTheme.space3),
                  ],
                ])
              : Row(children: [
                  for (var index = 0; index < cards.length; index++) ...[
                    Expanded(child: cards[index]),
                    if (index < cards.length - 1)
                      const SizedBox(width: AppTheme.space3),
                  ],
                ]);
        }),
        const SizedBox(height: AppTheme.space4),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(color: AppTheme.line),
            boxShadow: AppTheme.elevation,
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.all(AppTheme.space4),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Movimientos incluidos',
                        style: Theme.of(context).textTheme.titleLarge),
                    Text('Comisiones de ${model.recipient} por pago validado.'),
                  ]),
            ),
            for (final movement in model.movements)
              LayoutBuilder(builder: (context, constraints) {
                final compact = constraints.maxWidth < 600;
                final leading = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(movement.payment,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('${movement.contract} · ${model.position}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppTheme.muted)),
                    const SizedBox(height: AppTheme.space2),
                    AppBadge(label: movement.saleType, tone: AppBadgeTone.info),
                    const SizedBox(height: AppTheme.space2),
                    AppBadge(
                      label: '${movement.percentage}%',
                      tone: AppBadgeTone.neutral,
                    ),
                  ],
                );
                final values = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Base  ${MoneyFormatter.format(movement.baseAmount)}'),
                    Text(
                        'Importe  ${MoneyFormatter.format(movement.commissionAmount)}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: AppTheme.space2),
                    AppBadge(
                      label: movement.status,
                      tone: movement.status == 'Incluida'
                          ? AppBadgeTone.success
                          : AppBadgeTone.warning,
                    ),
                  ],
                );
                return Container(
                  padding: const EdgeInsets.all(AppTheme.space4),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppTheme.line)),
                  ),
                  child: compact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            leading,
                            const SizedBox(height: AppTheme.space3),
                            values
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(flex: 2, child: leading),
                            Expanded(child: values),
                          ],
                        ),
                );
              }),
          ]),
        ),
      ]),
    );
  }
}
