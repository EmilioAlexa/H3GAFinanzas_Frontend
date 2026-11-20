import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/responsive/window_size_class.dart';
import '../../../../core/utils/dialog_lifecycle.dart';
import '../../../../core/network/api_error_model.dart';
import '../../repositories/clientes_repository.dart';
import 'package:dio/dio.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_data_column.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_filter_button.dart';
import '../../../../core/widgets/app_filter_dropdown.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_responsive_collection.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../../auth/auth.dart';
import '../../../contratos/fixtures/contratos_demo_fixtures.dart';
import '../../../pagos/fixtures/pagos_demo_fixtures.dart';
import '../../controllers/clientes_controller.dart';
import '../../models/cliente_model.dart';

class ClientesPage extends ConsumerStatefulWidget {
  const ClientesPage({super.key});

  @override
  ConsumerState<ClientesPage> createState() => _ClientesPageState();
}

enum _ClientAction {
  view,
  edit,
  toggleStatus,
  delete
}

enum _ClientDialogMode { create, edit, view }

class _ClientesPageState extends ConsumerState<ClientesPage> {
  bool get _demoMode => ref.read(clientesRepositoryProvider).demoMode;
  static const _pageSize = 5;
  final _searchController = TextEditingController();

  String _query = '';
  String _statusFilter = 'Todos los estados';
  String _serviceFilter = 'Todos los servicios';
  int _page = 1;
  bool? _filtersExpanded;
  Timer? _searchDebounce;
  UserRole? _activeRole;

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
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
        _activeRole = session.role;
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
          final filtered = _demoMode ? _filter(clients) : clients;
          final hasFilters = _query.trim().isNotEmpty ||
              _statusFilter != 'Todos los estados' ||
              _serviceFilter != 'Todos los servicios';
          final controller =
              ref.read(clientesControllerProvider(role).notifier);
          final visibleTotal = _demoMode
              ? (hasFilters ? filtered.length : 326)
              : controller.total;
          final pageCount = _demoMode
              ? (visibleTotal == 0 ? 1 : (visibleTotal / _pageSize).ceil())
              : (controller.totalPages == 0 ? 1 : controller.totalPages);
          if (_page > pageCount) _page = pageCount;
          final start = (_page - 1) * _pageSize;
          final pageItems = !_demoMode
              ? filtered
              : hasFilters
                  ? filtered.skip(start).take(_pageSize).toList()
                  : filtered.isEmpty
                      ? <ClienteModel>[]
                      : List.generate(
                          _pageSize,
                          (index) =>
                              filtered[(start + index) % filtered.length],
                        );
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.space6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppPageHeader(
                  eyebrow: 'Directorio',
                  title: 'Clientes',
                  description: 'Información compartida desde H3GA Ruta.',
                  actions: [
                    if (role == UserRole.asesor)
                      FilledButton.icon(
                        onPressed: () => _showClientDialog(
                          context,
                          role,
                          mode: _ClientDialogMode.create,
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Registrar cliente'),
                      ),
                  ],
                ),
                if (_demoMode)
                  _summary(context)
                else
                  Wrap(
                    spacing: AppTheme.space5,
                    runSpacing: AppTheme.space2,
                    children: [
                      Text('${controller.total} clientes',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      _summaryLabel(
                          context, 'Activos: —', AppTheme.successBase),
                      _summaryLabel(
                          context, 'En seguimiento: —', AppTheme.warningBase),
                    ],
                  ),
                const SizedBox(height: AppTheme.space4),
                _listPanel(
                  context,
                  role: role,
                  clients: pageItems,
                  filteredCount: visibleTotal,
                  totalCount: _demoMode
                      ? (hasFilters ? clients.length : 326)
                      : controller.total,
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
    required UserRole role,
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    value: (client) => _clientMenu(context, role, client),
                  ),
                ],
                compactCardBuilder: (context, client) => _clientCard(
                  context,
                  role,
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
    final filtersVisible = _filtersExpanded ?? false;
    final search = TextField(
      key: const Key('clientes-search'),
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _query = value;
          _page = 1;
        });
        if (!_demoMode && _activeRole != null) {
          _searchDebounce?.cancel();
          _searchDebounce = Timer(
              const Duration(milliseconds: 400),
              () => ref
                  .read(clientesControllerProvider(_activeRole!).notifier)
                  .search(value));
        }
      },
      decoration: const InputDecoration(
        hintText: 'Buscar por nombre, folio o CURP…',
        prefixIcon: Icon(Icons.search),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
    final filterButton = AppFilterButton(
      expanded: filtersVisible,
      onPressed: () => setState(() => _filtersExpanded = !filtersVisible),
    );
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(child: search),
            const SizedBox(width: AppTheme.space2),
            if (_demoMode) filterButton,
          ]),
          if (filtersVisible) ...[
            const SizedBox(height: AppTheme.space3),
            _filterDropdowns(context),
          ],
        ],
      );
    }
    return Wrap(
      alignment: WrapAlignment.start,
      spacing: 8,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(width: 330, child: search),
        if (_demoMode) filterButton,
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

  Widget _clientCard(
    BuildContext context,
    UserRole role,
    ClienteModel client,
  ) =>
      Container(
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
                _clientMenu(context, role, client),
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
    final status = client.demoMetadata?.status ??
        (client.pausado == null
            ? null
            : (client.pausado! ? 'Pausado' : 'Activo'));
    if (status == null) return const SizedBox.shrink();
    final tone = switch (status) {
      'Activo' => AppBadgeTone.success,
      'Pausado' => AppBadgeTone.danger,
      _ => AppBadgeTone.warning,
    };
    return AppBadge(label: status, tone: tone);
  }

  Widget _clientMenu(
    BuildContext context,
    UserRole role,
    ClienteModel client,
  ) =>
      PopupMenuButton<_ClientAction>(
        tooltip: 'Acciones de ${client.nombreCompleto}',
        onSelected: (action) async {
          switch (action) {
            case _ClientAction.view:
              await _showClientDialog(context, role,
                  client: client, mode: _ClientDialogMode.view);
            case _ClientAction.edit:
              await _showClientDialog(context, role,
                  client: client, mode: _ClientDialogMode.edit);
            case _ClientAction.toggleStatus:
              await _confirmStatusToggle(context, role, client);
            case _ClientAction.delete:
              await _confirmDelete(context, role, client);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: _ClientAction.view,
            child: Text('Ver cliente'),
          ),
          if (role == UserRole.administrador || role == UserRole.asesor)
            const PopupMenuItem(
              value: _ClientAction.edit,
              child: Text('Editar cliente'),
            ),
          if (role == UserRole.administrador ||
              role == UserRole.administradorFinanciero)
            PopupMenuItem(
              value: _ClientAction.toggleStatus,
              child: Text(
                  (client.pausado ?? (client.demoMetadata?.status == 'Pausado'))
                      ? 'Activar cliente'
                      : 'Pausar cliente'),
            ),
          if (_canDeleteClient(role, client))
            const PopupMenuItem(
              value: _ClientAction.delete,
              child: Text('Eliminar cliente'),
            ),
        ],
      );

  bool _canDeleteClient(UserRole role, ClienteModel client) =>
      (role == UserRole.administrador ||
          role == UserRole.administradorFinanciero) &&
      (!_demoMode ||
          (client.demoMetadata?.status == 'Pausado' &&
              !_hasRelatedRecords(client.id)));

  bool _hasRelatedRecords(String clientId) {
    final hasContract = ContratosDemoFixtures.contracts
        .any((contract) => contract.clienteId == clientId);
    if (hasContract) return true;
    final contractIds = ContratosDemoFixtures.contracts
        .where((contract) => contract.clienteId == clientId)
        .map((contract) => contract.id)
        .toSet();
    return PagosDemoFixtures.payments
        .any((payment) => contractIds.contains(payment.contratoId));
  }

  Future<void> _confirmStatusToggle(
    BuildContext context,
    UserRole role,
    ClienteModel client,
  ) async {
    final paused = client.pausado ?? (client.demoMetadata?.status == 'Pausado');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: paused ? 'Activar cliente' : 'Pausar cliente',
        description: paused
            ? 'El cliente volverÃ¡ a aparecer como activo.'
            : 'El cliente dejarÃ¡ de aparecer como activo.',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(paused ? 'Activar' : 'Pausar'),
          ),
        ],
        child:
            Text('Â¿Confirmas cambiar el estado de ${client.nombreCompleto}?'),
      ),
    );
    if (confirmed != true || !mounted || !context.mounted) return;
    await waitForDialogDismissal();
    if (!mounted || !context.mounted) return;
    try {
      if (!_demoMode) {
        await ref
            .read(clientesControllerProvider(role).notifier)
            .setPaused(client);
        ref.invalidate(clienteDetalleProvider(client.id));
        return;
      }
      ref.read(clientesControllerProvider(role).notifier).toggleStatusDemo(
            client.id,
          );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error is StateError
              ? error.message
              : ApiErrorModel.fromObject(error).message)));
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    UserRole role,
    ClienteModel client,
  ) async {
    if (!_canDeleteClient(role, client)) return;
    if (!_demoMode) {
      await _previewDelete(context, role, client);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: 'Eliminar cliente',
        description: 'Esta acción no se puede deshacer.',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
        child: Text(
          '¿Confirmas eliminar a ${client.nombreCompleto}?',
        ),
      ),
    );
    if (confirmed != true || !mounted || !context.mounted) return;
    await waitForDialogDismissal();
    if (!mounted || !context.mounted) return;
    try {
      ref.read(clientesControllerProvider(role).notifier).deleteDemo(client.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente eliminado.')),
      );
    } on StateError catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _previewDelete(
      BuildContext context, UserRole role, ClienteModel client) async {
    final repository = ref.read(clientesRepositoryProvider);
    try {
      final preview = await repository.dependencies(client.id);
      if (!context.mounted) return;
      final blocking = (preview['bloqueantes'] as List<dynamic>?) ?? [];
      final allowed = preview['apto_para_eliminacion'] == true;
      final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
                title: const Text('Dependencias del cliente'),
                content: SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(allowed
                          ? 'No hay dependencias bloqueantes. ¿Deseas eliminar este cliente?'
                          : 'El cliente conserva dependencias y no puede eliminarse.'),
                      for (final item in blocking)
                        Text('${item['tabla']}: ${item['cantidad']}'),
                      const Text(
                          'Las dependencias se comprueban de nuevo al confirmar.'),
                    ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancelar')),
                  if (allowed)
                    FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('Eliminar'))
                ],
              ));
      if (confirmed != true || !context.mounted) return;
      await repository.delete(client.id);
      await ref.read(clientesControllerProvider(role).notifier).load();
      if (context.mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Cliente eliminado.')));
    } catch (error) {
      if (!context.mounted) return;
      if (error is DioException && error.response?.statusCode == 409) {
        final body = error.response?.data;
        final dependencies = body is Map && body['dependencias'] is List
            ? body['dependencias'] as List
            : <dynamic>[];
        await showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
                    title: const Text('La eliminación presenta un conflicto'),
                    content: Text(dependencies.isEmpty
                        ? 'Actualiza la vista de dependencias e inténtalo de nuevo.'
                        : dependencies
                            .map((e) => '${e['tabla']}: ${e['cantidad']}')
                            .join('\n')),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cerrar'))
                    ]));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ApiErrorModel.fromObject(error).message)));
      }
    }
  }

  Future<void> _showClientDialog(
    BuildContext context,
    UserRole role, {
    ClienteModel? client,
    required _ClientDialogMode mode,
  }) async {
    if (!_demoMode &&
        mode == _ClientDialogMode.create &&
        role != UserRole.asesor) return;
    if (!_demoMode && client != null) {
      try {
        client = await ref.read(clientesRepositoryProvider).detail(client.id);
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ApiErrorModel.fromObject(error).message)),
          );
        }
        return;
      }
      if (!context.mounted || !mounted) return;
    }
    final canEdit = client == null ||
        role == UserRole.administrador ||
        (role == UserRole.asesor &&
            (!_demoMode ||
                (client.demoMetadata?.assignedToCurrentAdvisor ?? false)));
    if (mode == _ClientDialogMode.edit && !canEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No tienes permiso para editar este cliente.')),
      );
      return;
    }
    final formKey = GlobalKey<FormState>();
    var nombre = client?.nombre ?? '';
    var apellidoPaterno = client?.apellidoPaterno ?? '';
    var apellidoMaterno = client?.apellidoMaterno ?? '';
    var telefono = client?.telefono ?? '';
    var correo = client?.correoElectronico ?? '';
    var curp = client?.curp ?? '';
    var rfc = client?.rfc ?? '';
    var nacimiento = _dateInput(client?.fechaNacimiento);
    var direccion = client?.direccion ?? '';
    var referido = client?.referidoPor ?? '';
    var observaciones = client?.observaciones ?? '';
    var saving = false;
    final nacimientoController = TextEditingController(text: nacimiento);
    final readOnly = mode == _ClientDialogMode.view;
    final title = switch (mode) {
      _ClientDialogMode.create => 'Registrar cliente',
      _ClientDialogMode.edit => 'Editar cliente',
      _ClientDialogMode.view => 'Datos del cliente',
    };
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AppDialog(
          title: title,
          description: client?.nombreCompleto,
          maxWidth: 760,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(readOnly ? 'Cerrar' : 'Cancelar'),
            ),
            if (!readOnly)
              FilledButton.icon(
                onPressed: () async {
                  if (saving) return;
                  if (!formKey.currentState!.validate()) return;
                  formKey.currentState!.save();
                  final controller = ref.read(
                    clientesControllerProvider(role).notifier,
                  );
                  if (!_demoMode) {
                    saving = true;
                    try {
                      final model = ClienteModel(
                        id: client?.id ?? '',
                        nombre: nombre,
                        apellidoPaterno: apellidoPaterno,
                        apellidoMaterno: _nullable(apellidoMaterno),
                        telefono: _nullable(telefono),
                        correoElectronico: _nullable(correo),
                        curp: _nullable(curp),
                        rfc: _nullable(rfc),
                        fechaNacimiento: _parseDate(nacimiento),
                        direccion: _nullable(direccion),
                        referidoPor: _nullable(referido),
                        observaciones: _nullable(observaciones),
                      );
                      final saved =
                          await controller.save(model, editing: client != null);
                      ref.invalidate(clienteDetalleProvider(saved.id));
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Datos admitidos por la API guardados.')),
                        );
                      }
                    } catch (error) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                              content: Text(
                                  ApiErrorModel.fromObject(error).message)),
                        );
                      }
                    } finally {
                      saving = false;
                    }
                    return;
                  }
                  final updatedClient = client == null
                      ? null
                      : ClienteModel(
                          id: client.id,
                          nombre: nombre,
                          apellidoPaterno: apellidoPaterno,
                          apellidoMaterno: _nullable(apellidoMaterno),
                          telefono: _nullable(telefono),
                          correoElectronico: _nullable(correo),
                          curp: _nullable(curp),
                          rfc: _nullable(rfc),
                          fechaNacimiento: _parseDate(nacimiento),
                          direccion: _nullable(direccion),
                          referidoPor: _nullable(referido),
                          observaciones: _nullable(observaciones),
                          demoMetadata: (
                            status: client.demoMetadata?.status ?? 'Activo',
                            advisorName:
                                client.demoMetadata?.advisorName,
                            service: client.demoMetadata?.service,
                            assignedToCurrentAdvisor:
                                client.demoMetadata?.assignedToCurrentAdvisor ??
                                    false,
                          ),
                        );
                  Navigator.pop(dialogContext);
                  await waitForDialogDismissal();
                  if (!mounted) return;
                  if (updatedClient == null) {
                    controller.createDemo(
                      nombre: nombre,
                      apellidoPaterno: apellidoPaterno,
                      apellidoMaterno: _nullable(apellidoMaterno),
                      telefono: _nullable(telefono),
                      correoElectronico: _nullable(correo),
                      curp: _nullable(curp),
                      rfc: _nullable(rfc),
                      fechaNacimiento: _parseDate(nacimiento),
                    );
                  } else {
                    controller.updateDemo(updatedClient);
                  }
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Guardar'),
              ),
          ],
          child: Form(
            key: formKey,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth > 520
                    ? (constraints.maxWidth - AppTheme.space3) / 2
                    : constraints.maxWidth;
                Widget field(
                  String label,
                  String value,
                  ValueChanged<String> onSaved, {
                  TextInputType? keyboardType,
                  int maxLines = 1,
                  String? Function(String?)? validator,
                  bool enabled = true,
                  bool unavailable = false,
                  List<TextInputFormatter>? inputFormatters,
                }) =>
                    SizedBox(
                      width: width,
                      child: TextFormField(
                        initialValue: value,
                        enabled: enabled && !readOnly && !unavailable,
                        keyboardType: keyboardType,
                        maxLines: maxLines,
                        inputFormatters: inputFormatters,
                        decoration: InputDecoration(
                            labelText: label,
                            helperText: unavailable
                                ? 'Aún no disponible para guardar'
                                : null),
                        validator: unavailable ? null : validator,
                        onSaved: (value) => onSaved(value?.trim() ?? ''),
                      ),
                    );
                Widget dateField(
                  String label,
                  TextEditingController controller,
                  ValueChanged<String> onSaved,
                ) =>
                    SizedBox(
                      width: width,
                      child: TextFormField(
                        controller: controller,
                        readOnly: true,
                        enabled: !readOnly,
                        decoration: InputDecoration(
                          labelText: label,
                          suffixIcon: const Icon(Icons.calendar_today_outlined),
                        ),
                        onTap: readOnly
                            ? null
                            : () async {
                                final now = DateTime.now();
                                final stored = _parseDate(controller.text);
                                final initial =
                                    stored == null || stored.isAfter(now)
                                        ? now
                                        : stored;
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: initial,
                                  firstDate: DateTime(1900),
                                  lastDate: now,
                                );
                                if (picked != null) {
                                  controller.text = _date(picked);
                                }
                              },
                        onSaved: (value) => onSaved(value?.trim() ?? ''),
                      ),
                    );
                return Wrap(
                  spacing: AppTheme.space3,
                  runSpacing: AppTheme.space3,
                  children: [
                    field('Nombre *', nombre, (value) => nombre = value,
                        validator: _required),
                    field('Apellido paterno *', apellidoPaterno,
                        (value) => apellidoPaterno = value,
                        validator: _required),
                    field('Apellido materno *', apellidoMaterno,
                        (value) => apellidoMaterno = value,
                        validator: _required),
                    field('Teléfono *', telefono, (value) => telefono = value,
                        keyboardType: TextInputType.phone,
                        validator: _required),
                    field(
                        'Correo electrónico', correo, (value) => correo = value,
                        keyboardType: TextInputType.emailAddress,
                        validator: _emailValidator),
                    field('CURP', curp, (value) => curp = value,
                        inputFormatters:
                            _identifierFormatters(18, allowAmpersand: false),
                        validator: (value) {
                      final text = value?.trim().toUpperCase() ?? '';
                      if (text.isEmpty) return null;
                      return RegExp(r'^[A-ZÑ]{4}\d{2}(?:0[1-9]|1[0-2])(?:0[1-9]|[12]\d|3[01])[HM][A-Z]{5}[A-Z0-9]\d$')
                              .hasMatch(text)
                          ? null
                          : 'Ingresa una CURP válida de 18 caracteres.';
                    }),
                    field('RFC', rfc, (value) => rfc = value,
                        inputFormatters:
                            _identifierFormatters(13, allowAmpersand: true),
                        validator: (value) {
                      final text = value?.trim().toUpperCase() ?? '';
                      if (text.isEmpty) return null;
                      return RegExp(r'^[A-ZÑ&]{3,4}\d{2}(?:0[1-9]|1[0-2])(?:0[1-9]|[12]\d|3[01])[A-Z0-9]{3}$')
                              .hasMatch(text)
                          ? null
                          : 'Ingresa un RFC válido de 12 o 13 caracteres.';
                    }),
                    dateField('Fecha de nacimiento *', nacimientoController,
                        (value) => nacimiento = value),
                    field('Dirección', direccion, (value) => direccion = value,
                        maxLines: 2),
                    field('Referido por', referido, (value) => referido = value),
                    field('Observaciones', observaciones,
                        (value) => observaciones = value,
                        maxLines: 3),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await waitForDialogDismissal();
    } finally {
      nacimientoController.dispose();
    }
  }

  String _dateInput(DateTime? date) => date == null ? '' : _date(date);

  String _date(DateTime date) => '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  DateTime? _parseDate(String value) {
    final parts = value.split('/');
    if (parts.length != 3) return null;
    return DateTime.tryParse('${parts[2]}-${parts[1]}-${parts[0]}');
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo obligatorio' : null;

  List<TextInputFormatter> _identifierFormatters(int length,
          {required bool allowAmpersand}) =>
      [
        FilteringTextInputFormatter.allow(
            RegExp(allowAmpersand ? r'[a-zA-Z0-9Ññ&]' : r'[a-zA-Z0-9Ññ]')),
        LengthLimitingTextInputFormatter(length),
        TextInputFormatter.withFunction((oldValue, newValue) =>
            newValue.copyWith(text: newValue.text.toUpperCase())),
      ];

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())
        ? null
        : 'Correo no vÃ¡lido';
  }

  String? _nullable(String value) => value.trim().isEmpty ? null : value.trim();

  Widget _pagination(
    BuildContext context,
    int filteredCount,
    int totalCount,
    int page,
    int pageCount,
  ) {
    final pageSize = _demoMode ? _pageSize : 20;
    final first = filteredCount == 0 ? 0 : (page - 1) * pageSize + 1;
    final last = (page * pageSize).clamp(0, filteredCount);
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
              onPressed: page > 1
                  ? () {
                      setState(() => _page--);
                      if (!_demoMode && _activeRole != null)
                        ref
                            .read(clientesControllerProvider(_activeRole!)
                                .notifier)
                            .goToPage(_page);
                    }
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text('$page de $pageCount'),
            IconButton(
              tooltip: 'Página siguiente',
              onPressed: page < pageCount
                  ? () {
                      setState(() => _page++);
                      if (!_demoMode && _activeRole != null)
                        ref
                            .read(clientesControllerProvider(_activeRole!)
                                .notifier)
                            .goToPage(_page);
                    }
                  : null,
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
