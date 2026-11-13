import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/env.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/responsive/window_size_class.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_data_column.dart';
import '../../../../core/widgets/app_filter_dropdown.dart';
import '../../../../core/widgets/app_metric_card.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_responsive_collection.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../../auth/auth.dart';
import '../../controllers/contratos_controller.dart';
import '../../models/contrato_model.dart';

class ContratosPage extends ConsumerStatefulWidget {
  const ContratosPage({super.key});

  @override
  ConsumerState<ContratosPage> createState() => _ContratosPageState();
}

class _ContratosPageState extends ConsumerState<ContratosPage> {
  final _searchController = TextEditingController();
  String _query = '';
  String _service = 'Todos los servicios';
  String _status = 'Todos los estados';
  bool? _filtersExpanded;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return auth.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const AppStatePanel(
        icon: Icons.lock_outline,
        title: 'No se pudo cargar la sesión',
        message: 'Vuelve a iniciar sesión para consultar los contratos.',
      ),
      data: (session) {
        if (session == null) {
          return const AppStatePanel(
            icon: Icons.lock_outline,
            title: 'Inicia sesión para continuar',
            message: 'Contratos requiere una sesión activa.',
          );
        }
        final state = ref.watch(contratosControllerProvider(session.role));
        return state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => AppStatePanel(
            icon: Icons.cloud_off_outlined,
            title: 'No se pudo cargar la lista',
            message: 'Inténtalo de nuevo.',
            action: TextButton.icon(
              onPressed: () => ref
                  .read(contratosControllerProvider(session.role).notifier)
                  .load(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ),
          data: (contracts) => contracts == null
              ? const AppStatePanel(
                  icon: Icons.description_outlined,
                  title: 'Sin contratos disponibles',
                  message: 'No fue posible consultar los contratos.',
                )
              : _content(context, contracts),
        );
      },
    );
  }

  Widget _content(BuildContext context, List<ContratoModel> contracts) {
    final widthClass = Responsive.of(context);
    final filtered = contracts.where(_matches).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPageHeader(
            eyebrow: 'Gestión contractual',
            title: 'Contratos',
            description: 'Consulta acuerdos activos e históricos.',
            actions: [
              if (AppEnv.demoMode)
                FilledButton.icon(
                  onPressed: () => context.go('/contratos/nuevo'),
                  icon: const Icon(Icons.add),
                  label: const Text('Crear contrato'),
                ),
            ],
          ),
          _contractMetrics(context),
          const SizedBox(height: AppTheme.space4),
          _tablePanel(context, filtered, widthClass),
        ],
      ),
    );
  }

  Widget _contractMetrics(BuildContext context) {
    const metrics = [
      ('Contratos activos', '248', 'Total de la cartera'),
      ('Por finalizar', '17', 'Próximos 30 días'),
      ('Valor contratado', r'$3.8 M', 'En contratos activos'),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final compact = Responsive.isCompact(constraints.maxWidth);
      final width = compact ? 210.0 : (constraints.maxWidth - 24) / 3;
      return SingleChildScrollView(
        scrollDirection: compact ? Axis.horizontal : Axis.vertical,
        child: Wrap(
          spacing: AppTheme.space3,
          runSpacing: AppTheme.space3,
          children: [
            for (var index = 0; index < metrics.length; index++)
              SizedBox(
                width: width,
                child: AppMetricCard(
                  label: metrics[index].$1,
                  value: metrics[index].$2,
                  detail: metrics[index].$3,
                  icon: switch (index) {
                    0 => Icons.description_outlined,
                    1 => Icons.schedule_outlined,
                    _ => Icons.bar_chart_outlined,
                  },
                  tone: index == 1
                      ? AppMetricTone.warning
                      : AppMetricTone.secondary,
                ),
              ),
          ],
        ),
      );
    });
  }

  bool _matches(ContratoModel contract) {
    final query = _query.trim().toLowerCase();
    final matchesQuery = query.isEmpty ||
        contract.folio.toLowerCase().contains(query) ||
        contract.clienteNombre.toLowerCase().contains(query);
    return matchesQuery &&
        (_service == 'Todos los servicios' ||
            contract.servicioNombre == _service) &&
        (_status == 'Todos los estados' || contract.estadoNombre == _status);
  }

  Widget _tablePanel(
    BuildContext context,
    List<ContratoModel> contracts,
    WindowSizeClass size,
  ) =>
      Container(
        padding: const EdgeInsets.all(AppTheme.space4),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.line),
          borderRadius: BorderRadius.circular(AppTheme.radius),
          boxShadow: AppTheme.elevation,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _filters(context, size),
            const Divider(height: AppTheme.space6),
            if (contracts.isEmpty)
              const AppStatePanel(
                icon: Icons.search_off_outlined,
                title: 'Sin contratos para mostrar',
                message: 'Cambia los filtros o limpia la búsqueda.',
              )
            else
              AppResponsiveCollection<ContratoModel>(
                rows: contracts,
                columns: [
                  AppDataColumn(
                    label: 'Folio / Cliente',
                    value: (item) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.folio,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        Text(item.clienteNombre,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  AppDataColumn(
                    label: 'Servicio',
                    value: (item) => Text(item.servicioNombre),
                  ),
                  AppDataColumn(
                    label: 'Asesor',
                    showOnMedium: false,
                    value: (item) => Text(item.asesorNombre),
                  ),
                  AppDataColumn(
                    label: 'Fecha',
                    showOnMedium: false,
                    value: (item) => Text(_date(item.fechaContrato)),
                  ),
                  AppDataColumn(
                    label: 'Estado',
                    value: (item) => _statusBadge(item.estadoNombre),
                  ),
                  AppDataColumn(
                    label: '',
                    value: (item) => IconButton(
                      tooltip: 'Abrir contrato ${item.folio}',
                      onPressed: () => context.go('/contratos/${item.id}'),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ),
                ],
                compactCardBuilder: _contractCard,
                onRowTap: (item) => context.go('/contratos/${item.id}'),
              ),
            const Divider(height: AppTheme.space6),
            Text('Mostrando ${contracts.length} registros'),
          ],
        ),
      );

  Widget _filters(BuildContext context, WindowSizeClass size) {
    final filtersVisible = _filtersExpanded ?? size != WindowSizeClass.compacto;
    final search = TextField(
      key: const Key('contratos-search'),
      controller: _searchController,
      onChanged: (value) => setState(() => _query = value),
      decoration: const InputDecoration(
        hintText: 'Buscar por cliente o folio…',
        prefixIcon: Icon(Icons.search),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(),
      ),
    );
    final filterButton = SizedBox(
      width: 96,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => setState(() => _filtersExpanded = !filtersVisible),
        icon: const Icon(Icons.filter_list_rounded, size: 19),
        label: const Text('Filtros'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space2),
        ),
      ),
    );
    final service = AppFilterDropdown<String>(
      value: _service,
      label: 'Servicio',
      items: const [
        DropdownMenuItem(
            value: 'Todos los servicios', child: Text('Todos los servicios')),
        DropdownMenuItem(value: 'Modalidad 10', child: Text('Modalidad 10')),
        DropdownMenuItem(value: 'Modalidad 40', child: Text('Modalidad 40')),
        DropdownMenuItem(
            value: 'M40 Retroactiva', child: Text('M40 Retroactiva')),
        DropdownMenuItem(value: 'APD', child: Text('APD')),
      ],
      onChanged: (value) => setState(() => _service = value ?? _service),
    );
    final status = AppFilterDropdown<String>(
      value: _status,
      label: 'Estado',
      items: const [
        DropdownMenuItem(
            value: 'Todos los estados', child: Text('Todos los estados')),
        DropdownMenuItem(value: 'Activo', child: Text('Activo')),
        DropdownMenuItem(value: 'En proceso', child: Text('En proceso')),
        DropdownMenuItem(
            value: 'Pago pendiente', child: Text('Pago pendiente')),
        DropdownMenuItem(value: 'Pausado', child: Text('Pausado')),
      ],
      onChanged: (value) => setState(() => _status = value ?? _status),
    );
    if (size == WindowSizeClass.compacto) {
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
            service,
            const SizedBox(height: AppTheme.space2),
            status,
          ],
        ],
      );
    }
    return Wrap(
      spacing: AppTheme.space2,
      runSpacing: AppTheme.space2,
      children: [
        SizedBox(width: 300, child: search),
        filterButton,
        if (filtersVisible) ...[
          SizedBox(width: 220, child: service),
          SizedBox(width: 210, child: status),
        ],
      ],
    );
  }

  Widget _contractCard(BuildContext context, ContratoModel contract) =>
      Container(
        padding: const EdgeInsets.all(AppTheme.space4),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.line),
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(contract.folio,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                _statusBadge(contract.estadoNombre),
              ],
            ),
            const SizedBox(height: AppTheme.space2),
            Text(contract.clienteNombre),
            const SizedBox(height: AppTheme.space2),
            _detail('Servicio', contract.servicioNombre),
            _detail('Asesor', contract.asesorNombre),
            _detail('Fecha', _date(contract.fechaContrato)),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => context.go('/contratos/${contract.id}'),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Ver detalle'),
              ),
            ),
          ],
        ),
      );

  Widget _detail(String label, String value) => Padding(
        padding: const EdgeInsets.only(top: AppTheme.space1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 74, child: Text(label)),
            Expanded(child: Text(value)),
          ],
        ),
      );

  Widget _statusBadge(String status) {
    final tone = switch (status) {
      'Activo' => AppBadgeTone.success,
      'Pago pendiente' || 'En proceso' => AppBadgeTone.warning,
      'Pausado' => AppBadgeTone.danger,
      _ => AppBadgeTone.neutral,
    };
    return AppBadge(label: status, tone: tone);
  }

  String _date(DateTime date) => '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
