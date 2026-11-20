import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/config/env.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/network/api_error_model.dart';
import '../../../../core/platform/file_platform_factory.dart';
import '../../../../core/platform/selected_file.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../../auth/auth.dart';
import '../../controllers/contrato_options_controller.dart';
import '../../controllers/contratos_controller.dart';
import '../../fixtures/contratos_demo_fixtures.dart';
import '../../models/contrato_model.dart';
import '../../models/servicio_model.dart';

const _demoClients = <({String id, String name})>[
  (id: 'demo-client-1', name: 'Elena Robles Vargas'),
  (id: 'demo-client-2', name: 'Carlos Mendoza Ruiz'),
  (id: 'demo-client-3', name: 'Sofía Ramírez León'),
  (id: 'demo-client-4', name: 'Javier Torres Luna'),
  (id: 'demo-client-5', name: 'María Salgado Pérez'),
];

const _demoAdvisors = <({String id, String name})>[
  (id: 'demo-advisor-1', name: 'Daniela Cruz'),
  (id: 'demo-advisor-2', name: 'Jorge Silva'),
  (id: 'demo-advisor-3', name: 'Mónica Ruiz'),
];

class ContratoFormPage extends ConsumerStatefulWidget {
  const ContratoFormPage({this.contratoId, super.key});

  final String? contratoId;

  @override
  ConsumerState<ContratoFormPage> createState() => _ContratoFormPageState();
}

