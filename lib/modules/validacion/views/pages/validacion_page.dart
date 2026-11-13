import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/env.dart';
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
import '../../../pagos/pagos.dart';

class ValidacionPage extends ConsumerStatefulWidget {
  const ValidacionPage({super.key});

  @override
  ConsumerState<ValidacionPage> createState() => _ValidacionPageState();
}

class _ValidacionPageState extends ConsumerState<ValidacionPage> {
  final _search = TextEditingController();
  String _query = '';
  String _stage = 'Pendientes';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final session = auth.valueOrNull;
    if (auth.isLoading) return const Center(child: CircularProgressIndicator());
    if (session == null) {
      return const AppStatePanel(
        icon: Icons.lock_outline,
        title: 'Inicia sesión para continuar',
        message: 'La bandeja de validación requiere sesión activa.',
      );
    }
    if (session.role == UserRole.asesor) {
      return const AppStatePanel(
        icon: Icons.lock_outline,
        title: 'Acceso restringido',
        message: 'La validación corresponde a administración.',
      );
    }
    final asyncState = ref.watch(pagosControllerProvider(session.role));
    return asyncState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => AppStatePanel(
        icon: Icons.cloud_off_outlined,
        title: 'No se pudo cargar la bandeja',
        message: 'Vuelve a intentarlo.',
        action: TextButton.icon(
          onPressed: () =>
              ref.read(pagosControllerProvider(session.role).notifier).load(),
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      ),
      data: (state) => state == null
          ? const AppStatePanel(
              icon: Icons.link_off,
              title: 'Validación sin conectar',
              message:
                  'La bandeja real se conectará en B6. No se muestran pagos ficticios en sesión real.',
            )
          : _content(context, state.payments),
    );
  }

  Widget _content(BuildContext context, List<PagoModel> payments) {
    final visible = _forStage(payments)
        .where((payment) => _matches(payment, _query))
        .toList();
    final pending = payments
        .where(
            (payment) => payment.estado == 'Pendiente de revisión financiera')
        .length;
    final waiting = payments
        .where((payment) => payment.estado == 'Pendiente de autorización')
        .length;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const AppPageHeader(
          eyebrow: 'Control y autorización',
          title: 'Bandeja de validación',
          description:
              'Consulta el avance de cada pago desde su registro hasta la validación.',
        ),
        if (AppEnv.demoMode) ...[
          AppNotice(
            type: AppNoticeType.warning,
            text:
                '$pending pagos esperan revisión financiera; $waiting esperan autorización administrativa. Conteos locales de demostración.',
          ),
          const SizedBox(height: AppTheme.space4),
        ],
        _stageTabs(payments),
        const SizedBox(height: AppTheme.space3),
        _list(context, visible),
      ]),
    );
  }

  Widget _stageTabs(List<PagoModel> payments) {
    const stages = ['Pendientes', 'Por autorizar', 'Concluidos'];
    int count(String stage) => _forStage(payments, stage: stage).length;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final stage in stages)
          Padding(
            padding: const EdgeInsets.only(right: AppTheme.space2),
            child: ChoiceChip(
              label: Text('$stage  ${count(stage)}'),
              selected: _stage == stage,
              onSelected: (_) => setState(() => _stage = stage),
            ),
          ),
      ]),
    );
  }

  List<PagoModel> _forStage(List<PagoModel> payments, {String? stage}) {
    final currentStage = stage ?? _stage;
    return payments
        .where((payment) => switch (currentStage) {
              'Pendientes' =>
                payment.estado == 'Pendiente de revisión financiera',
              'Por autorizar' => payment.estado == 'Pendiente de autorización',
              'Concluidos' =>
                payment.estado == 'Validado' || payment.estado == 'Rechazado',
              _ => true,
            })
        .toList();
  }

  bool _matches(PagoModel payment, String query) {
    final value = query.trim().toLowerCase();
    return value.isEmpty ||
        payment.folio.toLowerCase().contains(value) ||
        payment.clienteNombre.toLowerCase().contains(value) ||
        payment.referencia.toLowerCase().contains(value) ||
        payment.contratoFolio.toLowerCase().contains(value);
  }

  Widget _list(BuildContext context, List<PagoModel> rows) => Container(
        padding: const EdgeInsets.all(AppTheme.space4),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.line),
          borderRadius: BorderRadius.circular(AppTheme.radius),
          boxShadow: AppTheme.elevation,
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          LayoutBuilder(builder: (context, constraints) {
            final compact = Responsive.classify(constraints.maxWidth) ==
                WindowSizeClass.compacto;
            final search = TextField(
              controller: _search,
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                labelText: 'Buscar pago, cliente o referencia',
                prefixIcon: Icon(Icons.search),
              ),
            );
            if (compact) return search;
            return Row(children: [Expanded(child: search)]);
          }),
          const Divider(height: AppTheme.space6),
          if (rows.isEmpty)
            const AppStatePanel(
              icon: Icons.inbox_outlined,
              title: 'No hay pagos en esta etapa',
              message: 'Cambia de etapa o ajusta la búsqueda.',
            )
          else
            AppResponsiveCollection<PagoModel>(
              rows: rows,
              columns: [
                AppDataColumn(
                  label: 'Cliente / folio',
                  value: (payment) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(payment.clienteNombre,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(payment.folio),
                    ],
                  ),
                ),
                AppDataColumn(
                    label: 'Servicio / contrato',
                    showOnMedium: false,
                    value: (payment) => Text(
                        '${payment.servicioNombre} · ${payment.contratoFolio}')),
                AppDataColumn(
                    label: 'Asesor',
                    showOnMedium: false,
                    value: (payment) => Text(payment.asesorNombre)),
                AppDataColumn(
                    label: 'Fecha',
                    value: (payment) =>
                        Text(MoneyFormatter.formatDate(payment.fechaPago))),
                AppDataColumn(
                    label: 'Monto',
                    numeric: true,
                    value: (payment) =>
                        Text(MoneyFormatter.format(payment.monto))),
                AppDataColumn(
                    label: 'Estado',
                    value: (payment) => _statusBadge(payment.estado)),
                AppDataColumn(
                    label: 'Evidencia',
                    value: (payment) => Text(payment.evidencias.isEmpty
                        ? 'Sin evidencia'
                        : '${payment.evidencias.length} archivo(s)')),
                AppDataColumn(
                  label: '',
                  value: (payment) => IconButton(
                    tooltip: 'Revisar ${payment.folio}',
                    onPressed: () => context.go('/validacion/${payment.id}'),
                    icon: const Icon(Icons.visibility_outlined),
                  ),
                ),
              ],
              compactCardBuilder: (context, payment) => _card(context, payment),
              onRowTap: (payment) => context.go('/validacion/${payment.id}'),
            ),
        ]),
      );

  Widget _card(BuildContext context, PagoModel payment) => Container(
        padding: const EdgeInsets.all(AppTheme.space4),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.line),
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _statusBadge(payment.estado),
          ),
          const SizedBox(height: AppTheme.space2),
          Text(payment.clienteNombre,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppTheme.space2),
          Text('${payment.servicioNombre} · ${payment.contratoFolio}'),
          Text(payment.asesorNombre),
          Text(MoneyFormatter.formatDate(payment.fechaPago)),
          const SizedBox(height: AppTheme.space2),
          Text(MoneyFormatter.format(payment.monto),
              style: Theme.of(context).textTheme.titleMedium),
          Text(payment.estado),
          Row(children: [
            const Icon(Icons.description_outlined, size: 18),
            const SizedBox(width: AppTheme.space2),
            Text(payment.evidencias.isEmpty
                ? 'Sin evidencia'
                : '${payment.evidencias.length} archivo(s)'),
            const Spacer(),
            IconButton(
              tooltip: 'Ver detalle del pago ${payment.folio}',
              onPressed: () => context.go('/validacion/${payment.id}'),
              icon: const Icon(Icons.visibility_outlined),
            ),
          ]),
        ]),
      );

  Widget _statusBadge(String status) => AppBadge(
        label: status,
        tone: switch (status) {
          'Validado' => AppBadgeTone.success,
          'Rechazado' => AppBadgeTone.danger,
          'Pendiente de autorización' => AppBadgeTone.info,
          _ => AppBadgeTone.warning,
        },
      );
}
