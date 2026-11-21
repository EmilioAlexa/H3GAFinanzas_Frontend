import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/env.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/network/finanzas_api.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_metric_card.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../controllers/prenomina_controller.dart';
import '../../fixtures/prenomina_demo_fixtures.dart';
import '../../models/prenomina_cut_model.dart';
import '../../models/prenomina_model.dart';
import '../../models/prenomina_movement_model.dart';

class PrenominaPreparacionPage extends ConsumerStatefulWidget {
  const PrenominaPreparacionPage({required this.cutId, super.key});

  final String cutId;

  @override
  ConsumerState<PrenominaPreparacionPage> createState() =>
      _PrenominaPreparacionPageState();
}

class _PrenominaPreparacionPageState
    extends ConsumerState<PrenominaPreparacionPage> {
  bool _generating = false;
  Map<String, dynamic>? _preview;
  List<Map<String, dynamic>> _states = [];
  String? _loadError;
  @override
  void initState() {
    super.initState();
    if (!AppEnv.demoMode) _loadReal();
  }

  Future<void> _loadReal() async {
    try {
      final api = ref.read(finanzasApiProvider);
      final preview = await api
          .detail('/finanzas/cortes/${widget.cutId}/prenomina/preparacion');
      final states = await api.list('/finanzas/catalogos/estados-prenomina');
      if (mounted)
        setState(() {
          _preview = preview;
          _states = states;
          _selectedState = '';
        });
    } catch (e) {
      if (mounted) setState(() => _loadError = e.toString());
    }
  }

  final _observations = TextEditingController();
  String _selectedState = 'En preparación';

  @override
  void dispose() {
    _observations.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AppEnv.demoMode && _loadError != null)
      return AppStatePanel(
          icon: Icons.error_outline,
          title: 'No se pudo preparar',
          message: _loadError!);
    if (!AppEnv.demoMode && _preview == null)
      return const Center(child: CircularProgressIndicator());
    final rawCut = apiMap(_preview?['corte']);
    final cutMatches = AppEnv.demoMode
        ? PrenominaDemoFixtures.cuts.where((cut) => cut.id == widget.cutId)
        : [
            PrenominaCutModel(
                id: widget.cutId,
                name: apiText(rawCut['numero_corte']),
                period: '${rawCut['fecha_inicio']} / ${rawCut['fecha_fin']}',
                status: apiText(rawCut['estado']),
                people: (_preview!['por_receptor'] as List).length,
                operations: _preview!['comisiones_elegibles'] as int,
                total: Decimal.parse(apiText(_preview!['total_referencial'])),
                generated: false)
          ];
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
            title: 'Preparación no disponible',
            message: 'No fue posible cargar la preparación de prenómina.',
          );
        }
        final items = AppEnv.demoMode
            ? ref.read(prenominaControllerProvider.notifier).forCut(cut.id)
            : (_preview!['por_receptor'] as List).map((raw) {
                final group = apiMap(raw);
                return PrenominaModel(
                    id: '',
                    cutId: widget.cutId,
                    cutName: cut.name,
                    period: cut.period,
                    recipientId: apiText(group['receptor_dispersion_id'] ??
                        group['beneficiario_id']),
                    recipient: group['destino'] == 'Referidor'
                        ? 'Referidor (concepto general)'
                        : apiText(group['receptor']),
                    position: apiText(group['destino']),
                    status: 'Pendiente de generar',
                    backendTotal:
                        Decimal.parse(apiText(group['monto_referencial'])),
                    movements: (_preview!['movimientos'] as List)
                        .map(apiMap)
                        .where((m) =>
                            m['concepto'] == group['destino'] &&
                            m['receptor'] == group['receptor'])
                        .map((m) => PrenominaMovementModel(
                            id: apiText(m['comision_id']),
                            payment: apiText(apiMap(m['pago'])['id']),
                            contract: '',
                            saleType: apiText(m['concepto']),
                            percentage: Decimal.parse(
                                apiText(m['porcentaje_aplicado'])),
                            baseAmount: Decimal.parse(apiText(m['monto_base'])),
                            commissionAmount:
                                Decimal.parse(apiText(m['monto_referencial'])),
                            status: 'Elegible'))
                        .toList());
              }).toList();
        final generated = items.isNotEmpty &&
            items.every((item) => item.status == 'Preparada');
        final total = AppEnv.demoMode
            ? items.fold(Decimal.zero, (sum, item) => sum + item.total)
            : Decimal.parse(apiText(_preview!['total_referencial']));
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.space6),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AppBackButton(
              label: 'Prenómina',
              onPressed: () => context.go('/prenomina'),
            ),
            AppPageHeader(
              eyebrow: 'Revisión previa · ${cut.name}',
              title: 'Preparación de prenómina',
              description: cut.period,
            ),
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
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var index = 0; index < cards.length; index++) ...[
                      Expanded(child: cards[index]),
                      if (index != cards.length - 1)
                        const SizedBox(width: AppTheme.space3),
                    ],
                  ],
                ),
              );
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
          DropdownButtonFormField<String>(
            initialValue: _selectedState.isEmpty ? null : _selectedState,
            decoration: const InputDecoration(labelText: 'Estado de ejemplo'),
            items: (AppEnv.demoMode
                    ? const ['En preparacion', 'Preparada']
                    : _states.map((s) => apiText(s['id'])).toList())
                .map((value) => DropdownMenuItem(
                    value: value,
                    child: Text(AppEnv.demoMode
                        ? value
                        : apiText(_states.firstWhere(
                            (s) => apiText(s['id']) == value)['nombre']))))
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
              onPressed: generated || _generating ? null : _confirmGeneration,
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
        content:
            Text('¿Confirmas generar la prenómina con estado $_selectedState?'),
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
    setState(() => _generating = true);
    try {
      if (!AppEnv.demoMode) {
        final stateId = int.tryParse(_selectedState);
        if (stateId == null)
          throw StateError('Selecciona un estado del catalogo.');
        await ref
            .read(finanzasApiProvider)
            .generatePayroll(widget.cutId, stateId, _observations.text);
        await ref.read(prenominaControllerProvider.notifier).load();
        if (!mounted) return;
      } else {
        ref
            .read(prenominaControllerProvider.notifier)
            .generateDemo(widget.cutId);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prenómina generada.')),
      );
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }
}
