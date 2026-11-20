import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/env.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/network/api_error_model.dart';
import '../../../../core/platform/file_platform_factory.dart';
import '../../../../core/platform/selected_file.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../../auth/auth.dart';
import '../../../contratos/fixtures/contratos_demo_fixtures.dart';
import '../../../contratos/models/contrato_model.dart';
import '../../../usuarios/usuarios.dart';
import '../../controllers/pago_options_controller.dart';
import '../../controllers/pagos_controller.dart';
import '../../models/evidencia_pago_model.dart';
import '../../models/pago_model.dart';
import '../../models/pago_programado_model.dart';
import '../../models/payment_evidence_validation.dart';

const maxEvidenceBytes = 10 * 1024 * 1024;

String? validateEvidence(SelectedFile file) => validatePaymentEvidence(file);

class PagoFormPage extends ConsumerStatefulWidget {
  const PagoFormPage({this.paymentId, super.key});

  final String? paymentId;

  @override
  ConsumerState<PagoFormPage> createState() => _PagoFormPageState();
}

class _PagoFormPageState extends ConsumerState<PagoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  final _observations = TextEditingController();
  final _receipt = TextEditingController();
  final _reason = TextEditingController();
  List<PagoOption> _methods = [];
  List<PaymentReceiver> _receivers = [];
  String? _optionsMessage;
  String? _receiverMessage;
  String? _savedId;
  final List<SelectedFile> _files = [];
  final List<EvidenciaPagoModel> _existingEvidence = [];

  String? _clientId;
  String? _contractId;
  String? _scheduleId;
  String? _receivedById;
  String? _fileError;
  int? _methodId = AppEnv.demoMode ? 1 : null;
  DateTime? _date = DateTime.now();
  bool _saving = false;
  bool _editInitialized = false;

  @override
  void initState() {
    super.initState();
    _amount.addListener(_refreshSummary);
  }

  @override
  void dispose() {
    _amount.removeListener(_refreshSummary);
    _amount.dispose();
    _reference.dispose();
    _observations.dispose();
    _receipt.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _refreshSummary() {
    if (mounted) setState(() {});
  }

  void _initializeRejectedPayment(PagoModel payment) {
    _editInitialized = true;
    _clientId = payment.clienteId ??
        ContratosDemoFixtures.contracts
            .where((contract) =>
                AppEnv.demoMode && contract.id == payment.contratoId)
            .map((contract) => contract.clienteId)
            .firstOrNull;
    _contractId = payment.contratoId;
    _scheduleId = payment.pagoProgramadoId;
    _methodId = payment.formaPagoId;
    _date = payment.fechaPago;
    _receivedById = payment.recibidoPor;
    _amount.removeListener(_refreshSummary);
    _amount.text = payment.monto.toString();
    _amount.addListener(_refreshSummary);
    _reference.text = payment.referencia;
    _observations.text = payment.observaciones;
    _receipt.text = payment.folioRecibo ?? '';
    _existingEvidence
      ..clear()
      ..addAll(payment.evidencias);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    if (session == null) {
      return const AppStatePanel(
        icon: Icons.lock_outline,
        title: 'Inicia sesión para continuar',
        message: 'El registro requiere una sesión activa.',
      );
    }
    final paymentState = ref.watch(pagosControllerProvider(session.role));
    final optionsState =
        AppEnv.demoMode ? null : ref.watch(pagoOptionsProvider(session.role));
    final options = optionsState?.valueOrNull;
    if (options != null) {
      _methods = options.methods;
      _receivers = options.receivers;
      _receiverMessage = options.receiverMessage;
    }
    _optionsMessage = optionsState?.isLoading == true
        ? 'Cargando contratos y métodos…'
        : optionsState?.hasError == true
            ? ApiErrorModel.fromObject(optionsState!.error!).message
            : !AppEnv.demoMode && _methods.isEmpty
                ? (options?.methodError != null
                    ? ApiErrorModel.fromObject(options!.methodError!).message
                    : 'No hay métodos de pago activos.')
                : null;
    final contracts = AppEnv.demoMode
        ? ContratosDemoFixtures.contracts
            .where((item) =>
                session.role != UserRole.asesor ||
                item.assignedToCurrentAdvisor)
            .toList()
        : options?.contracts ?? <ContratoModel>[];
    final detailState = widget.paymentId == null || AppEnv.demoMode
        ? null
        : ref.watch(pagoDetailProvider(widget.paymentId!));
    final editingPayment = detailState?.valueOrNull ??
        paymentState.valueOrNull?.payments
            .where((payment) => payment.id == widget.paymentId)
            .firstOrNull;
    if (detailState?.hasError == true) {
      return AppStatePanel(
          icon: Icons.cloud_off_outlined,
          title: 'No se pudo cargar el pago',
          message: ApiErrorModel.fromObject(detailState!.error!).message,
          action: TextButton(
              onPressed: () =>
                  ref.invalidate(pagoDetailProvider(widget.paymentId!)),
              child: const Text('Reintentar')));
    }
    if (widget.paymentId != null) {
      if (paymentState.isLoading || detailState?.isLoading == true) {
        return const Center(child: CircularProgressIndicator());
      }
      if (session.role != UserRole.asesor ||
          editingPayment == null ||
          editingPayment.estado != 'Rechazado' ||
          (!AppEnv.demoMode && editingPayment.registradoPor != session.id)) {
        return const AppStatePanel(
          icon: Icons.lock_outline,
          title: 'Pago no editable',
          message: 'Solo puedes editar pagos rechazados que te pertenecen.',
        );
      }
      if (!_editInitialized) {
        _initializeRejectedPayment(editingPayment);
      }
    }
    final clients = <String, String>{
      for (final contract in contracts)
        contract.clienteId: contract.clienteNombre,
    };
    final schedules =
        paymentState.valueOrNull?.scheduled ?? const <PagoProgramadoModel>[];
    final matchingContracts =
        contracts.where((contract) => contract.clienteId == _clientId).toList();
    final selectedContract = _findContract(contracts);
    final matchingSchedules = _matchingSchedules(schedules);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space6),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppBackButton(
              label: 'Pagos',
              onPressed: () => context.go('/pagos'),
            ),
            AppPageHeader(
              eyebrow: widget.paymentId == null
                  ? 'Nuevo registro'
                  : 'Reenvío de pago',
              title: widget.paymentId == null
                  ? 'Registrar pago'
                  : 'Editar y reenviar pago',
              description:
                  'Captura la información y adjunta las evidencias correspondientes.',
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 980;
                final sections = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AbsorbPointer(
                        absorbing: widget.paymentId != null && !AppEnv.demoMode,
                        child: _relationSection(
                            clients, matchingContracts, matchingSchedules)),
                    const SizedBox(height: AppTheme.space4),
                    _paymentSection(matchingSchedules),
                    const SizedBox(height: AppTheme.space4),
                    _evidenceSection(),
                  ],
                );
                final summary = _summaryCard(
                  context,
                  selectedContract,
                  matchingSchedules,
                  session.role,
                  contracts,
                );
                if (!wide) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      sections,
                      const SizedBox(height: AppTheme.space4),
                      summary,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: sections),
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

  Widget _relationSection(
    Map<String, String> clients,
    List<ContratoModel> matchingContracts,
    List<PagoProgramadoModel> matchingSchedules,
  ) =>
      _sectionCard(
        number: '1',
        title: 'Relación del pago',
        description: 'Selecciona a qué obligación corresponde.',
        child: Column(
          children: [
            _fieldGrid(
              columns: 2,
              children: [
                _dropdown<String>(
                  label: 'Cliente',
                  value: clients.containsKey(_clientId) ? _clientId : null,
                  items: clients.entries
                      .map((entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value,
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() {
                    _clientId = value;
                    _contractId = null;
                    _scheduleId = null;
                  }),
                  validator: (value) =>
                      value == null ? 'Selecciona un cliente.' : null,
                ),
                _dropdown<String>(
                  label: 'Contrato',
                  value: matchingContracts.any((item) => item.id == _contractId)
                      ? _contractId
                      : null,
                  items: matchingContracts
                      .map((contract) => DropdownMenuItem(
                            value: contract.id,
                            child: Text(
                              '${contract.folio} · ${contract.servicioNombre}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: _clientId == null
                      ? null
                      : (value) => setState(() {
                            _contractId = value;
                            _scheduleId = null;
                          }),
                  validator: (value) =>
                      value == null ? 'Selecciona un contrato.' : null,
                ),
                _readOnlyField(
                  'Servicio',
                  _findContract(matchingContracts)?.servicioNombre ??
                      'Se asigna con el contrato',
                ),
                _dropdown<String>(
                  label: 'Pago programado',
                  value: matchingSchedules.any((item) => item.id == _scheduleId)
                      ? _scheduleId
                      : null,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Sin pago programado'),
                    ),
                    ...matchingSchedules.map((schedule) => DropdownMenuItem(
                          value: schedule.id,
                          child: Text(
                            'Mensualidad ${schedule.numeroPago} · ${_scheduleDate(schedule)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                  ],
                  onChanged: (value) => setState(() => _scheduleId = value),
                ),
              ],
            ),
            if (_findSchedule(matchingSchedules) case final schedule?) ...[
              const SizedBox(height: AppTheme.space3),
              _selectedSchedule(schedule),
            ],
          ],
        ),
      );

  Widget _paymentSection(List<PagoProgramadoModel> schedules) {
    final isCash = _isCash;
    return _sectionCard(
      number: '2',
      title: 'Información del pago',
      description: 'Registra los datos como aparecen en el comprobante.',
      child: Column(
        children: [
          _fieldGrid(
            columns: 3,
            spans: const [1, 1, 1, 1, 2],
            children: [
              TextFormField(
                controller: _amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixText: '\$',
                ),
                validator: _validateAmount,
              ),
              _dateField(),
              _dropdown<int>(
                label: 'Método de pago',
                value: _methodId,
                validator: (value) =>
                    value == null ? 'Selecciona un método activo.' : null,
                items: !AppEnv.demoMode
                    ? [
                        for (final method in _methods)
                          DropdownMenuItem(
                              value: method.id, child: Text(method.name))
                      ]
                    : const [
                        DropdownMenuItem(
                            value: 1, child: Text('Transferencia electrónica')),
                        DropdownMenuItem(value: 2, child: Text('Depósito')),
                        DropdownMenuItem(value: 3, child: Text('Efectivo')),
                        DropdownMenuItem(value: 4, child: Text('Cheque')),
                      ],
                onChanged: (value) => setState(() => _methodId = value),
              ),
              TextFormField(
                controller: _reference,
                readOnly: widget.paymentId != null && !AppEnv.demoMode,
                maxLength: 100,
                decoration:
                    const InputDecoration(labelText: 'Referencia de pago'),
              ),
              TextFormField(
                controller: _observations,
                decoration: const InputDecoration(
                  labelText: 'Observaciones',
                  hintText: 'Agrega información relevante...',
                ),
              ),
            ],
          ),
          if (widget.paymentId != null && !AppEnv.demoMode)
            TextFormField(
                controller: _reason,
                maxLength: 1000,
                decoration:
                    const InputDecoration(labelText: 'Motivo de corrección *'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Indica el motivo de corrección.'
                    : null),
          if (isCash) ...[
            const SizedBox(height: AppTheme.space3),
            _cashFields(),
          ],
        ],
      ),
    );
  }

  Widget _cashFields() {
    final demoUsers = AppEnv.demoMode
        ? ref.watch(usuariosControllerProvider).valueOrNull
        : null;
    final receivers = AppEnv.demoMode
        ? (demoUsers ?? const <UsuarioModel>[])
            .where((e) => e.activo)
            .map((e) => (id: e.id, name: e.nombreCompleto))
            .toList()
        : _receivers;
    return Container(
      padding: const EdgeInsets.all(AppTheme.space3),
      decoration: BoxDecoration(
        color: AppTheme.warningBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusField),
        border: Border.all(color: AppTheme.warningBase.withValues(alpha: .35)),
      ),
      child: _fieldGrid(
        columns: 3,
        children: [
          TextFormField(
            controller: _receipt,
            maxLength: 100,
            decoration: const InputDecoration(labelText: 'Folio de recibo *'),
            validator: (value) => _isCash && (value?.trim().isEmpty ?? true)
                ? 'Ingresa el folio del recibo.'
                : null,
          ),
          _dropdown<String>(
            label: 'Recibido por *',
            value: receivers.any((e) => e.id == _receivedById)
                ? _receivedById
                : null,
            items: receivers
                .map((receiver) => DropdownMenuItem<String>(
                      value: receiver.id,
                      child: Text(receiver.name),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _receivedById = value),
            validator: (value) => _isCash && value == null
                ? 'Selecciona quién recibió el pago.'
                : null,
          ),
        ],
      ),
    );
  }

  Widget _evidenceSection() => _sectionCard(
        number: '3',
        title: 'Evidencia',
        description: 'Adjunta uno o varios documentos de respaldo.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: _pickFile,
              borderRadius: BorderRadius.circular(AppTheme.radiusField),
              child: Container(
                constraints: const BoxConstraints(minHeight: 165),
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
                    const Text('Arrastra los archivos aquí o selecciónalos',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: AppTheme.space1),
                    const Text('PDF o JPG/JPEG · Máximo 10 MB por archivo',
                        style: TextStyle(color: AppTheme.muted, fontSize: 11)),
                    const SizedBox(height: AppTheme.space3),
                    OutlinedButton(
                      onPressed: _pickFile,
                      child: const Text('Seleccionar archivos'),
                    ),
                  ],
                ),
              ),
            ),
            if (_fileError != null)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.space2),
                child: Text(_fileError!,
                    style: const TextStyle(color: AppTheme.danger)),
              ),
            for (final file in _files)
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
                  onPressed: () => setState(() => _files.remove(file)),
                ),
              ),
          ],
        ),
      );

  Widget _summaryCard(
    BuildContext context,
    ContratoModel? contract,
    List<PagoProgramadoModel> schedules,
    UserRole role,
    List<ContratoModel> contracts,
  ) {
    final amount = _parsedAmount();
    final schedule = _findSchedule(schedules);
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
          Text('Resumen del registro',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppTheme.space4),
          _summaryLine('Cliente', contract?.clienteNombre ?? '—'),
          _summaryLine('Servicio', contract?.servicioNombre ?? '—'),
          _summaryLine(
            'Pago',
            schedule == null
                ? 'Sin pago programado'
                : '${schedule.numeroPago} de ${contract?.cantidadPagos ?? schedule.numeroPago}',
          ),
          _summaryLine(
              'Monto', amount == null ? '—' : MoneyFormatter.format(amount)),
          _summaryLine('Método', _methodLabel),
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
                    'El pago pasará a revisión financiera. No quedará validado automáticamente.',
                    style: TextStyle(color: AppTheme.warning, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          if (!AppEnv.demoMode) ...[
            if (_optionsMessage != null) Text(_optionsMessage!),
            if (contracts.isEmpty)
              const Text('Sin contratos disponibles para registrar pagos.'),
            if (_receiverMessage != null && _isCash) Text(_receiverMessage!),
            if (ref
                    .watch(pagosControllerProvider(role))
                    .valueOrNull
                    ?.scheduledError !=
                null)
              const Text(
                  'No se pudieron consultar las obligaciones. Reintenta antes de asociar el pago a un cobro.'),
            TextButton(
                onPressed: () {
                  ref.invalidate(pagoOptionsProvider(role));
                  ref.read(pagosControllerProvider(role).notifier).load();
                },
                child: const Text('Actualizar opciones')),
          ],
          FilledButton(
            onPressed: _saving ||
                    (!AppEnv.demoMode &&
                        (_optionsMessage != null || contracts.isEmpty))
                ? null
                : () => _save(role, contracts),
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Registrar y enviar a revisión'),
          ),
          TextButton(
            onPressed: () => context.go('/pagos'),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String number,
    required String title,
    required String description,
    required Widget child,
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
              ],
            ),
            const SizedBox(height: AppTheme.space4),
            child,
          ],
        ),
      );

  Widget _fieldGrid({
    required int columns,
    required List<Widget> children,
    List<int>? spans,
  }) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final actualColumns = constraints.maxWidth < 680 ? 1 : columns;
          final gap = AppTheme.space4;
          final width = (constraints.maxWidth - gap * (actualColumns - 1)) /
              actualColumns;
          return Wrap(
            spacing: gap,
            runSpacing: AppTheme.space3,
            children: [
              for (var index = 0; index < children.length; index++)
                SizedBox(
                  width: actualColumns == 1
                      ? constraints.maxWidth
                      : width * _spanAt(spans, index, actualColumns) +
                          gap * (_spanAt(spans, index, actualColumns) - 1),
                  child: children[index],
                ),
            ],
          );
        },
      );

  int _spanAt(List<int>? spans, int index, int columns) {
    final span = spans != null && index < spans.length ? spans[index] : 1;
    return span.clamp(1, columns);
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    FormFieldValidator<T>? validator,
  }) =>
      DropdownButtonFormField<T>(
        initialValue: items.any((item) => item.value == value) ? value : null,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: items,
        onChanged: widget.paymentId != null &&
                !AppEnv.demoMode &&
                ['Cliente', 'Contrato', 'Pago programado'].contains(label)
            ? null
            : onChanged,
        validator: validator,
      );

  Widget _dateField() => InkWell(
        onTap: _chooseDate,
        child: InputDecorator(
          decoration: const InputDecoration(labelText: 'Fecha de pago'),
          child: Row(
            children: [
              Expanded(
                  child: Text(_date == null
                      ? 'Selecciona una fecha'
                      : MoneyFormatter.formatDate(_date!))),
              const Icon(Icons.calendar_month_outlined),
            ],
          ),
        ),
      );

  Widget _readOnlyField(String label, String value) => InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppTheme.surfaceSecondary,
        ),
        child: Text(value, overflow: TextOverflow.ellipsis),
      );

  Widget _selectedSchedule(PagoProgramadoModel schedule) => Container(
        padding: const EdgeInsets.all(AppTheme.space3),
        decoration: BoxDecoration(
          color: AppTheme.infoBackground,
          borderRadius: BorderRadius.circular(AppTheme.radiusField),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.calendar_month_outlined,
                color: AppTheme.secondaryDark),
            const SizedBox(width: AppTheme.space2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pago seleccionado',
                      style: TextStyle(color: AppTheme.muted, fontSize: 11)),
                  const SizedBox(height: AppTheme.space1),
                  Text('Mensualidad ${schedule.numeroPago} de pago',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('Vencimiento: ${_scheduleDate(schedule)}',
                      style:
                          const TextStyle(color: AppTheme.muted, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      );

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
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );

  ContratoModel? _findContract(List<ContratoModel> contracts) {
    for (final contract in contracts) {
      if (contract.id == _contractId) return contract;
    }
    return null;
  }

  PagoProgramadoModel? _findSchedule(List<PagoProgramadoModel> schedules) {
    for (final schedule in schedules) {
      if (schedule.id == _scheduleId) return schedule;
    }
    return null;
  }

  List<PagoProgramadoModel> _matchingSchedules(
          List<PagoProgramadoModel> schedules) =>
      schedules
          .where((schedule) => schedule.contratoId == _contractId)
          .toList();

  String _scheduleDate(PagoProgramadoModel schedule) =>
      schedule.fechaVencimiento == null
          ? 'Sin vencimiento'
          : MoneyFormatter.formatDate(schedule.fechaVencimiento!);

  Decimal? _parsedAmount() {
    final value = _amount.text.replaceAll(',', '').replaceAll('\$', '').trim();
    try {
      return value.isEmpty ? null : Decimal.parse(value);
    } on FormatException {
      return null;
    }
  }

  bool get _isCash => AppEnv.demoMode
      ? _methodId == 3
      : _methodLabel.toLowerCase().contains('efectivo');
  String get _methodLabel => !AppEnv.demoMode
      ? _methods
              .where((e) => e.id == _methodId)
              .map((e) => e.name)
              .firstOrNull ??
          'Selecciona un método'
      : switch (_methodId) {
          1 => 'Transferencia electrónica',
          2 => 'Depósito',
          3 => 'Efectivo',
          _ => 'Cheque',
        };

  String? _validateAmount(String? value) {
    final normalized =
        (value ?? '').replaceAll(',', '').replaceAll('\$', '').trim();
    if (normalized.isEmpty) return 'Ingresa un monto.';
    try {
      final amount = Decimal.parse(normalized);
      if (amount <= Decimal.zero) return 'El monto debe ser mayor que cero.';
      if (!RegExp(r'^\d{1,10}(\.\d{1,2})?$').hasMatch(normalized)) {
        return 'Usa hasta 10 dígitos enteros y máximo dos decimales.';
      }
    } on FormatException {
      return 'Ingresa un monto válido.';
    }
    return null;
  }

  Future<void> _chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) setState(() => _date = date);
  }

  Future<void> _pickFile() async {
    final file = await createFilePlatform().chooseFile();
    if (!mounted || file == null) return;
    final validation = validateEvidence(file);
    setState(() {
      _fileError = validation;
      if (validation == null) _files.add(file);
    });
  }

  Future<void> _save(UserRole role, List<ContratoModel> contracts) async {
    if (!_formKey.currentState!.validate() || _saving) return;
    if (_date == null || _methodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona fecha y método de pago.')));
      return;
    }
    final contract = _findContract(contracts);
    final amount = _parsedAmount();
    if (contract == null || amount == null) return;
    setState(() => _saving = true);
    final controller = ref.read(pagosControllerProvider(role).notifier);
    if (!AppEnv.demoMode) {
      try {
        final payload = <String, dynamic>{
          'forma_pago_id': _methodId,
          'monto': amount.toString(),
          'fecha_pago': _date!.toUtc().toIso8601String(),
          'observaciones': _observations.text.trim().isEmpty
              ? null
              : _observations.text.trim(),
          if (_isCash) 'folio_recibo': _receipt.text.trim(),
          if (_isCash) 'recibido_por': _receivedById,
        };
        if (_savedId == null) {
          final saved = widget.paymentId == null
              ? await controller.createApi({
                  ...payload,
                  'contrato_id': contract.id,
                  if (_scheduleId != null) 'pago_programado_id': _scheduleId,
                  if (_reference.text.trim().isNotEmpty)
                    'referencia_pago': _reference.text.trim()
                })
              : await controller.correctApi(widget.paymentId!,
                  {...payload, 'motivo': _reason.text.trim()});
          _savedId = saved.id;
        }
        final repository = ref.read(pagosRepositoryProvider);
        for (final file in List<SelectedFile>.of(_files)) {
          await repository.upload(_savedId!, file);
          _files.remove(file);
        }
        ref.invalidate(pagoDetailProvider(_savedId!));
        if (mounted) context.go('/pagos/$_savedId');
      } catch (error) {
        if (mounted) {
          final savedMessage = _savedId == null
              ? ''
              : 'El pago ya fue guardado. Falta completar la evidencia. ';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  '$savedMessage${ApiErrorModel.fromObject(error).message}')));
          if (_savedId != null) {
            ref.invalidate(pagoDetailProvider(_savedId!));
            context.go('/pagos/$_savedId');
          }
        }
      } finally {
        if (mounted) setState(() => _saving = false);
      }
      return;
    }
    final payment = widget.paymentId == null
        ? controller.createPayment(
            contract: contract,
            methodId: _methodId!,
            method: _methodLabel,
            amount: amount,
            date: _date!,
            reference: _reference.text.trim(),
            observations: _observations.text.trim(),
            scheduleId: _scheduleId,
            receiptFolio: _receipt.text.trim(),
            receivedBy: _receivedById,
            evidenceFiles: _files,
          )
        : controller.resubmitRejectedDemo(
            paymentId: widget.paymentId!,
            contract: contract,
            methodId: _methodId!,
            method: _methodLabel,
            amount: amount,
            date: _date!,
            reference: _reference.text.trim(),
            observations: _observations.text.trim(),
            scheduleId: _scheduleId,
            receiptFolio: _receipt.text.trim(),
            receivedBy: _receivedById,
            existingEvidence: _existingEvidence,
            evidenceFiles: _files,
          );
    if (!mounted) return;
    setState(() => _saving = false);
    context.go('/pagos/${payment.id}');
  }
}