class _ContratoFormPageState extends ConsumerState<ContratoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _folioController = TextEditingController();
  final _observationsController = TextEditingController();
  final _dailySalaryController = TextEditingController();
  final _monthlyAmountController = TextEditingController();
  final List<SelectedFile> _documents = [];

  List<ContractPerson> _clients = AppEnv.demoMode ? _demoClients : [];
  List<ContractPerson> _advisors = AppEnv.demoMode ? _demoAdvisors : [];
  List<ServicioModel> _services =
      AppEnv.demoMode ? ContratosDemoFixtures.services : [];
  List<({int id, String name})> _states =
      AppEnv.demoMode ? [(id: 1, name: 'Activo')] : [];
  int? _selectedStateId;
  String? _optionsMessage;
  bool _saving = false;
  String? _selectedClientId = AppEnv.demoMode ? _demoClients.first.id : null;
  int? _selectedServiceId = AppEnv.demoMode ? 40 : null;
  String? _selectedAdvisorId = AppEnv.demoMode ? _demoAdvisors.first.id : null;
  String _saleType = 'Cambaceo';
  String _paymentScheme = 'Mensual';
  String _contractPeriod = '12 meses';
  DateTime? _selectedDate;
  DateTime? _estimatedEndDate;
  String? _fileError;
  String? _initializedContractId;

  @override
  void dispose() {
    _folioController.dispose();
    _observationsController.dispose();
    _dailySalaryController.dispose();
    _monthlyAmountController.dispose();
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
        message: 'Vuelve a iniciar sesión para continuar.',
      ),
      data: (session) {
        if (session == null) {
          return const AppStatePanel(
            icon: Icons.lock_outline,
            title: 'Inicia sesión para continuar',
            message: 'El formulario requiere una sesión activa.',
          );
        }
        if (!AppEnv.demoMode && widget.contratoId == null) {
          final options = ref.watch(contratoOptionsProvider(session.role));
          final data = options.valueOrNull;
          if (data != null) {
            _clients = data.clients;
            _advisors = data.advisors;
            _services = data.services;
            _states = data.states;
            if (!_clients.any((e) => e.id == _selectedClientId)) {
              _selectedClientId = null;
            }
            if (!_advisors.any((e) => e.id == _selectedAdvisorId)) {
              _selectedAdvisorId = null;
            }
            if (!_services.any((e) => e.id == _selectedServiceId)) {
              _selectedServiceId = null;
            }
            if (!_states.any((e) => e.id == _selectedStateId)) {
              _selectedStateId = null;
            }
          }
          _optionsMessage = options.isLoading
              ? 'Cargando catálogos…'
              : options.hasError
                  ? ApiErrorModel.fromObject(options.error!).message
                  : data?.advisorMessage;
        }
        final AsyncValue<List<ContratoModel>?> state =
            widget.contratoId != null && !AppEnv.demoMode
                ? ref
                    .watch(contratoDetailProvider(widget.contratoId!))
                    .whenData((value) => [value])
                : ref.watch(contratosControllerProvider(session.role));
        return state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => AppStatePanel(
            icon: Icons.cloud_off_outlined,
            title: 'No se pudo cargar el formulario',
            message: 'Inténtalo de nuevo.',
            action: TextButton.icon(
              onPressed: () {
                if (!AppEnv.demoMode && widget.contratoId != null) {
                  ref.invalidate(contratoDetailProvider(widget.contratoId!));
                } else {
                  ref
                      .read(contratosControllerProvider(session.role).notifier)
                      .load();
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ),
          data: (contracts) {
            if (contracts == null) {
              return const AppStatePanel(
                icon: Icons.edit_note_outlined,
                title: 'Formulario no disponible',
                message: 'No fue posible cargar la información del contrato.',
              );
            }
            final existing = widget.contratoId == null
                ? null
                : contracts
                    .where((item) => item.id == widget.contratoId)
                    .firstOrNull;
            if (widget.contratoId != null && existing == null) {
              return const AppStatePanel(
                icon: Icons.lock_outline,
                title: 'Contrato no disponible',
                message: '',
              );
            }
            if (existing != null) _initializeEdit(existing);
            return _form(context, session, existing);
          },
        );
      },
    );
  }

  void _initializeEdit(ContratoModel contract) {
    if (_initializedContractId == contract.id) return;
    _initializedContractId = contract.id;
    _folioController.text = contract.folio;
    _observationsController.text = contract.observaciones ?? '';
    _selectedClientId = contract.clienteId;
    _selectedServiceId = contract.servicioId;
    _selectedAdvisorId = contract.asesorId;
    _selectedDate = contract.fechaContrato;
  }

  Widget _form(
    BuildContext context,
    AuthSessionModel session,
    ContratoModel? existing,
  ) {
    final editing = existing != null;
    final canEdit = !editing ||
        session.role != UserRole.asesor ||
        (AppEnv.demoMode
            ? existing.assignedToCurrentAdvisor
            : existing.asesorId == session.id);
    if (!canEdit) {
      return const AppStatePanel(
        icon: Icons.lock_outline,
        title: 'No tienes permiso para editar este contrato',
        message:
            'El asesor solo puede actualizar contratos que tiene asignados.',
      );
    }

    final selectedDate = _selectedDate ?? DateTime.now();
    final isAdvisor = session.role == UserRole.asesor;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space6),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppBackButton(
              label: 'Contratos',
              onPressed: () => context.go(
                editing ? '/contratos/${existing.id}' : '/contratos',
              ),
            ),
            AppPageHeader(
              eyebrow: editing ? 'Edición' : null,
              title: editing ? 'Editar contrato' : 'Crear contrato',
              description: editing
                  ? 'Actualiza las observaciones del contrato.'
                  : 'Captura las condiciones generales y específicas del servicio.',
            ),
            const SizedBox(height: AppTheme.space5),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 980;
                final main = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: editing
                      ? [
                          _sectionCard(
                            number: '1',
                            title: 'Observaciones',
                            description: 'Actualiza las notas del contrato.',
                            child: TextFormField(
                              controller: _observationsController,
                              minLines: 5,
                              maxLines: 8,
                              decoration: const InputDecoration(
                                labelText: 'Observaciones',
                                hintText:
                                    'Agrega condiciones o acuerdos relevantes...',
                              ),
                            ),
                          ),
                        ]
                      : [
                          _clientServiceSection(session, isAdvisor: isAdvisor),
                          const SizedBox(height: AppTheme.space4),
                          _generalDataSection(selectedDate),
                          const SizedBox(height: AppTheme.space4),
                          AbsorbPointer(
                              absorbing: !AppEnv.demoMode,
                              child: _serviceConditionsSection()),
                          const SizedBox(height: AppTheme.space4),
                          AbsorbPointer(
                              absorbing: !AppEnv.demoMode,
                              child: _documentationSection()),
                        ],
                );
                final summary = _summaryCard(
                  context,
                  session,
                  existing,
                  selectedDate,
                );
                if (!wide) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      main,
                      const SizedBox(height: AppTheme.space4),
                      summary,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: main),
                    const SizedBox(width: AppTheme.space4),
                    SizedBox(width: 300, child: summary),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _clientServiceSection(
    AuthSessionModel session, {
    required bool isAdvisor,
  }) =>
      _sectionCard(
        number: '1',
        title: 'Cliente y servicio',
        description:
            'Selecciona el cliente, responsable y tipo de contratación.',
        child: _fieldGrid(
          columns: 3,
          fields: [
            _ContractGridItem(
              _dropdown<String>(
                label: 'Cliente',
                value: _selectedClientId,
                values: _clients.map((item) => (item.id, item.name)).toList(),
                onChanged: (value) => setState(() => _selectedClientId = value),
              ),
            ),
            _ContractGridItem(
              isAdvisor
                  ? TextFormField(
                      key: ValueKey(session.name),
                      initialValue: session.name,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Asesor'),
                    )
                  : _dropdown<String>(
                      label: 'Asesor',
                      value: _selectedAdvisorId,
                      values: _advisors
                          .map((item) => (item.id, item.name))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedAdvisorId = value),
                    ),
            ),
            _ContractGridItem(
              _dropdown<int>(
                label: 'Tipo de servicio',
                value: _selectedServiceId,
                values:
                    _services.map((item) => (item.id, item.nombre)).toList(),
                onChanged: (value) =>
                    setState(() => _selectedServiceId = value),
              ),
            ),
            if (!AppEnv.demoMode)
              _ContractGridItem(_dropdown<int>(
                label: 'Estado contractual',
                value: _selectedStateId,
                values: _states.map((e) => (e.id, e.name)).toList(),
                onChanged: (value) => setState(() => _selectedStateId = value),
              )),
            _ContractGridItem(
              _dropdown<String>(
                label: 'Tipo de venta',
                value: _saleType,
                values: const [
                  ('Cambaceo', 'Cambaceo'),
                  ('Referido', 'Referido'),
                  ('Renovación', 'Renovación'),
                  ('Digital', 'Digital'),
                ],
                onChanged: (value) =>
                    setState(() => _saleType = value ?? _saleType),
              ),
              span: 2,
            ),
          ],
        ),
      );

  Widget _generalDataSection(DateTime selectedDate) => _sectionCard(
        number: '2',
        title: 'Datos generales',
        description: 'Define plazo y condiciones de pago del acuerdo.',
        child: _fieldGrid(
          columns: 2,
          fields: [
            _ContractGridItem(_dateField(
              label: 'Fecha de inicio',
              value: selectedDate,
              onChanged: (value) => setState(() => _selectedDate = value),
            )),
            _ContractGridItem(
              _dropdown<String>(
                label: 'Esquema de pago',
                value: _paymentScheme,
                values: const [
                  ('Mensual', 'Mensual'),
                  ('Trimestral', 'Trimestral'),
                  ('Anual', 'Anual'),
                  ('Único', 'Único'),
                ],
                onChanged: (value) =>
                    setState(() => _paymentScheme = value ?? _paymentScheme),
              ),
            ),
            _ContractGridItem(
              TextFormField(
                controller: _folioController,
                readOnly: !AppEnv.demoMode,
                maxLength: 50,
                decoration: const InputDecoration(
                  labelText: 'Folio preliminar',
                  hintText: 'Se asignará al crear',
                  counterText: '',
                ),
              ),
            ),
            _ContractGridItem(
              TextFormField(
                controller: _observationsController,
                decoration: const InputDecoration(
                  labelText: 'Observaciones',
                  hintText: 'Agrega condiciones o acuerdos relevantes...',
                ),
              ),
            ),
          ],
        ),
      );

  Widget _serviceConditionsSection() {
    final service = _selectedService?.nombre ?? 'del servicio';
    return _sectionCard(
      number: '3',
      title: 'Condiciones de $service',
      description: AppEnv.demoMode
          ? 'Información específica para este tipo de servicio.'
          : 'Pendiente de integración financiera. Estos campos no se guardan.',
      trailing: _serviceBadge(service),
      child: _fieldGrid(
        columns: 2,
        fields: [
          _ContractGridItem(
            TextFormField(
              controller: _dailySalaryController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Salario diario de cotización',
                prefixText: '\$',
              ),
            ),
          ),
          _ContractGridItem(
            _dropdown<String>(
              label: 'Periodo contratado',
              value: _contractPeriod,
              values: const [
                ('6 meses', '6 meses'),
                ('12 meses', '12 meses'),
                ('24 meses', '24 meses'),
                ('Indefinido', 'Indefinido'),
              ],
              onChanged: (value) =>
                  setState(() => _contractPeriod = value ?? _contractPeriod),
            ),
          ),
          _ContractGridItem(
            _dateField(
              label: 'Fecha de término estimada',
              value:
                  AppEnv.demoMode ? _estimatedEndDate ?? _defaultEndDate : null,
              onChanged: (value) => setState(() => _estimatedEndDate = value),
            ),
          ),
          _ContractGridItem(
            TextFormField(
              controller: _monthlyAmountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monto mensual',
                prefixText: '\$',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentationSection() => _sectionCard(
        number: '4',
        title: 'Documentación',
        description: AppEnv.demoMode
            ? 'Adjunta el contrato firmado y sus anexos.'
            : 'Pendiente de integración de documentos contractuales.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: _pickDocument,
              borderRadius: BorderRadius.circular(AppTheme.radiusField),
              child: Container(
                constraints: const BoxConstraints(minHeight: 145),
                padding: const EdgeInsets.all(AppTheme.space5),
                decoration: BoxDecoration(
                  color: AppTheme.canvas,
                  border: Border.all(color: AppTheme.lineStrong),
                  borderRadius: BorderRadius.circular(AppTheme.radiusField),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppTheme.secondaryTint,
                      foregroundColor: AppTheme.secondaryDark,
                      child: Icon(Icons.arrow_upward_rounded),
                    ),
                    const SizedBox(height: AppTheme.space2),
                    const Text(
                      'Arrastra los documentos aquí o selecciónalos',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppTheme.space1),
                    const Text(
                      'PDF, JPG o PNG · Máximo 10 MB por archivo',
                      style: TextStyle(color: AppTheme.muted, fontSize: 11),
                    ),
                    const SizedBox(height: AppTheme.space3),
                    OutlinedButton(
                      onPressed: _pickDocument,
                      child: const Text('Seleccionar archivos'),
                    ),
                  ],
                ),
              ),
            ),
            if (_fileError != null)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.space2),
                child: Text(
                  _fileError!,
                  style: const TextStyle(color: AppTheme.danger),
                ),
              ),
            for (final file in _documents)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined),
                title: Text(file.name,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle:
                    Text('${(file.bytes.lengthInBytes / 1024).ceil()} KB'),
                trailing: IconButton(
                  tooltip: 'Quitar archivo',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _documents.remove(file)),
                ),
              ),
          ],
        ),
      );

  Widget _summaryCard(
    BuildContext context,
    AuthSessionModel session,
    ContratoModel? existing,
    DateTime selectedDate,
  ) {
    final editing = existing != null;
    final clientName = _selectedClient?.name ?? existing?.clienteNombre ?? '—';
    final serviceName =
        _selectedService?.nombre ?? existing?.servicioNombre ?? '—';
    final advisorName = session.role == UserRole.asesor
        ? session.name
        : _selectedAdvisor?.name ?? existing?.asesorNombre ?? '—';
    return Container(
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
          Text('Resumen del contrato',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppTheme.space4),
          _summaryLine('Cliente', clientName),
          _summaryLine('Servicio', serviceName),
          _summaryLine('Asesor', advisorName),
          if (!editing) ...[
            _summaryLine('Esquema', _paymentScheme),
            _summaryLine('Tipo de venta', _saleType),
            _summaryLine(
              'Fecha de inicio',
              DateFormat('dd/MM/yyyy', 'es_MX').format(selectedDate),
            ),
          ],
          const SizedBox(height: AppTheme.space3),
          Container(
            padding: const EdgeInsets.all(AppTheme.space3),
            decoration: BoxDecoration(
              color: AppTheme.warningBackground,
              borderRadius: BorderRadius.circular(AppTheme.radiusField),
              border: Border.all(
                  color: AppTheme.warningBase.withValues(alpha: .35)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 18, color: AppTheme.warning),
                SizedBox(width: AppTheme.space2),
                Expanded(
                  child: Text(
                    'El folio definitivo se asignará al crear el contrato. El tipo de venta es informativo y no determina la comisión.',
                    style: TextStyle(color: AppTheme.warning, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          if (!AppEnv.demoMode && !editing) ...[
            Text(_optionsMessage ??
                (_services.isEmpty
                    ? 'Sin servicios disponibles.'
                    : _states.isEmpty
                        ? 'Sin estados contractuales disponibles.'
                        : _clients.isEmpty
                            ? 'Sin clientes disponibles.'
                            : '')),
            const Text(
                'Condiciones financieras y documentos: pendientes de integración; no se guardan en esta etapa.'),
            TextButton(
                onPressed: () =>
                    ref.invalidate(contratoOptionsProvider(session.role)),
                child: const Text('Actualizar catálogos')),
          ],
          FilledButton(
            onPressed: _saving ||
                    (!AppEnv.demoMode &&
                        !editing &&
                        (_optionsMessage != null ||
                            _services.isEmpty ||
                            _states.isEmpty ||
                            _clients.isEmpty))
                ? null
                : () => _save(context, session, existing),
            child: Text(editing ? 'Guardar cambios' : 'Crear contrato'),
          ),
          TextButton(
            onPressed: () => context.go(
              editing ? '/contratos/${existing.id}' : '/contratos',
            ),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Widget _summaryLine(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.space3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
            ),
            const SizedBox(width: AppTheme.space2),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ],
        ),
      );

  Widget _sectionCard({
    required String number,
    required String title,
    required String description,
    required Widget child,
    Widget? trailing,
  }) =>
      Container(
        padding: const EdgeInsets.all(AppTheme.space5),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.line),
          borderRadius: BorderRadius.circular(AppTheme.radius),
          boxShadow: AppTheme.elevation,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.accentSoft,
                  foregroundColor: AppTheme.primary,
                  child: Text(number,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: AppTheme.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: AppTheme.space1),
                      Text(description,
                          style: const TextStyle(
                              color: AppTheme.muted, fontSize: 11)),
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: AppTheme.space4),
            child,
          ],
        ),
      );

  Widget _serviceBadge(String label) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space3,
          vertical: AppTheme.space2,
        ),
        decoration: BoxDecoration(
          color: AppTheme.infoBackground,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        ),
        child: Text(
          '• $label',
          style: const TextStyle(
            color: AppTheme.info,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _fieldGrid({
    required int columns,
    required List<_ContractGridItem> fields,
  }) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final actualColumns = constraints.maxWidth < 680 ? 1 : columns;
          final gap = AppTheme.space4;
          final cellWidth = (constraints.maxWidth - gap * (actualColumns - 1)) /
              actualColumns;
          return Wrap(
            spacing: gap,
            runSpacing: AppTheme.space3,
            children: [
              for (final field in fields)
                SizedBox(
                  width: actualColumns == 1
                      ? constraints.maxWidth
                      : cellWidth *
                              (field.span > actualColumns
                                  ? actualColumns
                                  : field.span) +
                          gap *
                              ((field.span > actualColumns
                                      ? actualColumns
                                      : field.span) -
                                  1),
                  child: field.child,
                ),
            ],
          );
        },
      );

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<(T, String)> values,
    required ValueChanged<T?> onChanged,
  }) =>
      DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          for (final item in values)
            DropdownMenuItem<T>(value: item.$1, child: Text(item.$2)),
        ],
        validator: (selected) => selected == null ? 'Selecciona $label.' : null,
        onChanged: !AppEnv.demoMode &&
                ['Tipo de venta', 'Esquema de pago', 'Periodo contratado']
                    .contains(label)
            ? null
            : onChanged,
      );

  Widget _dateField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
  }) =>
      InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null && mounted) onChanged(picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(labelText: label),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value == null
                      ? 'Selecciona una fecha'
                      : DateFormat('dd/MM/yyyy', 'es_MX').format(value),
                  style: TextStyle(
                    color: value == null ? AppTheme.faint : AppTheme.ink,
                  ),
                ),
              ),
              const Icon(Icons.calendar_month_outlined),
            ],
          ),
        ),
      );

  Future<void> _pickDocument() async {
    final file = await createFilePlatform().chooseFile();
    if (!mounted || file == null) return;
    final extension = file.name.split('.').last.toLowerCase();
    final validExtension = {'pdf', 'jpg', 'jpeg', 'png'}.contains(extension);
    final validSize = file.bytes.lengthInBytes <= 10 * 1024 * 1024;
    setState(() {
      if (!validExtension) {
        _fileError = 'Solo se permiten archivos PDF, JPG o PNG.';
      } else if (!validSize) {
        _fileError = 'El archivo no puede superar 10 MB.';
      } else {
        _fileError = null;
        _documents.add(file);
      }
    });
  }

  Future<void> _save(
    BuildContext context,
    AuthSessionModel session,
    ContratoModel? existing,
  ) async {
    if (!_formKey.currentState!.validate() || _saving) return;
    if (!AppEnv.demoMode) {
      setState(() => _saving = true);
      try {
        final controller =
            ref.read(contratosControllerProvider(session.role).notifier);
        final contract = existing != null
            ? await controller.updateObservations(
                existing.id, _nullable(_observationsController.text))
            : await controller.create({
                'cliente_id': _selectedClientId,
                'servicio_id': _selectedServiceId,
                if (session.role != UserRole.asesor)
                  'asesor_id': _selectedAdvisorId,
                'fecha_contrato': DateFormat('yyyy-MM-dd')
                    .format(_selectedDate ?? DateTime.now()),
                'estado_contrato_id': _selectedStateId,
                'observaciones': _nullable(_observationsController.text),
              });
        ref.invalidate(contratoDetailProvider(contract.id));
        if (context.mounted) context.go('/contratos/${contract.id}');
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(ApiErrorModel.fromObject(error).message)));
        }
      } finally {
        if (mounted) setState(() => _saving = false);
      }
      return;
    }
    final controller =
        ref.read(contratosControllerProvider(session.role).notifier);
    if (existing != null) {
      controller.updateObservationsDemo(
        existing.id,
        _nullable(_observationsController.text),
      );
      context.go('/contratos/${existing.id}');
      return;
    }

    final client = _selectedClient;
    final service = _selectedService;
    if (client == null || service == null) return;
    final advisor = session.role == UserRole.asesor ? null : _selectedAdvisor;
    final contract = controller.createDemo(
      clienteId: client.id,
      clienteNombre: client.name,
      servicioId: service.id,
      folio: _folioController.text.trim().isEmpty
          ? 'Sin folio (demo)'
          : _folioController.text.trim(),
      fechaContrato: _selectedDate ?? DateTime.now(),
      estadoContratoId: 1,
      estadoNombre: 'Activo',
      cantidadPagos: _paymentCount,
      observaciones: _nullable(_observationsController.text),
      currentUserId: session.id,
      currentUserName: session.name,
      advisorId: advisor?.id,
      advisorName: advisor?.name,
      documentos: List.unmodifiable(_documents),
    );
    context.go('/contratos/${contract.id}');
  }

  int get _paymentCount => switch (_paymentScheme) {
        'Trimestral' => 4,
        'Anual' || 'Único' => 1,
        _ => 12,
      };

  DateTime get _defaultEndDate {
    final date = _selectedDate ?? DateTime.now();
    return DateTime(date.year + 1, date.month, date.day);
  }

  ({String id, String name})? get _selectedClient {
    for (final client in _clients) {
      if (client.id == _selectedClientId) return client;
    }
    return null;
  }

  ({String id, String name})? get _selectedAdvisor {
    for (final advisor in _advisors) {
      if (advisor.id == _selectedAdvisorId) return advisor;
    }
    return null;
  }

  ServicioModel? get _selectedService {
    for (final service in _services) {
      if (service.id == _selectedServiceId) return service;
    }
    return null;
  }

  String? _nullable(String value) => value.trim().isEmpty ? null : value.trim();
}

class _ContractGridItem {
  const _ContractGridItem(this.child, {this.span = 1});

  final Widget child;
  final int span;
}
