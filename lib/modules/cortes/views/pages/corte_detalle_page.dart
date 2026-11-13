import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_metric_card.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../../auth/auth.dart';
import '../../controllers/cortes_controller.dart';
import '../../fixtures/cortes_demo_fixtures.dart';
import '../../models/cut_distribution_model.dart';
import '../../models/cut_model.dart';
import '../../utils/cut_period_formatter.dart';

class CorteDetallePage extends ConsumerWidget {
  const CorteDetallePage({required this.cutId, super.key});
  final String cutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    if (session == null || session.role == UserRole.asesor) {
      return const AppStatePanel(
        icon: Icons.lock_outline,
        title: 'Acceso restringido',
        message: 'Solo administración puede consultar los detalles de corte.',
      );
    }
    return ref.watch(cortesControllerProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => const AppStatePanel(
            icon: Icons.cloud_off_outlined,
            title: 'No se pudo cargar el corte',
            message: 'Vuelve al listado e inténtalo de nuevo.',
          ),
          data: (cuts) {
            final cut = ref.read(cortesControllerProvider.notifier).find(cutId);
            if (cuts == null) {
              return const AppStatePanel(
                icon: Icons.link_off,
                title: 'Detalle no disponible',
                message: 'No fue posible consultar el corte.',
              );
            }
            if (cut == null) {
              return const AppStatePanel(
                icon: Icons.search_off_outlined,
                title: 'Corte no disponible',
                message: 'No existe en el conjunto.',
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
    final samples = CortesDemoFixtures.distributions;
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
          eyebrow: 'Corte ${cut.folio}',
          title: CutPeriodFormatter.label(
            cut.periodStart,
            cut.periodEndExclusive,
          ),
          description: 'Periodo viernes a jueves · ${_statusDescription(cut)}',
          actions: [
            _statusBadge(cut.status),
            if (cut.status == 'Abierto')
              OutlinedButton.icon(
                onPressed: () => _transition(
                  context,
                  ref,
                  session,
                  cut,
                  action: 'cancelar',
                  title: 'Cancelar corte',
                  detail:
                      'Se cancelará el corte y se conservará el historial de movimientos.',
                ),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancelar'),
              ),
            if (cut.status == 'Abierto')
              FilledButton.icon(
                onPressed: () => _transition(
                  context,
                  ref,
                  session,
                  cut,
                  action: 'cerrar',
                  title: 'Cerrar corte',
                  detail:
                      'El cierre es terminal. Revisa los totales y confirma para registrar el estado local.',
                ),
                icon: const Icon(Icons.lock_outline),
                label: const Text('Cerrar corte'),
              ),
          ],
        ),
        LayoutBuilder(builder: (context, constraints) {
          final count = constraints.maxWidth >= 900
              ? 3
              : constraints.maxWidth >= 560
                  ? 2
                  : 1;
          final width = (constraints.maxWidth - (count - 1) * 12) / count;
          return Wrap(spacing: 12, runSpacing: 12, children: [
            SizedBox(
              width: width,
              child: AppMetricCard(
                label: 'Total del corte',
                value: MoneyFormatter.format(cut.totalAmount),
                detail: '${cut.includedCount} pagos incluidos',
                icon: Icons.bar_chart_outlined,
              ),
            ),
            SizedBox(
              width: width,
              child: AppMetricCard(
                label: 'Comisiones relacionadas',
                value: MoneyFormatter.format(cut.commissionAmount),
                detail: '${cut.advisorCount} asesores',
                icon: Icons.business_center_outlined,
                tone: AppMetricTone.accent,
              ),
            ),
            SizedBox(
              width: width,
              child: AppMetricCard(
                label: 'Movimientos del periodo',
                value: '${cut.includedCount + cut.excludedCount}',
                detail: '${cut.excludedCount} excluidos en la vista previa',
                icon: Icons.receipt_long_outlined,
                tone: AppMetricTone.info,
              ),
            ),
          ]);
        }),
        const SizedBox(height: AppTheme.space4),
        _distributionPanel(context, samples),
        const SizedBox(height: AppTheme.space4),
        LayoutBuilder(builder: (context, constraints) {
          final services = _serviceSummary(context);
          final advisors = _advisorSummary(context);
          if (constraints.maxWidth > 900) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: services),
                const SizedBox(width: AppTheme.space4),
                SizedBox(width: 380, child: advisors),
              ],
            );
          }
          return Column(children: [
            services,
            const SizedBox(height: AppTheme.space4),
            advisors,
          ]);
        }),
        const SizedBox(height: AppTheme.space4),
        _historyPanel(context, cut),
      ]),
    );
  }

  Widget _distributionPanel(
    BuildContext context,
    List<CutDistributionModel> distributions,
  ) =>
      Container(
        clipBehavior: Clip.antiAlias,
        decoration: _panelDecoration(),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.space4),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dispersión de recursos del corte',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  )),
                      const SizedBox(height: AppTheme.space1),
                      const Text(
                        'Ejemplos de snapshots de comisión; Empresa se muestra como remanente.',
                        style: TextStyle(color: AppTheme.muted),
                      ),
                    ]),
              ),
            ]),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppTheme.space4),
            child: LayoutBuilder(builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900 ? 2 : 1;
              final cardWidth =
                  (constraints.maxWidth - (columns - 1) * 12) / columns;
              return Wrap(spacing: 12, runSpacing: 12, children: [
                for (final distribution in distributions)
                  SizedBox(
                    width: cardWidth,
                    child: _distributionCard(context, distribution),
                  ),
              ]);
            }),
          ),
        ]),
      );

  Widget _distributionCard(
    BuildContext context,
    CutDistributionModel distribution,
  ) =>
      Container(
        padding: const EdgeInsets.all(AppTheme.space4),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.line),
          borderRadius: BorderRadius.circular(AppTheme.radiusField),
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(distribution.paymentFolio,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                )),
                    Text(
                      '${distribution.clientName} · ${distribution.serviceName} · ${distribution.paymentMethod}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.muted),
                    ),
                  ]),
            ),
            const SizedBox(width: AppTheme.space2),
            Text(MoneyFormatter.format(distribution.amount),
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
          const Divider(height: AppTheme.space5),
          for (final line in distribution.lines)
            _distributionLine(
              line.destination,
              '${line.percentage}%',
              MoneyFormatter.format(line.amount),
            ),
          _distributionLine(
            'Empresa',
            '${_remainderPercentage(distribution)}%',
            MoneyFormatter.format(distribution.companyRemainder),
            muted: true,
          ),
          const Divider(height: AppTheme.space4),
          _distributionLine(
            'Total conciliado',
            '100%',
            MoneyFormatter.format(distribution.amount),
          ),
        ]),
      );

  String _remainderPercentage(CutDistributionModel distribution) {
    final assigned = distribution.lines.fold<Decimal>(
      Decimal.zero,
      (sum, line) => sum + line.percentage,
    );
    return (Decimal.fromInt(100) - assigned).toString();
  }

  Widget _distributionLine(
    String label,
    String percentage,
    String amount, {
    bool muted = false,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space2),
        child: Row(children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                  color: muted ? AppTheme.muted : AppTheme.ink,
                  fontStyle: muted ? FontStyle.italic : null,
                )),
          ),
          SizedBox(
              width: 72, child: Text(percentage, textAlign: TextAlign.end)),
          SizedBox(
            width: 120,
            child: Text(amount,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ]),
      );

  Widget _serviceSummary(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppTheme.space4),
        decoration: _panelDecoration(),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Resumen por servicio',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  )),
          const SizedBox(height: AppTheme.space1),
          const Text('Pagos validados incluidos · datos ',
              style: TextStyle(color: AppTheme.muted)),
          const SizedBox(height: AppTheme.space4),
          for (final item in const [
            ('Modalidad 40', '\$486,300', 38),
            ('APD', '\$398,250', 31),
            ('Modalidad 10', '\$274,650', 21),
            ('M40 Retroactiva', '\$125,300', 10),
          ]) ...[
            Row(children: [
              Expanded(child: Text(item.$1)),
              Text(item.$2,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: AppTheme.space2),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              child: LinearProgressIndicator(
                value: item.$3 / 100,
                minHeight: 7,
                backgroundColor: AppTheme.surfaceSecondary,
                color: AppTheme.secondaryDark,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  top: AppTheme.space1, bottom: AppTheme.space3),
              child: Text('${item.$3}%',
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
            ),
          ],
        ]),
      );

  Widget _advisorSummary(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppTheme.space4),
        decoration: _panelDecoration(),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Resumen por asesor',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  )),
          const SizedBox(height: AppTheme.space1),
          const Text('Principales contribuciones',
              style: TextStyle(color: AppTheme.muted)),
          const SizedBox(height: AppTheme.space3),
          for (final item in const [
            ('DC', 'Daniela Cruz', '28 pagos', '\$348,500'),
            ('JS', 'Jorge Silva', '24 pagos', '\$292,800'),
            ('MR', 'Mónica Ruiz', '19 pagos', '\$248,100'),
            ('RG', 'Roberto Gil', '12 pagos', '\$185,400'),
          ])
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppTheme.accentSoft,
                foregroundColor: AppTheme.primary,
                child: Text(item.$1),
              ),
              title: Text(item.$2),
              subtitle: Text(item.$3),
              trailing: Text(item.$4,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
        ]),
      );

  Widget _historyPanel(BuildContext context, CutModel cut) => Container(
        padding: const EdgeInsets.all(AppTheme.space4),
        decoration: _panelDecoration(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Historial del corte',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  )),
          const SizedBox(height: AppTheme.space2),
          for (final event in cut.history)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history, color: AppTheme.secondaryDark),
              title: Text(event.status),
              subtitle: Text(
                '${event.actor} · ${MoneyFormatter.formatDate(event.at)}${event.comment == null ? '' : ' · ${event.comment}'}',
              ),
            ),
        ]),
      );

  BoxDecoration _panelDecoration() => BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.line),
        boxShadow: AppTheme.elevation,
      );

  String _statusDescription(CutModel cut) => switch (cut.status) {
        'Cerrado' =>
          'Cerrado el ${CutPeriodFormatter.short(cut.history.last.at)}',
        'Abierto' => 'Corte abierto para revisión',
        'Cancelado' => 'Corte cancelado',
        _ => 'En preparación',
      };

  AppBadge _statusBadge(String status) => AppBadge(
        label: status,
        tone: switch (status) {
          'Abierto' => AppBadgeTone.info,
          'En preparación' => AppBadgeTone.warning,
          'Cerrado' => AppBadgeTone.success,
          'Cancelado' => AppBadgeTone.danger,
          _ => AppBadgeTone.neutral,
        },
      );

  Future<void> _transition(
    BuildContext context,
    WidgetRef ref,
    AuthSessionModel session,
    CutModel cut, {
    required String action,
    required String title,
    required String detail,
  }) async {
    final comment = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(detail),
          const SizedBox(height: AppTheme.space3),
          TextField(
            controller: comment,
            maxLength: 500,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Comentario opcional',
              alignLabelWithHint: true,
            ),
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
            SnackBar(content: Text(title)),
          );
          context.go('/cortes');
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
