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
import '../../fixtures/prenomina_demo_fixtures.dart';
import '../../models/prenomina_model.dart';

class PrenominaPreparacionPage extends ConsumerStatefulWidget {
  const PrenominaPreparacionPage({required this.cutId, super.key});

  final String cutId;

  @override
  ConsumerState<PrenominaPreparacionPage> createState() =>
      _PrenominaPreparacionPageState();
}

class _PrenominaPreparacionPageState
    extends ConsumerState<PrenominaPreparacionPage> {
  final _observations = TextEditingController();
  String _selectedState = 'En preparación';

  @override
  void dispose() {
    _observations.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cutMatches =
        PrenominaDemoFixtures.cuts.where((cut) => cut.id == widget.cutId);
    if (cutMatches.isEmpty) {
      return const AppStatePanel(
        icon: Icons.search_off_outlined,
        title: 'No se encontró el corte',
        message: 'Vuelve al listado de prenómina.',
      );
    }
    final cut = cutMatches.first;
    final state = ref.watch(prenominaControllerProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => const AppStatePanel(
        icon: Icons.error_outline,
        title: 'No se pudo preparar la prenómina',
        message: 'Inténtalo de nuevo.',
      ),
      data: (allItems) {
        if (allItems == null) {
          return const AppStatePanel(
            icon: Icons.link_off_outlined,
            title: 'Preparación sin conectar',
            message:
                'La vista previa GET /cortes/{corteId}/prenomina/preparacion se integrará en B9.',
          );
        }
        final items =
            ref.read(prenominaControllerProvider.notifier).forCut(cut.id);
        final generated = items.isNotEmpty &&
            items.every((item) => item.status == 'Preparada');
        final total = items.fold(Decimal.zero, (sum, item) => sum + item.total);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.space6),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.go('/prenomina'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Prenómina'),
              ),
            ),
            AppPageHeader(
              eyebrow: 'Revisión previa · ${cut.name}',
              title: 'Preparación de prenómina',
              description: cut.period,
            ),
            const AppNotice(
              type: AppNoticeType.warning,
              text:
                  'Vista previa ilustrativa. Solo se incluyen comisiones personales elegibles; IMSS, remanente de Empresa y comisiones ya ligadas se excluyen.',
            ),
            const SizedBox(height: AppTheme.space4),
            LayoutBuilder(builder: (context, constraints) {
              final cards = [
                AppMetricCard(
                  label: 'Receptores',
                  value: '${items.length}',
                  detail: 'Personas y receptores externos',
                  icon: Icons.people_outline,
                ),
                AppMetricCard(
                  label: 'Movimientos elegibles',
                  value:
                      '${items.fold<int>(0, (sum, item) => sum + item.movements.length)}',
                  icon: Icons.receipt_long_outlined,
                  tone: AppMetricTone.info,
                ),
                AppMetricCard(
                  label: 'Total estimado',
                  value: MoneyFormatter.format(total),
                  detail: 'MXN · Referencial',
                  icon: Icons.account_balance_wallet_outlined,
                  tone: AppMetricTone.accent,
                ),
              ];
              if (constraints.maxWidth < 600) {
                return Column(children: [
                  for (final card in cards) ...[
                    card,
                    const SizedBox(height: AppTheme.space3),
                  ],
                ]);
              }
              return Row(children: [
                for (var index = 0; index < cards.length; index++) ...[
                  Expanded(child: cards[index]),
                  if (index != cards.length - 1)
                    const SizedBox(width: AppTheme.space3),
                ],
              ]);
            }),
            const SizedBox(height: AppTheme.space4),
            _reviewPanel(items),
            const SizedBox(height: AppTheme.space4),
            _generationPanel(generated),
          ]),
        );
      },
    );
  }

  Widget _reviewPanel(List<PrenominaModel> items) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: AppTheme.line),
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.space4),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Revisión de movimientos',
                  style: Theme.of(context).textTheme.titleLarge),
              const Text(
                  'Confirma los receptores y los importes antes de generar.'),
            ]),
          ),
          for (final recipient in items)
            ExpansionTile(
              title: Text(recipient.recipient,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                  '${recipient.position} · ${recipient.movements.length} movimientos · ${MoneyFormatter.format(recipient.total)}'),
              trailing: AppBadge(
                label: recipient.status,
                tone: recipient.status == 'Preparada'
                    ? AppBadgeTone.success
                    : AppBadgeTone.warning,
              ),
              children: [
                for (final movement in recipient.movements)
                  ListTile(
                    title: Text(movement.payment),
                    subtitle: Text(
                        '${movement.contract} · ${movement.saleType} · Base ${MoneyFormatter.format(movement.baseAmount)}'),
                    trailing: Text(
                        MoneyFormatter.format(movement.commissionAmount),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
        ]),
      );

  Widget _generationPanel(bool generated) => Container(
        padding: const EdgeInsets.all(AppTheme.space4),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: AppTheme.line),
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Generar prenómina',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppTheme.space2),
          const AppNotice(
            text:
                'Los estados y el resultado de este formulario son. En backend debe elegirse un estado real de estados_prenomina.',
          ),
          const SizedBox(height: AppTheme.space3),
          DropdownButtonFormField<String>(
            initialValue: _selectedState,
            decoration: const InputDecoration(labelText: 'Estado de ejemplo'),
            items: const ['En preparación', 'Preparada']
                .map((value) =>
                    DropdownMenuItem(value: value, child: Text(value)))
                .toList(),
            onChanged: generated
                ? null
                : (value) {
                    if (value != null) setState(() => _selectedState = value);
                  },
          ),
          const SizedBox(height: AppTheme.space3),
          TextField(
            controller: _observations,
            maxLength: 2000,
            maxLines: 3,
            enabled: !generated,
            decoration: const InputDecoration(
              labelText: 'Observaciones',
              hintText: 'Opcional · máximo 2,000 caracteres',
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: generated ? null : _confirmGeneration,
              icon: const Icon(Icons.playlist_add_check),
              label:
                  Text(generated ? 'Prenómina generada' : 'Generar prenómina'),
            ),
          ),
        ]),
      );

  Future<void> _confirmGeneration() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generar prenómina'),
        content: Text(
            '¿Confirmas generar la prenómina con estado $_selectedState?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      ref.read(prenominaControllerProvider.notifier).generateDemo(widget.cutId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prenómina generada en memoria.')),
      );
    } on StateError catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}
