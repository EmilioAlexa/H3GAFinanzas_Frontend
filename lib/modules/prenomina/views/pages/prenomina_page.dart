import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_data_column.dart';
import '../../../../core/widgets/app_metric_card.dart';
import '../../../../core/widgets/app_notice.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_responsive_collection.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../controllers/prenomina_controller.dart';
import '../../fixtures/prenomina_demo_fixtures.dart';
import '../../models/prenomina_model.dart';

class PrenominaPage extends ConsumerStatefulWidget {
  const PrenominaPage({super.key});

  @override
  ConsumerState<PrenominaPage> createState() => _PrenominaPageState();
}

class _PrenominaPageState extends ConsumerState<PrenominaPage> {
  var _tab = 0;
  var _position = 'Todos los puestos';

  @override
  Widget build(BuildContext context) {
    final prenominas = ref.watch(prenominaControllerProvider);
    return prenominas.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => AppStatePanel(
        icon: Icons.cloud_off_outlined,
        title: 'No se pudo cargar la prenómina',
        message: 'Inténtalo de nuevo.',
        action: TextButton.icon(
          onPressed: () =>
              ref.read(prenominaControllerProvider.notifier).load(),
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      ),
      data: (items) => items == null
          ? const AppStatePanel(
              icon: Icons.link_off_outlined,
              title: 'Sin prenómina disponible',
              message: 'No fue posible consultar la prenómina del periodo.',
            )
          : _content(items),
    );
  }

