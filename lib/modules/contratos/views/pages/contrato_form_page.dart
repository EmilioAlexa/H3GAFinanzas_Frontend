import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/responsive/window_size_class.dart';
import '../../../../core/widgets/app_notice.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../../auth/auth.dart';
import '../../controllers/contratos_controller.dart';
import '../../fixtures/contratos_demo_fixtures.dart';
import '../../models/contrato_model.dart';

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

const _demoContractStates = <({int id, String name})>[
  (id: 1, name: 'Activo'),
  (id: 2, name: 'En proceso'),
  (id: 3, name: 'Pago pendiente'),
  (id: 4, name: 'Pausado'),
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
  final _paymentsController = TextEditingController();
  final _observationsController = TextEditingController();
  String? _selectedClientId = _demoClients.first.id;
  int? _selectedServiceId = 40;
  String? _selectedAdvisorId = _demoAdvisors.first.id;
  int? _selectedStateId = 1;
  DateTime? _selectedDate;
  String? _initializedContractId;

  @override
  void dispose() {
    _folioController.dispose();
    _paymentsController.dispose();
    _observationsController.dispose();
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
        final state = ref.watch(contratosControllerProvider(session.role));
        return state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => AppStatePanel(
            icon: Icons.cloud_off_outlined,
            title: 'No se pudo cargar el formulario',
            message: 'Inténtalo de nuevo.',
            action: TextButton.icon(
              onPressed: () => ref
                  .read(contratosControllerProvider(session.role).notifier)
                  .load(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ),
          data: (contracts) {
            if (contracts == null) {
              return const AppStatePanel(
                icon: Icons.edit_note_outlined,
                title: 'Formulario sin conectar',
                message:
                    'El alta y la edición se conectarán a los catálogos del backend en B4.',
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
                message:
                    'No existe en la muestra o no está asignado a esta sesión.',
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
    _paymentsController.text = contract.cantidadPagos?.toString() ?? '';
    _observationsController.text = contract.observaciones ?? '';
    _selectedClientId = contract.clienteId;
    _selectedServiceId = contract.servicioId;
    _selectedAdvisorId = contract.asesorId;
    _selectedStateId = contract.estadoContratoId;
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
        existing.assignedToCurrentAdvisor;
    if (!canEdit) {
      return const AppStatePanel(
        icon: Icons.lock_outline,
        title: 'No tienes permiso para editar este contrato',
        message:
            'El asesor solo puede actualizar contratos que tiene asignados.',
      );
    }
    final isAdvisor = session.role == UserRole.asesor;
    final selectedDate = _selectedDate ?? DateTime.now();
    final compact = Responsive.of(context) == WindowSizeClass.compacto;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space6),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextButton.icon(
                  onPressed: () => context.go(
                    editing ? '/contratos/${existing.id}' : '/contratos',
                  ),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Contratos'),
                  style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                ),
                AppPageHeader(
                  eyebrow: editing ? 'Edición demo' : 'Nuevo registro · demo',
                  title: editing ? 'Editar observaciones' : 'Crear contrato',
                  description: editing
                      ? 'Observaciones es el único campo actualizable por PATCH.'
                      : 'Captura las condiciones generales del contrato.',
                ),
                const AppNotice(
                  text:
                      'Esta operación modifica solo la muestra local. Los IDs y las opciones de catálogos son ficticios; el backend debe proporcionar las opciones vigentes.',
                ),
                const SizedBox(height: AppTheme.space4),
                if (editing)
                  _formCard(
                    context,
                    title: 'Observaciones',
                    children: [
                      TextFormField(
                        controller: _observationsController,
                        minLines: 4,
                        maxLines: 7,
                        decoration: const InputDecoration(
                          labelText: 'Observaciones',
                          hintText: 'Agrega condiciones o acuerdos relevantes',
                        ),
                      ),
                    ],
                  )
                else ...[
                  _formCard(
                    context,
                    title: 'Cliente y servicio',
                    children: [
                      _fieldWidth(
                        compact,
                        _dropdown<String>(
                          label: 'Cliente',
                          value: _selectedClientId,
                          values: _demoClients
                              .map((item) => (item.id, item.name))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedClientId = value),
                        ),
                      ),
                      _fieldWidth(
                        compact,
                        _dropdown<int>(
                          label: 'Servicio',
                          value: _selectedServiceId,
                          values: ContratosDemoFixtures.services
                              .map((item) => (item.id, item.nombre))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedServiceId = value),
                        ),
                      ),
                      if (!isAdvisor)
                        _fieldWidth(
                          compact,
                          _dropdown<String>(
                            label: 'Asesor asignado',
                            value: _selectedAdvisorId,
                            values: _demoAdvisors
                                .map((item) => (item.id, item.name))
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _selectedAdvisorId = value),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space4),
                  _formCard(
                    context,
                    title: 'Datos del contrato',
                    children: [
                      _fieldWidth(
                        compact,
                        TextFormField(
                          controller: _folioController,
                          maxLength: 50,
                          decoration: const InputDecoration(
                            labelText: 'Folio',
                            helperText: 'Máximo 50 caracteres',
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'El folio es obligatorio.'
                                  : null,
                        ),
                      ),
                      _fieldWidth(
                        compact,
                        _dateField(context, selectedDate),
                      ),
                      _fieldWidth(
                        compact,
                        _dropdown<int>(
                          label: 'Estado contractual',
                          value: _selectedStateId,
                          values: _demoContractStates
                              .map((item) => (item.id, item.name))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedStateId = value),
                        ),
                      ),
                      _fieldWidth(
                        compact,
                        TextFormField(
                          controller: _paymentsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Cantidad de pagos (opcional)',
                          ),
                          validator: (value) {
                            final input = value?.trim() ?? '';
                            if (input.isEmpty) return null;
                            final count = int.tryParse(input);
                            if (count == null || count < 1 || count > 32767) {
                              return 'Usa un número entero entre 1 y 32767.';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: TextFormField(
                          controller: _observationsController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Observaciones (opcional)',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppTheme.space4),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: AppTheme.space2,
                  runSpacing: AppTheme.space2,
                  children: [
                    OutlinedButton(
                      onPressed: () => context.go(
                        editing ? '/contratos/${existing.id}' : '/contratos',
                      ),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton.icon(
                      onPressed: () => _save(context, session, existing),
                      icon: const Icon(Icons.save_outlined),
                      label: Text(editing
                          ? 'Guardar observaciones demo'
                          : 'Crear contrato demo'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _formCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
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
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.space4),
            Wrap(
              spacing: AppTheme.space4,
              runSpacing: AppTheme.space3,
              children: children,
            ),
          ],
        ),
      );

  Widget _fieldWidth(bool compact, Widget child) => SizedBox(
        width: compact ? double.infinity : 390,
        child: child,
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
        onChanged: onChanged,
      );

  Widget _dateField(BuildContext context, DateTime value) => InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null) setState(() => _selectedDate = picked);
        },
        child: InputDecorator(
          decoration: const InputDecoration(labelText: 'Fecha de contrato'),
          child: Row(
            children: [
              Expanded(
                  child: Text(DateFormat('dd/MM/yyyy', 'es_MX').format(value))),
              const Icon(Icons.calendar_month_outlined),
            ],
          ),
        ),
      );

  void _save(
    BuildContext context,
    AuthSessionModel session,
    ContratoModel? existing,
  ) {
    if (!_formKey.currentState!.validate()) return;
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
    final client =
        _demoClients.firstWhere((item) => item.id == _selectedClientId);
    final service = ContratosDemoFixtures.services
        .firstWhere((item) => item.id == _selectedServiceId);
    final state =
        _demoContractStates.firstWhere((item) => item.id == _selectedStateId);
    final advisor = session.role == UserRole.asesor
        ? null
        : _demoAdvisors.firstWhere((item) => item.id == _selectedAdvisorId);
    final contract = controller.createDemo(
      clienteId: client.id,
      clienteNombre: client.name,
      servicioId: service.id,
      folio: _folioController.text.trim(),
      fechaContrato: _selectedDate ?? DateTime.now(),
      estadoContratoId: state.id,
      estadoNombre: state.name,
      cantidadPagos: int.tryParse(_paymentsController.text.trim()),
      observaciones: _nullable(_observationsController.text),
      currentUserId: session.id,
      currentUserName: session.name,
      advisorId: advisor?.id,
      advisorName: advisor?.name,
    );
    context.go('/contratos/${contract.id}');
  }

  String? _nullable(String value) => value.trim().isEmpty ? null : value.trim();
}
