import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/responsive/window_size_class.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_data_column.dart';
import '../../../../core/widgets/app_notice.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_responsive_collection.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../../auth/auth.dart';
import '../../controllers/cortes_controller.dart';
import '../../models/cut_model.dart';
import '../../utils/cut_period_formatter.dart';

class CortesPage extends ConsumerStatefulWidget {
  const CortesPage({super.key});

  @override
  ConsumerState<CortesPage> createState() => _CortesPageState();
}

class _CortesPageState extends ConsumerState<CortesPage> {
  String _statusFilter = 'Todos los estados';
  String _periodFilter = 'Todos los periodos';

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final session = auth.valueOrNull;
    if (auth.isLoading) return const Center(child: CircularProgressIndicator());
    if (session == null || session.role == UserRole.asesor) {
      return const AppStatePanel(
        icon: Icons.lock_outline,
        title: 'Acceso restringido',
        message: 'Los cortes financieros requieren un perfil administrativo.',
      );
    }

    return ref.watch(cortesControllerProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => AppStatePanel(
            icon: Icons.cloud_off_outlined,
            title: 'No se pudieron cargar los cortes',
            message: 'Inténtalo de nuevo.',
            action: TextButton.icon(
              onPressed: () =>
                  ref.read(cortesControllerProvider.notifier).load(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ),
          data: (cuts) => cuts == null
              ? const AppStatePanel(
                  icon: Icons.link_off,
                  title: 'Cortes sin conectar',
                  message:
                      'La respuesta de cortes se conectará en la etapa de integración B8.',
                )
              : _content(context, cuts, session.name),
        );
  }

  Widget _content(BuildContext context, List<CutModel> cuts, String actor) {
    if (cuts.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppTheme.space6),
        children: [
          _header(context, actor),
          const AppStatePanel(
            icon: Icons.calendar_month_outlined,
            title: 'Todavía no hay cortes',
            message: 'Prepara un periodo que inicie en viernes.',
          ),
        ],
      );
    }
    final current = cuts.firstWhere(
      (cut) => cut.status == 'Abierto',
      orElse: () => cuts.first,
    );
    final periods = cuts
        .map((cut) => DateFormat('MMMM yyyy', 'es_MX').format(cut.periodStart))
        .toSet()
        .toList();
    final filtered = cuts.where((cut) {
      final month = DateFormat('MMMM yyyy', 'es_MX').format(cut.periodStart);
      return (_statusFilter == 'Todos los estados' ||
              cut.status == _statusFilter) &&
          (_periodFilter == 'Todos los periodos' || month == _periodFilter);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _header(context, actor),
        if (ref.read(cortesControllerProvider.notifier).demoMode) ...[
          const AppNotice(
            text:
                'Cortes de muestra. Crear, generar, cerrar y cancelar solo cambia datos locales; no reserva pagos reales.',
          ),
          const SizedBox(height: AppTheme.space4),
        ],
        _currentCutCard(current),
        const SizedBox(height: AppTheme.space4),
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
              child: Wrap(
                spacing: AppTheme.space2,
                runSpacing: AppTheme.space2,
                children: [
                  SizedBox(
                    width: 230,
                    child: DropdownButtonFormField<String>(
                      initialValue: _periodFilter,
                      decoration: const InputDecoration(
                          labelText: 'Periodo', isDense: true),
                      items: ['Todos los periodos', ...periods]
                          .map((period) => DropdownMenuItem(
                              value: period, child: Text(period)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _periodFilter = value);
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    width: 230,
                    child: DropdownButtonFormField<String>(
                      initialValue: _statusFilter,
                      decoration: const InputDecoration(
                          labelText: 'Estado', isDense: true),
                      items: const [
                        'Todos los estados',
                        'En preparación',
                        'Abierto',
                        'Cerrado',
                        'Cancelado',
                      ]
                          .map((status) => DropdownMenuItem(
                              value: status, child: Text(status)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _statusFilter = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            AppResponsiveCollection<CutModel>(
              rows: filtered,
              emptyTitle: 'No hay cortes para este estado',
              emptyMessage: 'Prueba otro filtro o prepara un nuevo corte.',
              columns: [
                AppDataColumn<CutModel>(
                  label: 'Periodo',
                  value: (cut) => _periodCell(cut),
                ),
                AppDataColumn<CutModel>(
                  label: 'Creación',
                  showOnMedium: false,
                  value: (cut) => Text(CutPeriodFormatter.short(cut.createdAt)),
                ),
                AppDataColumn<CutModel>(
                  label: 'Responsable',
                  showOnMedium: false,
                  value: (cut) => Text(cut.responsible),
                ),
                AppDataColumn<CutModel>(
                  label: 'Pagos',
                  numeric: true,
                  value: (cut) => Text('${cut.includedCount}'),
                ),
                AppDataColumn<CutModel>(
                  label: 'Total',
                  numeric: true,
                  value: (cut) => Text(
                    MoneyFormatter.format(cut.totalAmount),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                AppDataColumn<CutModel>(
                  label: 'Estado',
                  value: (cut) => _statusBadge(cut.status),
                ),
                AppDataColumn<CutModel>(
                  label: '',
                  value: (cut) => const Icon(Icons.chevron_right),
                ),
              ],
              compactCardBuilder: (context, cut) => _cutCard(cut),
              onRowTap: (cut) => _openCut(context, cut),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _header(BuildContext context, String actor) => AppPageHeader(
        eyebrow: 'Periodos viernes → jueves',
        title: 'Cortes financieros',
        description: 'Concentrado semanal de pagos validados y comisiones.',
        actions: [
          FilledButton.icon(
            onPressed: () => _createCut(context, actor),
            icon: const Icon(Icons.add),
            label: const Text('Preparar corte'),
          ),
        ],
      );

  Widget _currentCutCard(CutModel cut) => LayoutBuilder(
        builder: (context, constraints) {
          final compact = Responsive.classify(constraints.maxWidth) ==
              WindowSizeClass.compacto;
          return Material(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(AppTheme.radius + 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radius + 4),
              onTap: () => _openCut(context, cut),
              child: Container(
                padding: const EdgeInsets.all(AppTheme.space6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radius + 4),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF123F48), Color(0xFF082D34)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _heroPeriod(cut),
                          const SizedBox(height: AppTheme.space5),
                          _heroTotal(cut),
                          const SizedBox(height: AppTheme.space3),
                          _statusBadge(cut.status),
                        ],
                      )
                    : Row(children: [
                        Expanded(child: _heroPeriod(cut)),
                        Expanded(child: _heroTotal(cut)),
                        _statusBadge(cut.status),
                      ]),
              ),
            ),
          );
        },
      );

  Widget _heroPeriod(CutModel cut) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CORTE ACTUAL',
              style: TextStyle(
                color: AppTheme.white.withValues(alpha: .64),
                letterSpacing: 1.2,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: AppTheme.space2),
          Text(
            CutPeriodFormatter.label(cut.periodStart, cut.periodEndExclusive),
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppTheme.space1),
          Text('Viernes a jueves · America/Cancun',
              style: TextStyle(color: AppTheme.white.withValues(alpha: .68))),
        ],
      );

  Widget _heroTotal(CutModel cut) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TOTAL ACUMULADO',
              style: TextStyle(
                color: AppTheme.white.withValues(alpha: .64),
                letterSpacing: 1.2,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: AppTheme.space2),
          Text(
            MoneyFormatter.format(cut.totalAmount),
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.space1),
          Text('${cut.includedCount} pagos validados',
              style: TextStyle(color: AppTheme.white.withValues(alpha: .68))),
        ],
      );

  Widget _periodCell(CutModel cut) => SizedBox(
        width: 180,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            CutPeriodFormatter.label(cut.periodStart, cut.periodEndExclusive),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppTheme.space1),
          const Text('Viernes → Jueves',
              style: TextStyle(color: AppTheme.muted, fontSize: 12)),
        ]),
      );

  Widget _cutCard(CutModel cut) => Container(
        padding: const EdgeInsets.all(AppTheme.space4),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.line),
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(
                CutPeriodFormatter.label(
                    cut.periodStart, cut.periodEndExclusive),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            _statusBadge(cut.status),
            const SizedBox(width: AppTheme.space1),
            const Icon(Icons.chevron_right, color: AppTheme.ink),
          ]),
          const Text('Viernes → Jueves',
              style: TextStyle(color: AppTheme.muted)),
          const Divider(height: AppTheme.space5),
          _mobileInfo('Creación', CutPeriodFormatter.short(cut.createdAt)),
          _mobileInfo('Responsable', cut.responsible),
          _mobileInfo('Pagos incluidos', '${cut.includedCount}'),
          _mobileInfo('Total', MoneyFormatter.format(cut.totalAmount),
              bold: true),
        ]),
      );

  Widget _mobileInfo(String label, String value, {bool bold = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space1),
        child: Row(children: [
          Expanded(
              child:
                  Text(label, style: const TextStyle(color: AppTheme.muted))),
          Text(value,
              style: TextStyle(fontWeight: bold ? FontWeight.w700 : null)),
        ]),
      );

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

  void _openCut(BuildContext context, CutModel cut) {
    if (cut.status == 'En preparación') {
      context.go('/cortes/${cut.id}/preparacion');
    } else {
      context.go('/cortes/${cut.id}');
    }
  }

  Future<void> _createCut(BuildContext context, String actor) async {
    final now = DateTime.now();
    var initial = DateTime(now.year, now.month, now.day);
    while (initial.weekday != DateTime.friday) {
      initial = initial.add(const Duration(days: 1));
    }
    final start = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
      selectableDayPredicate: (date) => date.weekday == DateTime.friday,
      helpText: 'Selecciona el viernes de inicio',
      cancelText: 'Cancelar',
      confirmText: 'Continuar',
    );
    if (start == null || !context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Preparar corte'),
        content: Text(
          'Se creará un periodo viernes a jueves desde ${CutPeriodFormatter.short(start)}. En esta maqueta no se reservarán pagos reales.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Crear corte demo'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final cut = ref.read(cortesControllerProvider.notifier).createDemo(
            periodStart: DateTime(start.year, start.month, start.day),
            actor: actor,
          );
      if (context.mounted) context.go('/cortes/${cut.id}/preparacion');
    } on StateError catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message.toString())),
        );
      }
    }
  }
}
