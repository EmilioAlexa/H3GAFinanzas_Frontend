import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_data_column.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_metric_card.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_responsive_collection.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../../../core/widgets/app_tab_strip.dart';
import '../../controllers/usuarios_controller.dart';
import '../../models/usuario_model.dart';
import '../../repositories/usuarios_repository.dart';

class UsuariosPage extends ConsumerStatefulWidget {
  const UsuariosPage({super.key});

  @override
  ConsumerState<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends ConsumerState<UsuariosPage> {
  final _searchController = TextEditingController();
  String _statusFilter = 'Todos los estados';
  String _roleFilter = 'Todos los roles';
  int _selectedTab = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.read(usuariosRepositoryProvider);
    if (!ref.watch(usuariosDemoModeProvider)) {
      return const AppStatePanel(
        icon: Icons.link_off_outlined,
        title: 'Usuarios no disponibles',
        message: 'No fue posible consultar los usuarios y accesos.',
      );
    }
    final usersState = ref.watch(usuariosControllerProvider);
    return usersState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AppStatePanel(
        icon: Icons.error_outline,
        title: 'No se pudieron cargar los usuarios',
        message: error.toString(),
        action: TextButton(
          onPressed: () =>
              ref.read(usuariosControllerProvider.notifier).loadDemo(),
          child: const Text('Reintentar'),
        ),
      ),
      data: (users) => _buildContent(users, repository),
    );
  }

  Widget _buildContent(
      List<UsuarioModel> users, UsuariosRepository repository) {
    final active = users.where((user) => user.activo).length;
    final suspended = users.length - active;
    final admins =
        users.where((user) => user.rolId != 'demo-role-asesor').length;
    final query = _searchController.text.trim().toLowerCase();
    final filtered = users.where((user) {
      final matchesQuery = query.isEmpty ||
          '${user.nombreCompleto} ${user.correo} ${user.rolNombre}'
              .toLowerCase()
              .contains(query);
      final matchesStatus = _statusFilter == 'Todos los estados' ||
          (_statusFilter == 'Activos' && user.activo) ||
          (_statusFilter == 'Suspendidos' && !user.activo);
      final matchesRole =
          _roleFilter == 'Todos los roles' || user.rolNombre == _roleFilter;
      return matchesQuery && matchesStatus && matchesRole;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPageHeader(
            eyebrow: 'Administración',
            title: 'Usuarios y accesos',
            description:
                'Consulta perfiles y visualiza el alcance de cada rol.',
            actions: [
              FilledButton.icon(
                onPressed: () => _showUserForm(repository, users),
                icon: const Icon(Icons.add),
                label: const Text('Registrar usuario'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 54),
                  backgroundColor: AppTheme.secondaryDark,
                  foregroundColor: AppTheme.white,
                ),
              ),
            ],
          ),
          LayoutBuilder(builder: (context, constraints) {
            final metrics = [
              AppMetricCard(
                label: 'Usuarios activos',
                value: '$active',
                detail: 'Con acceso al sistema',
                icon: Icons.people_outline,
              ),
              AppMetricCard(
                label: 'Usuarios suspendidos',
                value: '$suspended',
                detail: 'Sin acceso mientras estén suspendidos',
                icon: Icons.warning_amber_rounded,
                tone: AppMetricTone.warning,
              ),
              AppMetricCard(
                label: 'Total de usuarios',
                value: '${users.length}',
                detail: '$admins perfiles administrativos',
                icon: Icons.settings_outlined,
                tone: AppMetricTone.info,
              ),
            ];
            if (Responsive.isCompact(constraints.maxWidth)) {
              return Column(children: [
                for (final metric in metrics) ...[
                  metric,
                  const SizedBox(height: AppTheme.space3),
                ],
              ]);
            }
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (var index = 0; index < metrics.length; index++) ...[
                Expanded(child: metrics[index]),
                if (index != metrics.length - 1)
                  const SizedBox(width: AppTheme.space3),
              ],
            ]);
          }),
          const SizedBox(height: AppTheme.space5),
          AppTabStrip(
            labels: const ['Usuarios', 'Roles y permisos'],
            counts: [users.length, null],
            selectedIndex: _selectedTab,
            onSelected: (index) => setState(() => _selectedTab = index),
          ),
          const SizedBox(height: AppTheme.space4),
          if (_selectedTab == 0)
            _userList(filtered, repository, users)
          else
            _rolePermissions(),
        ],
      ),
    );
  }

  Widget _userList(
    List<UsuarioModel> users,
    UsuariosRepository repository,
    List<UsuarioModel> allUsers,
  ) =>
      Card(
        clipBehavior: Clip.antiAlias,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.space4),
            child: LayoutBuilder(builder: (context, constraints) {
              final compact = Responsive.isCompact(constraints.maxWidth);
              final filterWidth = compact ? constraints.maxWidth : null;
              final search = SizedBox(
                width: compact ? double.infinity : 330,
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar por nombre, correo o rol...',
                    labelText: 'Buscar usuarios',
                  ),
                ),
              );
              final filters = Wrap(spacing: AppTheme.space2, children: [
                SizedBox(
                  width: filterWidth ?? 180,
                  child: DropdownButtonFormField<String>(
                    initialValue: _statusFilter,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: const [
                      'Todos los estados',
                      'Activos',
                      'Suspendidos',
                    ]
                        .map((value) =>
                            DropdownMenuItem(value: value, child: Text(value)))
                        .toList(),
                    onChanged: (value) => setState(
                        () => _statusFilter = value ?? 'Todos los estados'),
                  ),
                ),
                SizedBox(
                  width: filterWidth ?? 210,
                  child: DropdownButtonFormField<String>(
                    initialValue: _roleFilter,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Rol'),
                    items: [
                      'Todos los roles',
                      ...UsuariosRepository.roles.map((role) => role.nombre),
                    ]
                        .map((value) =>
                            DropdownMenuItem(value: value, child: Text(value)))
                        .toList(),
                    onChanged: (value) => setState(
                        () => _roleFilter = value ?? 'Todos los roles'),
                  ),
                ),
              ]);
              if (compact) {
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      search,
                      const SizedBox(height: AppTheme.space3),
                      filters,
                    ]);
              }
              return Wrap(
                  spacing: AppTheme.space3,
                  runSpacing: AppTheme.space3,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [search, filters]);
            }),
          ),
          const Divider(height: 1),
          if (users.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppTheme.space8),
              child: AppStatePanel(
                icon: Icons.search_off_outlined,
                title: 'No hay usuarios para mostrar',
                message: 'Cambia la búsqueda o los filtros seleccionados.',
              ),
            )
          else
            AppResponsiveCollection<UsuarioModel>(
              rows: users,
              onRowTap: (user) => _showDetails(user, repository, allUsers),
              columns: [
                AppDataColumn(
                  label: 'Usuario',
                  flex: 3,
                  value: (user) => _identity(user),
                ),
                AppDataColumn(
                  label: 'Correo',
                  flex: 3,
                  value: (user) => Text(user.correo),
                ),
                AppDataColumn(
                  label: 'Rol',
                  flex: 2,
                  value: (user) => Text(user.rolNombre),
                ),
                AppDataColumn(
                  label: 'Estado',
                  flex: 2,
                  value: (user) => _statusBadge(user.activo),
                ),
                AppDataColumn(
                  label: 'Último acceso',
                  flex: 2,
                  showOnMedium: false,
                  value: (user) => Text(user.ultimoAccesoDemo ?? 'Sin accesos'),
                ),
                AppDataColumn(
                  label: 'Acciones',
                  flex: 1,
                  value: (user) => _actionsMenu(user, repository, allUsers),
                ),
              ],
              compactCardBuilder: (context, user) => Container(
                padding: const EdgeInsets.all(AppTheme.space4),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  border: Border.all(color: AppTheme.line),
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        Expanded(child: _identity(user)),
                        _actionsMenu(user, repository, allUsers),
                      ]),
                      const SizedBox(height: AppTheme.space3),
                      Text(user.correo),
                      const SizedBox(height: AppTheme.space2),
                      Wrap(
                          spacing: AppTheme.space2,
                          runSpacing: AppTheme.space2,
                          children: [
                            Chip(label: Text(user.rolNombre)),
                            _statusBadge(user.activo),
                          ]),
                    ]),
              ),
            ),
        ]),
      );

  Widget _identity(UsuarioModel user) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(
          backgroundColor: AppTheme.accentSoft,
          foregroundColor: AppTheme.primary,
          child: Text(user.iniciales),
        ),
        const SizedBox(width: AppTheme.space3),
        Flexible(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              user.nombreCompleto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ]),
        ),
      ]);

  Widget _statusBadge(bool active) => AppBadge(
        label: active ? 'Activo' : 'Suspendido',
        tone: active ? AppBadgeTone.success : AppBadgeTone.danger,
      );

  Widget _actionsMenu(
    UsuarioModel user,
    UsuariosRepository repository,
    List<UsuarioModel> allUsers,
  ) =>
      PopupMenuButton<String>(
        tooltip: 'Acciones para ${user.nombreCompleto}',
        onSelected: (action) {
          switch (action) {
            case 'view':
              _showDetails(user, repository, allUsers);
            case 'edit':
              _showUserForm(repository, allUsers, user: user);
            case 'role':
              _showRoleDialog(user, repository);
            case 'status':
              _showStatusDialog(user);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'view', child: Text('Ver usuario')),
          const PopupMenuItem(value: 'edit', child: Text('Editar usuario')),
          const PopupMenuItem(value: 'role', child: Text('Cambiar rol')),
          PopupMenuItem(
            value: 'status',
            child: Text(user.activo ? 'Suspender usuario' : 'Activar usuario'),
          ),
        ],
        child: Semantics(
          label: 'Abrir acciones del usuario',
          button: true,
          child: const SizedBox(
            width: 48,
            height: 48,
            child: Icon(Icons.more_horiz, color: AppTheme.muted),
          ),
        ),
      );

  Widget _rolePermissions() {
    const permissions = <String, List<bool>>{
      'Inicio y clientes': [true, true, true],
      'Servicios y contratos': [true, true, true],
      'Seguimiento M10 / M40 / APD': [true, true, true],
      'Pagos y comisiones': [true, true, true],
      'Validación y cortes': [true, true, false],
      'Prenómina y reportes': [true, true, false],
      'Agregar y editar comisiones por contrato': [true, true, false],
      'Usuarios y accesos': [true, false, false],
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: AppTheme.space3),
      Card(
          child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(columns: const [
          DataColumn(label: Text('Módulo')),
          DataColumn(label: Text('Administrador')),
          DataColumn(label: Text('Admin. financiero')),
          DataColumn(label: Text('Asesor')),
        ], rows: [
          for (final entry in permissions.entries)
            DataRow(cells: [
              DataCell(Text(entry.key)),
              for (final allowed in entry.value)
                DataCell(Text(allowed ? 'Visible' : 'Oculto')),
            ]),
        ]),
      )),
    ]);
  }

  Future<void> _showDetails(
    UsuarioModel user,
    UsuariosRepository repository,
    List<UsuarioModel> users,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        alignment: Alignment.centerRight,
        insetPadding: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 500,
            minHeight: MediaQuery.sizeOf(context).height,
            maxHeight: MediaQuery.sizeOf(context).height,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space6),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    const Expanded(
                        child: Text('Información compartida con H3GA Ruta',
                            style: TextStyle(
                                color: AppTheme.secondaryDark,
                                fontWeight: FontWeight.w700))),
                    IconButton(
                        tooltip: 'Cerrar detalle',
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close)),
                  ]),
                  const SizedBox(height: AppTheme.space4),
                  Row(children: [
                    CircleAvatar(radius: 30, child: Text(user.iniciales)),
                    const SizedBox(width: AppTheme.space3),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(user.nombreCompleto,
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: AppTheme.space2),
                          _statusBadge(user.activo),
                        ])),
                  ]),
                  const SizedBox(height: AppTheme.space4),
                  _detailLine('Correo electrónico', user.correo),
                  _detailLine('Rol', user.rolNombre),
                  _detailLine(
                      'Fecha de creación',
                      DateFormat('dd/MM/yyyy', 'es_MX')
                          .format(user.fechaCreacion)),
                  const SizedBox(height: AppTheme.space3),
                  const SizedBox(height: AppTheme.space4),
                  const Spacer(),
                  Wrap(
                      alignment: WrapAlignment.end,
                      spacing: AppTheme.space2,
                      children: [
                        OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Cerrar')),
                        FilledButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              _showUserForm(repository, users, user: user);
                            },
                            child: const Text('Editar usuario')),
                      ]),
                ]),
          ),
        ),
      ),
    );
  }

  Widget _detailLine(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space3),
        child: Row(children: [
          Expanded(
              child:
                  Text(label, style: const TextStyle(color: AppTheme.muted))),
          const SizedBox(width: AppTheme.space3),
          Flexible(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
      );

  Future<void> _showUserForm(
    UsuariosRepository repository,
    List<UsuarioModel> users, {
    UsuarioModel? user,
  }) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: user?.nombre);
    final paternal = TextEditingController(text: user?.apellidoPaterno);
    final maternal = TextEditingController(text: user?.apellidoMaterno);
    final email = TextEditingController(text: user?.correo);
    final password = TextEditingController();
    var roleId = user?.rolId ?? UsuariosRepository.roles.last.id;
    var saving = false;
    var showPassword = false;
    UsuarioModel? createdUser;
    final controller = ref.read(usuariosControllerProvider.notifier);
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) => AppDialog(
                  title: user == null ? 'Registrar usuario' : 'Editar usuario',
                  description: user == null
                      ? 'Registra un nuevo usuario y asigna el rol correspondiente.'
                      : 'Actualiza los datos del usuario y su rol asignado.',
                  icon: user == null
                      ? Icons.person_add_alt_1_outlined
                      : Icons.assignment_outlined,
                  maxWidth: 672,
                  actions: [
                    TextButton(
                        onPressed:
                            saving ? null : () => Navigator.pop(dialogContext),
                        child: const Text('Cancelar')),
                    FilledButton.icon(
                      onPressed: saving
                          ? null
                          : () async {
                              if (!(formKey.currentState?.validate() ??
                                  false)) {
                                return;
                              }
                              setDialogState(() => saving = true);
                              try {
                                if (user == null) {
                                  createdUser = await controller.createDemo(
                                    nombre: name.text,
                                    apellidoPaterno: paternal.text,
                                    apellidoMaterno: maternal.text,
                                    correo: email.text,
                                    rolId: roleId,
                                    contrasena: 'Temporal123',
                                  );
                                } else {
                                  await controller.updateDemo(
                                    user.id,
                                    nombre: name.text,
                                    apellidoPaterno: paternal.text,
                                    apellidoMaterno: maternal.text,
                                    correo: email.text,
                                  );
                                  if (roleId != user.rolId) {
                                    await controller.changeRoleDemo(
                                      user.id,
                                      roleId,
                                    );
                                  }
                                }
                                if (dialogContext.mounted) {
                                  Navigator.pop(dialogContext);
                                }
                                if (mounted) {
                                  if (createdUser != null) {
                                    await _showCreateSuccess(createdUser!);
                                  } else {
                                    _message('Datos actualizados.');
                                  }
                                }
                              } catch (error) {
                                setDialogState(() => saving = false);
                                if (dialogContext.mounted) {
                                  _message(error.toString());
                                }
                              }
                            },
                      icon: const Icon(Icons.check),
                      label: Text(saving
                          ? 'Guardando...'
                          : user == null
                              ? 'Registrar usuario'
                              : 'Guardar cambios'),
                    ),
                  ],
                  child: SizedBox(
                    width: 520,
                    child: SingleChildScrollView(
                        child: Form(
                      key: formKey,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        _formField('Nombre', name, required: true),
                        LayoutBuilder(builder: (context, constraints) {
                          final paternalField = _formField(
                            'Apellido paterno',
                            paternal,
                            required: true,
                          );
                          final maternalField = _formField(
                            'Apellido materno',
                            maternal,
                          );
                          if (constraints.maxWidth < 520) {
                            return Column(
                              children: [paternalField, maternalField],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: paternalField),
                              const SizedBox(width: AppTheme.space3),
                              Expanded(child: maternalField),
                            ],
                          );
                        }),
                        _formField('Correo electrónico', email,
                            required: true,
                            email: true,
                            users: users,
                            currentUser: user),
                        ...[
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: roleId,
                            decoration: const InputDecoration(labelText: 'Rol'),
                            items: UsuariosRepository.roles
                                .map((role) => DropdownMenuItem(
                                    value: role.id, child: Text(role.nombre)))
                                .toList(),
                            onChanged: (value) => roleId = value ?? roleId,
                            validator: (value) =>
                                value == null ? 'Selecciona un rol.' : null,
                          ),
                          const SizedBox(height: AppTheme.space3),
                          if (!ref.read(usuariosDemoModeProvider))
                            TextFormField(
                              controller: password,
                              obscureText: !showPassword,
                              decoration: InputDecoration(
                                labelText: 'Contraseña inicial',
                                helperText: 'Mínimo 8 caracteres.',
                                suffixIcon: IconButton(
                                  tooltip: showPassword
                                      ? 'Ocultar contraseña'
                                      : 'Mostrar contraseña',
                                  onPressed: () => setDialogState(
                                      () => showPassword = !showPassword),
                                  icon: Icon(showPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                ),
                              ),
                              validator: (value) => (value?.length ?? 0) < 8
                                  ? 'Usa al menos 8 caracteres.'
                                  : null,
                            ),
                        ],
                        const SizedBox(height: AppTheme.space3),
                      ]),
                    )),
                  ),
                )),
      );
    } finally {
      name.dispose();
      paternal.dispose();
      maternal.dispose();
      email.dispose();
      password.dispose();
    }
  }

  Widget _formField(
    String label,
    TextEditingController controller, {
    bool required = false,
    bool email = false,
    List<UsuarioModel> users = const [],
    UsuarioModel? currentUser,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.space3),
        child: TextFormField(
          controller: controller,
          keyboardType: email ? TextInputType.emailAddress : TextInputType.name,
          decoration: InputDecoration(labelText: label),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (required && text.isEmpty) return 'Este campo es obligatorio.';
            if (email &&
                text.isNotEmpty &&
                !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
              return 'Escribe un correo electrónico válido.';
            }
            if (email &&
                users.any((user) =>
                    user.id != currentUser?.id &&
                    user.correo.toLowerCase() == text.toLowerCase())) {
              return 'Ese correo ya está registrado.';
            }
            return null;
          },
        ),
      );

  Future<void> _showCreateSuccess(UsuarioModel user) => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircleAvatar(
              radius: 36,
              backgroundColor: AppTheme.successBackground,
              child: Icon(Icons.check_circle_outline,
                  color: AppTheme.success, size: 34),
            ),
            const SizedBox(height: AppTheme.space4),
            Text(
              'Usuario registrado correctamente',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTheme.space3),
            Text(
              '${user.nombreCompleto} · ${user.rolNombre}\n${user.correo}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space4),
          ]),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      );

  Future<void> _showRoleDialog(
      UsuarioModel user, UsuariosRepository repository) async {
    var roleId = user.rolId;
    final next = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
                title: const Text('¿Cambiar rol?'),
                content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Confirma el cambio para ${user.nombreCompleto}.'),
                      const SizedBox(height: AppTheme.space4),
                      Text('Rol actual: ${user.rolNombre}'),
                      const SizedBox(height: AppTheme.space2),
                      DropdownButtonFormField<String>(
                        initialValue: roleId,
                        decoration:
                            const InputDecoration(labelText: 'Nuevo rol'),
                        items: UsuariosRepository.roles
                            .map((role) => DropdownMenuItem(
                                value: role.id, child: Text(role.nombre)))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => roleId = value ?? roleId),
                      ),
                    ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, roleId),
                      child: const Text('Confirmar cambio')),
                ],
              )),
    );
    if (next == null || next == user.rolId) return;
    await ref
        .read(usuariosControllerProvider.notifier)
        .changeRoleDemo(user.id, next);
    if (mounted) _message('Rol actualizado.');
  }

  Future<void> _showStatusDialog(UsuarioModel user) async {
    final active = !user.activo;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(active ? '¿Activar usuario?' : '¿Suspender usuario?'),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${user.nombreCompleto} · ${user.correo}'),
              const SizedBox(height: AppTheme.space3),
              Text(active
                  ? 'El perfil recuperará el acceso al sistema.'
                  : 'El perfil perderá acceso al sistema.'),
            ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
            style: active
                ? null
                : FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(active ? 'Activar usuario' : 'Suspender usuario'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await ref
        .read(usuariosControllerProvider.notifier)
        .changeStatusDemo(user.id, active);
    if (mounted) {
      _message(active ? 'Usuario activado.' : 'Usuario suspendido.');
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
