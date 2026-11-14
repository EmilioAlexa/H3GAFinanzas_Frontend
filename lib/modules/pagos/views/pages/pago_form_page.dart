import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/platform/file_platform_factory.dart';
import '../../../../core/platform/selected_file.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/responsive/window_size_class.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_notice.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/auth.dart';
import '../../../contratos/contratos.dart';
import '../../controllers/pagos_controller.dart';
import '../../models/pago_programado_model.dart';

const maxEvidenceBytes = 10 * 1024 * 1024;

String? validateEvidence(SelectedFile file) {
  final extension = file.name.split('.').last.toLowerCase();
  if (!const {'pdf', 'jpg', 'jpeg'}.contains(extension)) {
    return 'Solo se permiten archivos PDF, JPG o JPEG.';
  }
  if (file.bytes.lengthInBytes > maxEvidenceBytes) {
    return 'El archivo supera el límite de 10 MB.';
  }
  return null;
}

class PagoFormPage extends ConsumerStatefulWidget {
  const PagoFormPage({super.key});

  @override
  ConsumerState<PagoFormPage> createState() => _PagoFormPageState();
}

class _PagoFormPageState extends ConsumerState<PagoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  final _observations = TextEditingController();
  final _receipt = TextEditingController();
  final _place = TextEditingController();
  final List<SelectedFile> _files = [];
  String? _clientId;
  String? _contractId;
  String? _scheduleId;
  String? _receivedById;
  String? _fileError;
  int _methodId = 1;
  DateTime _date = DateTime.now();
  bool _saving = false;

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
    _place.dispose();
    super.dispose();
  }

  void _refreshSummary() {
    if (mounted) setState(() {});
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
    if (!ref.watch(pagosControllerProvider(session.role).notifier).demoMode) {
      return const AppStatePanel(
        icon: Icons.link_off,
        title: 'Registro no disponible',
        message: 'No fue posible cargar el formulario de pago.',
      );
    }

    final contracts = ContratosDemoFixtures.contracts
        .where((item) =>
            session.role != UserRole.asesor || item.assignedToCurrentAdvisor)
        .toList();
    final clients = <String, String>{
      for (final contract in contracts)
        contract.clienteId: contract.clienteNombre,
    };
    final schedules = ref
            .watch(pagosControllerProvider(session.role))
            .valueOrNull
            ?.scheduled ??
        const <PagoProgramadoModel>[];
    final matchingContracts =
        contracts.where((contract) => contract.clienteId == _clientId).toList();
    final selectedContract = _findContract(contracts);

    return LayoutBuilder(
      builder: (context, constraints) {
        final expanded = Responsive.classify(constraints.maxWidth) ==
            WindowSizeClass.expandido;
        final sections = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _relationSection(clients, matchingContracts),
            const SizedBox(height: AppTheme.space4),
            _paymentSection(schedules),
            const SizedBox(height: AppTheme.space4),
            _evidenceSection(),
          ],
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.space6),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppPageHeader(
                  eyebrow: 'Captura de movimiento',
                  title: 'Registrar pago',
                  description:
                      'Relaciona el pago con su contrato y agrega la información del comprobante.',
                  actions: [
                    OutlinedButton.icon(
                      onPressed: () => context.go('/pagos'),
                      icon: const Icon(Icons.close),
                      label: const Text('Cancelar'),
                    ),
                  ],
                ),
                if (expanded)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 7, child: sections),
                      const SizedBox(width: AppTheme.space4),
                      Expanded(
                        flex: 3,
                        child: _summaryCard(
                          context,
                          selectedContract,
                          session.role,
                          contracts,
                        ),
                      ),
                    ],
                  )
                else ...[
                  sections,
                  const SizedBox(height: AppTheme.space4),
                  _summaryCard(
                    context,
                    selectedContract,
                    session.role,
                    contracts,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _relationSection(
    Map<String, String> clients,
    List<ContratoModel> matchingContracts,
  ) =>
      _section(
        context,
        'Relación del pago',
        'Selecciona el cliente y el contrato al que corresponde.',
        [
          DropdownButtonFormField<String>(
            initialValue: clients.containsKey(_clientId) ? _clientId : null,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Cliente *'),
            items: clients.entries
                .map((entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value, overflow: TextOverflow.ellipsis),
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
          const SizedBox(height: AppTheme.space3),
          DropdownButtonFormField<String>(
            initialValue:
                matchingContracts.any((item) => item.id == _contractId)
                    ? _contractId
                    : null,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Contrato *'),
            items: matchingContracts
                .map((contract) => DropdownMenuItem(
                      value: contract.id,
                      child: Text(
                        '${contract.folio} · ${contract.estadoNombre}',
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
          if (_findContract(matchingContracts) case final contract?) ...[
            const SizedBox(height: AppTheme.space3),
            _readOnlyField('Servicio', contract.servicioNombre),
          ],
        ],
      );

  Widget _paymentSection(List<PagoProgramadoModel> schedules) {
    final isCash = _methodId == 3;
    final matchingSchedules = _matchingSchedules(schedules);
    return _section(
      context,
      'Información del pago',
      'Agrega el importe, la fecha y el método registrado.',
      [
        DropdownButtonFormField<int>(
          initialValue: _methodId,
          decoration: const InputDecoration(labelText: 'Forma de pago *'),
          items: const [
            DropdownMenuItem(value: 1, child: Text('Transferencia')),
            DropdownMenuItem(value: 2, child: Text('Depósito')),
            DropdownMenuItem(value: 3, child: Text('Efectivo')),
            DropdownMenuItem(value: 4, child: Text('Cheque')),
          ],
          onChanged: (value) => setState(() => _methodId = value ?? 1),
        ),
        const SizedBox(height: AppTheme.space3),
        AppTextField(
          controller: _amount,
          label: 'Importe *',
          hint: '0.00',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          prefixIcon: const Icon(Icons.attach_money),
          validator: _validateAmount,
        ),
        const SizedBox(height: AppTheme.space2),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Fecha del pago *'),
          subtitle: Text(MoneyFormatter.formatDate(_date)),
          trailing: const Icon(Icons.calendar_month),
          onTap: _chooseDate,
        ),
        DropdownButtonFormField<String>(
          initialValue:
              matchingSchedules.any((schedule) => schedule.id == _scheduleId)
                  ? _scheduleId
                  : null,
          isExpanded: true,
          decoration:
              const InputDecoration(labelText: 'Pago programado (opcional)'),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Sin pago programado'),
            ),
            ...matchingSchedules.map((schedule) => DropdownMenuItem(
                  value: schedule.id,
                  child: Text(
                    'Pago ${schedule.numeroPago} · ${schedule.estado}',
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
          ],
          onChanged: (value) => setState(() => _scheduleId = value),
        ),
        const SizedBox(height: AppTheme.space3),
        AppTextField(
          controller: _reference,
          label: 'Referencia',
          hint: 'Referencia bancaria o folio',
        ),
        if (isCash) ...[
          const SizedBox(height: AppTheme.space3),
          const AppNotice(
            type: AppNoticeType.warning,
            text:
                'Para efectivo se requiere folio de recibo y persona receptora.',
          ),
          const SizedBox(height: AppTheme.space3),
          AppTextField(
            controller: _receipt,
            label: 'Folio de recibo *',
            validator: (value) => (value?.trim().isEmpty ?? true)
                ? 'Ingresa el folio del recibo.'
                : null,
          ),
          const SizedBox(height: AppTheme.space3),
          DropdownButtonFormField<String>(
            initialValue: _receivedById,
            decoration: const InputDecoration(labelText: 'Recibido por *'),
            items: const [
              DropdownMenuItem(
                value: '00000000-0000-4000-8000-000000000001',
                child: Text('Mariana López'),
              ),
              DropdownMenuItem(
                value: '00000000-0000-4000-8000-000000000002',
                child: Text('Ricardo Pérez'),
              ),
            ],
            onChanged: (value) => setState(() => _receivedById = value),
            validator: (value) =>
                value == null ? 'Selecciona a la persona receptora.' : null,
          ),
          const SizedBox(height: AppTheme.space3),
          AppTextField(controller: _place, label: 'Lugar de recepción'),
        ],
        const SizedBox(height: AppTheme.space3),
        AppTextField(
          controller: _observations,
          label: 'Observaciones',
          hint: 'Notas adicionales',
        ),
      ],
    );
  }

  Widget _evidenceSection() => _section(
        context,
        'Comprobante',
        'Adjunta el archivo que respalda el pago.',
        [
          const AppNotice(text: 'PDF, JPG o JPEG · Máximo 10 MB por archivo.'),
          const SizedBox(height: AppTheme.space3),
          OutlinedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.upload_file),
            label: const Text('Seleccionar comprobante'),
          ),
          if (_fileError != null)
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.space2),
              child: Text(
                _fileError!,
                style: const TextStyle(color: AppTheme.danger),
              ),
            ),
          for (final file in _files)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.description_outlined),
              title:
                  Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${(file.bytes.lengthInBytes / 1024).ceil()} KB'),
              trailing: IconButton(
                tooltip: 'Quitar archivo',
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _files.remove(file)),
              ),
            ),
        ],
      );

  Widget _summaryCard(
    BuildContext context,
    ContratoModel? contract,
    UserRole role,
    List<ContratoModel> contracts,
  ) {
    final amount = _parsedAmount();
    return _section(
      context,
      'Resumen del registro',
      'Revisa los datos antes de guardar.',
      [
        _summaryLine(
            'Cliente', contract?.clienteNombre ?? 'Selecciona un cliente'),
        _summaryLine('Contrato', contract?.folio ?? 'Sin seleccionar'),
        _summaryLine('Servicio', contract?.servicioNombre ?? '—'),
        _summaryLine('Fecha', MoneyFormatter.formatDate(_date)),
        _summaryLine('Método', _methodLabel),
        const Divider(height: AppTheme.space5),
        Text(
          amount == null ? 'Importe pendiente' : MoneyFormatter.format(amount),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.primary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppTheme.space2),
        Text(
          _files.isEmpty
              ? 'Sin comprobante adjunto'
              : '${_files.length} comprobante${_files.length == 1 ? '' : 's'} adjunto${_files.length == 1 ? '' : 's'}',
          style: const TextStyle(color: AppTheme.muted, fontSize: 12),
        ),
        const SizedBox(height: AppTheme.space4),
        AppButton(
          label: 'Registrar pago',
          onPressed: _saving ? null : () => _save(role, contracts),
          loading: _saving,
          expand: true,
        ),
      ],
    );
  }

  Widget _summaryLine(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 78,
              child: Text(
                label,
                style: const TextStyle(color: AppTheme.muted, fontSize: 11),
              ),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: AppTheme.inkSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _readOnlyField(String label, String value) => InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppTheme.surfaceSecondary,
        ),
        child:
            Text(value, style: const TextStyle(color: AppTheme.inkSecondary)),
      );

  Widget _section(
    BuildContext context,
    String title,
    String description,
    List<Widget> children,
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
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppTheme.space1),
            Text(
              description,
              style: const TextStyle(color: AppTheme.muted, fontSize: 12),
            ),
            const Divider(height: AppTheme.space5),
            ...children,
          ],
        ),
      );

  ContratoModel? _findContract(List<ContratoModel> contracts) {
    for (final contract in contracts) {
      if (contract.id == _contractId) return contract;
    }
    return null;
  }

  List<PagoProgramadoModel> _matchingSchedules(
    List<PagoProgramadoModel> schedules,
  ) =>
      schedules
          .where((schedule) => schedule.contratoId == _contractId)
          .toList();

  Decimal? _parsedAmount() {
    final value = _amount.text.replaceAll(',', '').replaceAll('\$', '').trim();
    try {
      return value.isEmpty ? null : Decimal.parse(value);
    } on FormatException {
      return null;
    }
  }

  String get _methodLabel => switch (_methodId) {
        1 => 'Transferencia',
        2 => 'Depósito',
        3 => 'Efectivo',
        _ => 'Cheque',
      };

  String? _validateAmount(String? value) {
    final normalized =
        (value ?? '').replaceAll(',', '').replaceAll('\$', '').trim();
    if (normalized.isEmpty) return 'Ingresa un importe.';
    try {
      final amount = Decimal.parse(normalized);
      if (amount <= Decimal.zero) return 'El importe debe ser mayor que cero.';
      if (!RegExp(r'^\d{1,10}(\.\d{1,2})?$').hasMatch(normalized)) {
        return 'Usa hasta 10 dígitos enteros y máximo dos decimales.';
      }
    } on FormatException {
      return 'Ingresa un importe válido.';
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
    if (!_formKey.currentState!.validate()) return;
    final contract = _findContract(contracts);
    final amount = _parsedAmount();
    if (contract == null || amount == null) return;
    setState(() => _saving = true);

    final payment =
        ref.read(pagosControllerProvider(role).notifier).createPayment(
              contract: contract,
              methodId: _methodId,
              method: _methodLabel,
              amount: amount,
              date: _date,
              reference: _reference.text.trim(),
              observations: _observations.text.trim(),
              scheduleId: _scheduleId,
              receiptFolio: _receipt.text.trim(),
              receivedBy: _receivedById,
              evidenceFiles: _files,
            );
    if (!mounted) return;
    setState(() => _saving = false);
    context.go('/pagos/${payment.id}');
  }
}
