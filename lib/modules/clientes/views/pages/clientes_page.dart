import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/responsive/window_size_class.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_data_column.dart';
import '../../../../core/widgets/app_filter_dropdown.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_responsive_collection.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../../auth/auth.dart';
import '../../controllers/clientes_controller.dart';
import '../../models/cliente_model.dart';

class ClientesPage extends ConsumerStatefulWidget {
  const ClientesPage({super.key});

  @override
  ConsumerState<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends ConsumerState<ClientesPage> {
  static const _pageSize = 5;
  final _searchController = TextEditingController();

  String _query = '';
  String _statusFilter = 'Todos los estados';
  String _serviceFilter = 'Todos los servicios';
  int _page = 1;
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
        icon: Icons.person_off_outlined,
        title: 'No se pudo cargar la sesión',
        message: 'Vuelve a iniciar sesión para consultar los clientes.',
      ),
      data: (session) {
        if (session == null) {
          return const AppStatePanel(
            icon: Icons.lock_outline,
            title: 'Inicia sesión para continuar',
            message: 'Clientes requiere una sesión activa.',
          );
        }
        final state = ref.watch(clientesControllerProvider(session.role));
        return state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => AppStatePanel(
            icon: Icons.cloud_off_outlined,
            title: 'No se pudo cargar la lista',
            message: 'Inténtalo de nuevo.',
            action: TextButton.icon(
              onPressed: () => ref
                  .read(clientesControllerProvider(session.role).notifier)
                  .load(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ),
          data: (clients) => clients == null
              ? const AppStatePanel(
                  icon: Icons.people_outline,
                  title: 'Sin clientes disponibles',
                  message: 'No fue posible consultar el directorio.',
                )
              : _content(context, clients, session.role),
        );
      },
    );
  }

  Widget _content(
    BuildContext context,
    List<ClienteModel> clients,
    UserRole role,
  ) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final widthClass = Responsive.of(context);
          final filtered = _filter(clients);
          final hasFilters = _query.trim().isNotEmpty ||
              _statusFilter != 'Todos los estados' ||
              _serviceFilter != 'Todos los servicios';
          final visibleTotal = hasFilters ? filtered.length : 326;
          final pageCount =
              visibleTotal == 0 ? 1 : (visibleTotal / _pageSize).ceil();
          if (_page > pageCount) _page = pageCount;
          final start = (_page - 1) * _pageSize;
          final pageItems = hasFilters
              ? filtered.skip(start).take(_pageSize).toList()
              : filtered.isEmpty
                  ? <ClienteModel>[]
                  : List.generate(
                      _pageSize,
                      (index) => filtered[(start + index) % filtered.length],
                    );
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.space6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppPageHeader(
                  eyebrow: 'Directorio',
                  title: 'Clientes',
                  description: 'Información compartida desde H3GA Ruta.',
                  actions: [],
                ),
                _summary(context),
                const SizedBox(height: AppTheme.space4),
                _listPanel(
                  context,
                  clients: pageItems,
                  filteredCount: visibleTotal,
                  totalCount: hasFilters ? clients.length : 326,
                  page: _page,
                  pageCount: pageCount,
                  widthClass: widthClass,
                ),
              ],
            ),
          );
        },
      );

  List<ClienteModel> _filter(List<ClienteModel> clients) {
    final query = _query.trim().toLowerCase();
    return clients.where((client) {
      final matchesQuery = query.isEmpty ||
          '${client.nombre} ${client.apellidoPaterno} '
                  '${client.apellidoMaterno ?? ''} '
                  '${client.correoElectronico ?? ''}'
              .toLowerCase()
              .contains(query);
      final metadata = client.demoMetadata;
      final matchesStatus = _statusFilter == 'Todos los estados' ||
          metadata?.status == _statusFilter;
      final matchesService = _serviceFilter == 'Todos los servicios' ||
          metadata?.service == _serviceFilter;
      return matchesQuery && matchesStatus && matchesService;
    }).toList();
  }

  Widget _summary(BuildContext context) {
    return Wrap(
      spacing: AppTheme.space5,
      runSpacing: AppTheme.space2,
      children: [
        const Text.rich(
          TextSpan(
            text: '326 ',
            style: TextStyle(fontWeight: FontWeight.w700),
            children: [TextSpan(text: 'clientes')],
          ),
        ),
        _summaryLabel(context, '284 activos', AppTheme.successBase),
        _summaryLabel(context, '18 en seguimiento', AppTheme.warningBase),
      ],
    );
  }

  Widget _summaryLabel(BuildContext context, String label, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 9, color: color),
          const SizedBox(width: AppTheme.space2),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      );

  Widget _listPanel(
    BuildContext context, {
    required List<ClienteModel> clients,
    required int filteredCount,
    required int totalCount,
    required int page,
    required int pageCount,
    required WindowSizeClass widthClass,
  }) =>
      Container(
        padding: const EdgeInsets.all(AppTheme.space4),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: AppTheme.line),
          boxShadow: AppTheme.elevation,
        ),
        child: Column(
          children: [
            _filters(context, widthClass),
            const Divider(height: AppTheme.space6),
            if (filteredCount == 0)
              const AppStatePanel(
                icon: Icons.search_off_outlined,
                title: 'Sin clientes para mostrar',
                message: 'Prueba con otro nombre o limpia los filtros.',
              )
            else
              AppResponsiveCollection<ClienteModel>(
                rows: clients,
                columns: [
                  AppDataColumn<ClienteModel>(
                    label: 'Cliente',
                    flex: 3,
                    value: (client) => _personCell(context, client),
                  ),
                  AppDataColumn<ClienteModel>(
                    label: 'CURP / Teléfono',
                    flex: 3,
                    showOnMedium: false,
                    value: (client) => _contactCell(context, client),
                  ),
                  AppDataColumn<ClienteModel>(
                    label: 'Asesor',
                    flex: 2,
                    showOnMedium: false,
                    value: (client) => Text(
                      client.demoMetadata?.advisorName ?? '—',
                    ),
                  ),
                  AppDataColumn<ClienteModel>(
                    label: 'Servicio',
                    flex: 2,
                    showOnMedium: false,
                    value: (client) => Text(
                      client.demoMetadata?.service ?? '—',
                    ),
                  ),
                  AppDataColumn<ClienteModel>(
                    label: 'Estado',
                    flex: 2,
                    value: (client) => _statusBadge(client),
                  ),
                  AppDataColumn<ClienteModel>(
                    label: '',
                    flex: 1,
                    value: (client) => IconButton(
                      tooltip: 'Abrir cliente ${client.nombreCompleto}',
                      onPressed: () => _openClient(context, client),
                      icon: const Icon(Icons.more_horiz),
                    ),
                  ),
                ],
                compactCardBuilder: (context, client) => _clientCard(
                  context,
                  client,
                ),
                onRowTap: (client) => _openClient(context, client),
                emptyTitle: 'Sin clientes para mostrar',
              ),
            const Divider(height: AppTheme.space6),
            _pagination(context, filteredCount, totalCount, page, pageCount),
          ],
        ),
      );

  Widget _filters(BuildContext context, WindowSizeClass widthClass) {
    final compact = widthClass == WindowSizeClass.compacto;
    final filtersVisible = _filtersExpanded ?? !compact;
    final search = TextField(
      key: const Key('clientes-search'),
      controller: _searchController,
      onChanged: (value) => setState(() {
        _query = value;
        _page = 1;
      }),
      decoration: const InputDecoration(
        hintText: 'Buscar por nombre, folio o CURP…',
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
            const SizedBox(height: AppTheme.space3),
            _filterDropdowns(context),
          ],
        ],
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(width: 330, child: search),
        filterButton,
        if (filtersVisible) ...[
          SizedBox(width: 190, child: _statusDropdown()),
          SizedBox(width: 190, child: _serviceDropdown()),
        ],
      ],
    );
  }

  Widget _filterDropdowns(BuildContext context) => Column(
        children: [
          _statusDropdown(),
          const SizedBox(height: AppTheme.space2),
          _serviceDropdown(),
        ],
      );

  Widget _statusDropdown() => AppFilterDropdown<String>(
        value: _statusFilter,
        label: 'Estado',
        items: const [
          DropdownMenuItem(
            value: 'Todos los estados',
            child: Text('Todos los estados'),
          ),
          DropdownMenuItem(value: 'Activo', child: Text('Activo')),
          DropdownMenuItem(value: 'Seguimiento', child: Text('Seguimiento')),
          DropdownMenuItem(value: 'Pausado', child: Text('Pausado')),
        ],
        onChanged: (value) => setState(() {
          _statusFilter = value ?? 'Todos los estados';
          _page = 1;
        }),
      );

  Widget _serviceDropdown() => AppFilterDropdown<String>(
        value: _serviceFilter,
        label: 'Servicio',
        items: const [
          DropdownMenuItem(
            value: 'Todos los servicios',
            child: Text('Todos los servicios'),
          ),
          DropdownMenuItem(value: 'Modalidad 10', child: Text('Modalidad 10')),
          DropdownMenuItem(value: 'Modalidad 40', child: Text('Modalidad 40')),
          DropdownMenuItem(value: 'APD', child: Text('APD')),
          DropdownMenuItem(
            value: 'M40 Retroactiva',
            child: Text('M40 Retroactiva'),
          ),
        ],
        onChanged: (value) => setState(() {
          _serviceFilter = value ?? 'Todos los servicios';
          _page = 1;
        }),
      );

  Widget _personCell(BuildContext context, ClienteModel client) => Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.accentSoft,
            foregroundColor: AppTheme.primary,
            child: Text(_initials(client.nombreCompleto)),
          ),
          const SizedBox(width: AppTheme.space2),
          Flexible(
            child: Text(
              client.nombreCompleto,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );

  Widget _contactCell(BuildContext context, ClienteModel client) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (client.curp != null)
            Text(
              client.curp!,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          if (client.telefono != null)
            Text(
              client.telefono!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      );

  Widget _clientCard(BuildContext context, ClienteModel client) => Container(
        padding: const EdgeInsets.all(AppTheme.space4),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: AppTheme.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.accentSoft,
                  foregroundColor: AppTheme.primary,
                  child: Text(_initials(client.nombreCompleto)),
                ),
                const SizedBox(width: AppTheme.space2),
                Expanded(
                  child: Text(
                    client.nombreCompleto,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                _statusBadge(client),
              ],
            ),
            const SizedBox(height: AppTheme.space3),
            if (client.telefono != null)
              _detailLine('Teléfono', client.telefono!),
            if (client.correoElectronico != null)
              _detailLine('Correo', client.correoElectronico!),
            if (client.demoMetadata?.advisorName case final advisor?)
              _detailLine('Asesor', advisor),
            if (client.demoMetadata?.service case final service?)
              _detailLine('Servicio', service),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _openClient(context, client),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Ver detalle'),
              ),
            ),
          ],
        ),
      );

  Widget _detailLine(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.space2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 112, child: Text(label)),
            Expanded(child: Text(value)),
          ],
        ),
      );

  Widget _statusBadge(ClienteModel client) {
    final status = client.demoMetadata?.status;
    if (status == null) return const SizedBox.shrink();
    final tone = switch (status) {
      'Activo' => AppBadgeTone.success,
      'Pausado' => AppBadgeTone.danger,
      _ => AppBadgeTone.warning,
    };
    return AppBadge(label: status, tone: tone);
  }

  Widget _pagination(
    BuildContext context,
    int filteredCount,
    int totalCount,
    int page,
    int pageCount,
  ) {
    final first = filteredCount == 0 ? 0 : (page - 1) * _pageSize + 1;
    final last = (page * _pageSize).clamp(0, filteredCount);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppTheme.space3,
      runSpacing: AppTheme.space2,
      children: [
        Text('Mostrando $first–$last de $filteredCount clientes'),
        if (filteredCount != totalCount)
          TextButton(
            onPressed: () => setState(() {
              _query = '';
              _statusFilter = 'Todos los estados';
              _serviceFilter = 'Todos los servicios';
              _page = 1;
            }),
            child: const Text('Limpiar filtros'),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Página anterior',
              onPressed: page > 1 ? () => setState(() => _page--) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text('$page de $pageCount'),
            IconButton(
              tooltip: 'Página siguiente',
              onPressed:
                  page < pageCount ? () => setState(() => _page++) : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }

  String _initials(String fullName) {
    final parts = fullName.split(' ');
    if (parts.length < 2) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}'
        .toUpperCase();
  }

  void _openClient(BuildContext context, ClienteModel client) =>
      context.go('/clientes/${client.id}');
}