  Widget _content(List<PrenominaModel> allItems) {
    final filtered = allItems
        .where((item) =>
            _position == 'Todos los puestos' || item.position == _position)
        .toList();
    final total = filtered.fold(Decimal.zero, (sum, item) => sum + item.total);
    final ops =
        filtered.fold<int>(0, (sum, item) => sum + item.movements.length);
    final people = filtered.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppPageHeader(
            eyebrow: 'Concentrado de comisiones a personas',
            title: 'Prenómina',
            description:
                'Preparación de importes por persona: asesores y receptores externos.',
          ),
          const AppNotice(
            type: AppNoticeType.warning,
            text:
                'Información referencial. Esta aplicación prepara el concentrado; no realiza pagos de nómina.',
          ),
          const SizedBox(height: AppTheme.space4),
          _periodCard(allItems),
          const SizedBox(height: AppTheme.space4),
          LayoutBuilder(builder: (context, constraints) {
            final compact = Responsive.isCompact(constraints.maxWidth);
            final metrics = [
              AppMetricCard(
                label: 'Personas receptoras',
                value: '$people',
                detail: 'En el corte seleccionado',
                icon: Icons.people_outline,
              ),
              AppMetricCard(
                label: 'Movimientos',
                value: '$ops',
                detail: 'Comisiones elegibles',
                icon: Icons.receipt_long_outlined,
                tone: AppMetricTone.info,
              ),
              AppMetricCard(
                label: 'Total a personas',
                value: MoneyFormatter.format(total),
                detail: 'Sin IMSS ni remanente de empresa',
                icon: Icons.account_balance_wallet_outlined,
                tone: AppMetricTone.accent,
              ),
            ];
            return compact
                ? Column(
                    children: [
                      for (final metric in metrics) ...[
                        metric,
                        const SizedBox(height: AppTheme.space3),
                      ],
                    ],
                  )
                : Row(
                    children: [
                      for (var i = 0; i < metrics.length; i++) ...[
                        Expanded(child: metrics[i]),
                        if (i != metrics.length - 1)
                          const SizedBox(width: AppTheme.space3),
                      ],
                    ],
                  );
          }),
          const SizedBox(height: AppTheme.space4),
          _tabs(),
          const SizedBox(height: AppTheme.space3),
          if (_tab == 0) _recipients(filtered) else _cuts(allItems),
        ],
      ),
    );
  }

  Widget _periodCard(List<PrenominaModel> allItems) {
    final cut = PrenominaDemoFixtures.cuts.first;
    final controller = ref.read(prenominaControllerProvider.notifier);
    final generated =
        controller.forCut(cut.id).every((item) => item.status == 'Preparada');
    return Container(
      padding: const EdgeInsets.all(AppTheme.space5),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.line),
        boxShadow: AppTheme.elevation,
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final compact = Responsive.isCompact(constraints.maxWidth);
        final period = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Periodo relacionado'),
            const SizedBox(height: AppTheme.space1),
            Text(cut.period,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    )),
            Text('${cut.name} · Solo comisiones a personas'),
          ],
        );
        final total = allItems
            .where((item) => item.cutId == cut.id)
            .fold(Decimal.zero, (sum, item) => sum + item.total);
        final amount = Column(
          crossAxisAlignment:
              compact ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            const Text('Total a personas'),
            const SizedBox(height: AppTheme.space1),
            Text(MoneyFormatter.format(total),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    )),
            const Text('Sin IMSS ni Empresa'),
          ],
        );
        return compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  period,
                  const SizedBox(height: AppTheme.space4),
                  amount,
                  const SizedBox(height: AppTheme.space3),
                  AppBadge(
                    label: generated ? 'Preparada' : 'En preparación',
                    tone:
                        generated ? AppBadgeTone.success : AppBadgeTone.warning,
                  ),
                ],
              )
            : Row(children: [
                Expanded(child: period),
                Expanded(child: amount),
                AppBadge(
                  label: generated ? 'Preparada' : 'En preparación',
                  tone: generated ? AppBadgeTone.success : AppBadgeTone.warning,
                ),
              ]);
      }),
    );
  }

  Widget _tabs() => Wrap(
        spacing: AppTheme.space2,
        children: [
          ChoiceChip(
            label: const Text('Por receptor'),
            selected: _tab == 0,
            onSelected: (_) => setState(() => _tab = 0),
          ),
          ChoiceChip(
            label: const Text('Pagos semanales por corte'),
            selected: _tab == 1,
            onSelected: (_) => setState(() => _tab = 1),
          ),
        ],
      );

  Widget _recipients(List<PrenominaModel> items) => _panel(
        title: 'Concentrado por receptor',
        subtitle: 'Importes agrupados por concepto y receptor.',
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.space4),
            child: Wrap(spacing: AppTheme.space3, children: [
              SizedBox(
                width: 230,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _position,
                  decoration: const InputDecoration(
                    labelText: 'Puesto o destino',
                    isDense: true,
                  ),
                  items: [
                    'Todos los puestos',
                    ...items.map((item) => item.position).toSet(),
                  ]
                      .map((value) =>
                          DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _position = value);
                  },
                ),
              ),
            ]),
          ),
          AppResponsiveCollection<PrenominaModel>(
            rows: items,
            columns: [
              AppDataColumn(
                label: 'Receptor',
                value: (item) => Text(item.recipient,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              AppDataColumn(
                  label: 'Puesto', value: (item) => Text(item.position)),
              AppDataColumn(
                label: 'Movimientos',
                numeric: true,
                value: (item) => Text('${item.movements.length}'),
              ),
              AppDataColumn(
                label: 'Importe concentrado',
                numeric: true,
                value: (item) => Text(MoneyFormatter.format(item.total)),
              ),
              AppDataColumn(
                label: 'Estado',
                value: (item) => AppBadge(
                  label: item.status,
                  tone: item.status == 'Preparada'
                      ? AppBadgeTone.success
                      : AppBadgeTone.warning,
                ),
              ),
            ],
            compactCardBuilder: (context, item) => _recipientCard(item),
            emptyTitle: 'Sin movimientos',
            emptyMessage: 'No hay receptores para este filtro.',
            onRowTap: (item) => context.go('/prenomina/detalle/${item.id}'),
          ),
        ],
      );

  Widget _recipientCard(PrenominaModel item) => Container(
        padding: const EdgeInsets.all(AppTheme.space4),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.line),
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.recipient,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          Text('${item.position} · ${item.movements.length} movimientos'),
          const SizedBox(height: AppTheme.space2),
          Row(children: [
            Expanded(child: Text(MoneyFormatter.format(item.total))),
            AppBadge(
              label: item.status,
              tone: item.status == 'Preparada'
                  ? AppBadgeTone.success
                  : AppBadgeTone.warning,
            ),
          ]),
          const Align(
            alignment: Alignment.centerRight,
            child: Text('Ver detalle',
                style: TextStyle(color: AppTheme.secondaryDark)),
          ),
        ]),
      );

  Widget _cuts(List<PrenominaModel> items) {
    final cuts = PrenominaDemoFixtures.cuts;
    return _panel(
      title: 'Pagos semanales por corte',
      subtitle: 'Importes a personas concentrados por corte semanal.',
      children: [
        for (final cut in cuts)
          Builder(builder: (context) {
            final recipients =
                items.where((item) => item.cutId == cut.id).toList();
            final generated = recipients.isNotEmpty &&
                recipients.every((item) => item.status == 'Preparada');
            final total = recipients.fold(
              Decimal.zero,
              (sum, item) => sum + item.total,
            );
            final displayTotal = recipients.isEmpty ? cut.total : total;
            final displayPeople =
                recipients.isEmpty ? cut.people : recipients.length;
            return ListTile(
              title: Text(cut.name,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                  '${cut.period} · $displayPeople personas · ${cut.operations} operaciones'),
              leading: const Icon(Icons.calendar_month_outlined),
              trailing: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppTheme.space2,
                children: [
                  Text(MoneyFormatter.format(displayTotal)),
                  AppBadge(
                    label: generated ? 'Preparada' : cut.status,
                    tone:
                        generated ? AppBadgeTone.success : AppBadgeTone.warning,
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: recipients.isEmpty
                  ? null
                  : () => context.go('/prenomina/${recipients.first.id}'),
            );
          }),
      ],
    );
  }

  Widget _panel(
          {required String title,
          required String subtitle,
          required List<Widget> children}) =>
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
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              Text(subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTheme.muted)),
            ]),
          ),
          ...children,
        ]),
      );
}
