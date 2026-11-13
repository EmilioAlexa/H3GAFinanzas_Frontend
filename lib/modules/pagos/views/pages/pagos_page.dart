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
import '../../../../core/widgets/app_filter_dropdown.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_responsive_collection.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../../../core/widgets/app_tab_strip.dart';
import '../../../auth/auth.dart';
import '../../controllers/pagos_controller.dart';
import '../../models/pago_model.dart';

class PagosPage extends ConsumerStatefulWidget {
  const PagosPage({super.key});
  @override
  ConsumerState<PagosPage> createState() => _PagosPageState();
}

class _PagosPageState extends ConsumerState<PagosPage> {
  final _search = TextEditingController();
  String _query = '';
  String _statusGroup = 'Todos';
  String _method = 'Todas';
  String _service = 'Todos los servicios';
  bool? _filtersExpanded;

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
          message: 'Pagos requiere una sesión activa.');
    }
    final data = ref.watch(pagosControllerProvider(session.role));
    return data.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => AppStatePanel(
        icon: Icons.cloud_off_outlined,
        title: 'No se pudieron cargar los pagos',
        message: 'Inténtalo de nuevo.',
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
              title: 'Sin pagos disponibles',
              message: 'No fue posible consultar los pagos.')
          : _content(context, state.payments),
    );
  }

  Widget _content(BuildContext context, List<PagoModel> payments) {
    final filtered = payments.where((payment) {
      final query = _query.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          payment.folio.toLowerCase().contains(query) ||
          payment.clienteNombre.toLowerCase().contains(query) ||
          payment.contratoFolio.toLowerCase().contains(query) ||
          payment.referencia.toLowerCase().contains(query);
      final matchesStatus = switch (_statusGroup) {
        'Pendientes' => payment.estado.startsWith('Pendiente'),
        'Por revisar' => payment.estado == 'En revisión',
        'Rechazados' => payment.estado == 'Rechazado',
        'Validados' => payment.estado == 'Validado',
        _ => true,
      };
      final matchesService = _service == 'Todos los servicios' ||
          payment.servicioNombre == _service;
      return matchesQuery &&
          matchesStatus &&
          matchesService &&
          (_method == 'Todas' || payment.formaPago == _method);
    }).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AppPageHeader(
            eyebrow: 'Operación financiera',
            title: 'Pagos',
            description: 'Consulta y registra pagos de contratos.',
            actions: [
              if (AppEnv.demoMode)
                FilledButton.icon(
                    onPressed: () => context.go('/pagos/nuevo'),
                    icon: const Icon(Icons.add),
                    label: const Text('Registrar pago')),
            ]),
        _statusFilters(payments),
        const SizedBox(height: AppTheme.space3),
        _panel(context, filtered, payments),
      ]),
    );
  }

  Widget _statusFilters(List<PagoModel> payments) {
    const groups = [
      'Todos',
      'Pendientes',
      'Por revisar',
      'Rechazados',
      'Validados'
    ];
    int count(String group) => payments
        .where((payment) => switch (group) {
              'Pendientes' => payment.estado.startsWith('Pendiente'),
              'Por revisar' => payment.estado == 'En revisión',
              'Rechazados' => payment.estado == 'Rechazado',
              'Validados' => payment.estado == 'Validado',
              _ => true,
            })
        .length;
    return AppTabStrip(
      labels: groups,
      counts: [for (final group in groups) count(group)],
      selectedIndex: groups.indexOf(_statusGroup),
      onSelected: (index) => setState(() => _statusGroup = groups[index]),
    );
  }

  Widget _panel(
    BuildContext context,
    List<PagoModel> payments,
    List<PagoModel> allPayments,
  ) =>
      Container(
        padding: const EdgeInsets.all(AppTheme.space4),
        decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border.all(color: AppTheme.line),
            borderRadius: BorderRadius.circular(AppTheme.radius),
            boxShadow: AppTheme.elevation),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          LayoutBuilder(builder: (context, constraints) {
            final compact = Responsive.of(context) == WindowSizeClass.compacto;
            final filtersVisible = _filtersExpanded ?? !compact;
            final search = TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                    hintText: 'Folio, cliente o referencia',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14)));
            final filterButton = SizedBox(
              width: 96,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () =>
                    setState(() => _filtersExpanded = !filtersVisible),
                icon: const Icon(Icons.filter_list_rounded, size: 19),
                label: const Text('Filtros'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppTheme.space2),
                ),
              ),
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Expanded(child: search),
                    const SizedBox(width: AppTheme.space2),
                    filterButton,
                  ]),
                  if (filtersVisible) ...[
                    const SizedBox(height: AppTheme.space2),
                    _statusDropdown(),
                    const SizedBox(height: AppTheme.space2),
                    _serviceDropdown(allPayments),
                    const SizedBox(height: AppTheme.space2),
                    _methodDropdown(),
                  ],
                ],
              );
            }
            return Wrap(
              spacing: AppTheme.space2,
              runSpacing: AppTheme.space2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(width: 330, child: search),
                filterButton,
                if (filtersVisible) ...[
                  SizedBox(width: 190, child: _statusDropdown()),
                  SizedBox(width: 210, child: _serviceDropdown(allPayments)),
                  SizedBox(width: 190, child: _methodDropdown()),
                ],
              ],
            );
          }),
          const Divider(height: AppTheme.space6),
          if (payments.isEmpty)
            const AppStatePanel(
                icon: Icons.search_off_outlined,
                title: 'No hay pagos para mostrar',
                message: 'Cambia los filtros o registra un pago.')
          else
            AppResponsiveCollection<PagoModel>(
              rows: payments,
              columns: [
                AppDataColumn(
                    label: 'Folio / Cliente',
                    value: (p) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.folio,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              Text(p.clienteNombre)
                            ])),
                AppDataColumn(
                    label: 'Contrato / Servicio',
                    showOnMedium: false,
                    value: (p) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.contratoFolio),
                              Text(p.servicioNombre)
                            ])),
                AppDataColumn(
                    label: 'Fecha',
                    value: (p) => Text(MoneyFormatter.formatDate(p.fechaPago))),
                AppDataColumn(
                    label: 'Número de pago',
                    showOnMedium: false,
                    value: (p) => Text(_paymentNumber(p))),
                AppDataColumn(
                    label: 'Importe',
                    numeric: true,
                    value: (p) => Text(MoneyFormatter.format(p.monto))),
                AppDataColumn(
                    label: 'Forma de pago',
                    showOnMedium: false,
                    value: (p) => Text(p.formaPago)),
                AppDataColumn(label: 'Estado', value: (p) => _badge(p.estado)),
                AppDataColumn(
                    label: 'Evidencias',
                    value: (p) => Text('${p.evidencias.length}')),
                AppDataColumn(
                    label: '', value: (p) => const Icon(Icons.chevron_right)),
              ],
              compactCardBuilder: _card,
              onRowTap: (p) => context.go('/pagos/${p.id}'),
            ),
          const Divider(height: AppTheme.space6),
          Text('Mostrando ${payments.length} movimientos'),
        ]),
      );

  Widget _statusDropdown() => AppFilterDropdown<String>(
        value: _statusGroup,
        label: 'Estado',
        items: const [
          'Todos',
          'Pendientes',
          'Por revisar',
          'Rechazados',
          'Validados',
        ]
            .map((value) => DropdownMenuItem(value: value, child: Text(value)))
            .toList(),
        onChanged: (value) => setState(() => _statusGroup = value ?? 'Todos'),
      );

  Widget _serviceDropdown(List<PagoModel> payments) =>
      AppFilterDropdown<String>(
        value: _service,
        label: 'Servicio',
        items: [
          'Todos los servicios',
          ...payments.map((payment) => payment.servicioNombre).toSet(),
        ]
            .map((value) => DropdownMenuItem(value: value, child: Text(value)))
            .toList(),
        onChanged: (value) =>
            setState(() => _service = value ?? 'Todos los servicios'),
      );

  Widget _methodDropdown() => AppFilterDropdown<String>(
        value: _method,
        label: 'Forma de pago',
        items: const [
          'Todas',
          'Transferencia',
          'Depósito',
          'Efectivo',
          'Cheque',
        ]
            .map((value) => DropdownMenuItem(value: value, child: Text(value)))
            .toList(),
        onChanged: (value) => setState(() => _method = value ?? 'Todas'),
      );

  Widget _card(BuildContext context, PagoModel p) => Container(
        padding: const EdgeInsets.all(AppTheme.space4),
        decoration: BoxDecoration(
            border: Border.all(color: AppTheme.line),
            borderRadius: BorderRadius.circular(AppTheme.radius)),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(p.folio, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppTheme.space2),
          Align(alignment: Alignment.centerLeft, child: _badge(p.estado)),
          const SizedBox(height: AppTheme.space2),
          Text(p.clienteNombre),
          Text('${p.contratoFolio} · ${p.servicioNombre}',
              style: Theme.of(context).textTheme.bodySmall),
          const Divider(height: AppTheme.space4),
          _line('Fecha', MoneyFormatter.formatDate(p.fechaPago)),
          _line('Pago', _paymentNumber(p)),
          _line('Importe', MoneyFormatter.format(p.monto)),
          _line('Forma de pago', p.formaPago),
          _line(
              'Evidencias',
              p.evidencias.isEmpty
                  ? 'Sin evidencia'
                  : '${p.evidencias.length} archivos'),
          Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                  onPressed: () => context.go('/pagos/${p.id}'),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Detalle'))),
        ]),
      );

  Widget _line(String label, String value) => Padding(
      padding: const EdgeInsets.only(top: AppTheme.space1),
      child: Row(children: [
        SizedBox(width: 110, child: Text(label)),
        Expanded(child: Text(value))
      ]));

  Widget _badge(String state) => AppBadge(
      label: state,
      tone: switch (state) {
        'Validado' => AppBadgeTone.success,
        'Rechazado' => AppBadgeTone.danger,
        'En revisión' => AppBadgeTone.info,
        _ => AppBadgeTone.warning,
      });

  String _paymentNumber(PagoModel payment) {
    final number = payment.numeroPago;
    final total = payment.cantidadPagos;
    if (number == null || total == null) return 'Sin número de pago';
    return total == 1
        ? 'Pago único · $number de $total'
        : 'Mensualidad $number de $total';
  }
}
