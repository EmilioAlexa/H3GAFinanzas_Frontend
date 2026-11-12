import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/platform/file_platform_factory.dart';
import '../../../../core/platform/selected_file.dart';
import '../../../../core/utils/money_formatter.dart';
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
  String? _receivedById;
  final _place = TextEditingController();
  String? _contractId;
  String? _scheduleId;
  int _methodId = 1;
  DateTime _date = DateTime.now();
  final List<SelectedFile> _files = [];
  String? _fileError;
  bool _saving = false;
  final _filePlatform = createFilePlatform();

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _observations.dispose();
    _receipt.dispose();
    _place.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    if (session == null) {
      return const AppStatePanel(
          icon: Icons.lock_outline,
          title: 'Inicia sesión para continuar',
          message: 'El registro requiere sesión activa.');
    }
    if (!ref.watch(pagosControllerProvider(session.role).notifier).demoMode) {
      return const AppStatePanel(
          icon: Icons.link_off,
          title: 'Registro sin conectar',
          message:
              'El formulario de captura se habilitará al integrar el endpoint B5.');
    }
    final contracts = ContratosDemoFixtures.contracts
        .where((item) =>
            session.role != UserRole.asesor || item.assignedToCurrentAdvisor)
        .toList();
    final scheduled = ref
            .watch(pagosControllerProvider(session.role))
            .valueOrNull
            ?.scheduled ??
        const <PagoProgramadoModel>[];
    final isCash = _methodId == 3;
    return SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space6),
        child: Form(
          key: _formKey,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AppPageHeader(
                eyebrow: 'Captura de movimiento',
                title: 'Registrar pago',
                description:
                    'Completa los datos del pago y adjunta su comprobante.',
                actions: [
                  TextButton.icon(
                      onPressed: () => context.go('/pagos'),
                      icon: const Icon(Icons.close),
                      label: const Text('Cancelar'))
                ]),
            const AppNotice(
                text:
                    'Este formulario es una demostración local. Al guardar no se crea un movimiento en el backend ni se suben los archivos.'),
            const SizedBox(height: AppTheme.space4),
            _section(context, 'Datos del pago', [
              DropdownButtonFormField<String>(
                  initialValue: _contractId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Contrato *'),
                  items: contracts
                      .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.folio} · ${c.clienteNombre}',
                              overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (value) => setState(() {
                        _contractId = value;
                        _scheduleId = null;
                      }),
                  validator: (value) =>
                      value == null ? 'Selecciona un contrato.' : null),
              const SizedBox(height: AppTheme.space3),
              DropdownButtonFormField<int>(
                  initialValue: _methodId,
                  decoration:
                      const InputDecoration(labelText: 'Forma de pago *'),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Transferencia')),
                    DropdownMenuItem(value: 2, child: Text('Depósito')),
                    DropdownMenuItem(value: 3, child: Text('Efectivo')),
                    DropdownMenuItem(value: 4, child: Text('Cheque'))
                  ],
                  onChanged: (value) => setState(() => _methodId = value ?? 1)),
              const SizedBox(height: AppTheme.space3),
              AppTextField(
                  controller: _amount,
                  label: 'Importe *',
                  hint: '0.00',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: const Icon(Icons.attach_money),
                  validator: _validateAmount),
              const SizedBox(height: AppTheme.space3),
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fecha del pago *'),
                  subtitle: Text(MoneyFormatter.formatDate(_date)),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: _chooseDate),
              DropdownButtonFormField<String>(
                  initialValue: _matchingSchedules(scheduled)
                          .any((s) => s.id == _scheduleId)
                      ? _scheduleId
                      : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      labelText: 'Pago programado (opcional)'),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Sin pago programado')),
                    ..._matchingSchedules(scheduled).map((s) =>
                        DropdownMenuItem(
                            value: s.id,
                            child: Text('Pago ${s.numeroPago} · ${s.estado}',
                                overflow: TextOverflow.ellipsis)))
                  ],
                  onChanged: (value) => setState(() => _scheduleId = value)),
              const SizedBox(height: AppTheme.space3),
              AppTextField(
                  controller: _reference,
                  label: 'Referencia',
                  hint: 'Referencia bancaria o folio'),
              const SizedBox(height: AppTheme.space3),
              if (isCash) ...[
                const AppNotice(
                    type: AppNoticeType.warning,
                    text:
                        'Para efectivo el contrato requiere folio de recibo y persona receptora.'),
                const SizedBox(height: AppTheme.space3),
                AppTextField(
                    controller: _receipt,
                    label: 'Folio de recibo *',
                    validator: (v) => (v?.trim().isEmpty ?? true)
                        ? 'Ingresa el folio del recibo.'
                        : null),
                const SizedBox(height: AppTheme.space3),
                DropdownButtonFormField<String>(
                    initialValue: _receivedById,
                    decoration:
                        const InputDecoration(labelText: 'Recibido por *'),
                    items: const [
                      DropdownMenuItem(
                          value: '00000000-0000-4000-8000-000000000001',
                          child: Text('Mariana López (demo)')),
                      DropdownMenuItem(
                          value: '00000000-0000-4000-8000-000000000002',
                          child: Text('Ricardo Pérez (demo)')),
                    ],
                    onChanged: (value) => setState(() => _receivedById = value),
                    validator: (value) => value == null
                        ? 'Selecciona a la persona receptora.'
                        : null),
                const SizedBox(height: AppTheme.space3),
                AppTextField(controller: _place, label: 'Lugar de recepción'),
                const SizedBox(height: AppTheme.space3),
              ],
              AppTextField(
                  controller: _observations,
                  label: 'Observaciones',
                  hint: 'Notas adicionales'),
            ]),
            const SizedBox(height: AppTheme.space4),
            _section(context, 'Comprobante', [
              const AppNotice(
                  text:
                      'Formatos admitidos por el backend: PDF, JPG y JPEG; máximo 10 MB. Figma también menciona PNG, pero la API no lo admite.'),
              const SizedBox(height: AppTheme.space2),
              OutlinedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Seleccionar comprobante')),
              if (_fileError != null)
                Padding(
                    padding: const EdgeInsets.only(top: AppTheme.space2),
                    child: Text(_fileError!,
                        style: const TextStyle(color: AppTheme.danger))),
              for (final file in _files)
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.description_outlined),
                    title: Text(file.name),
                    subtitle: Text(
                        '${(file.bytes.lengthInBytes / 1024).ceil()} KB · solo local'),
                    trailing: IconButton(
                        tooltip: 'Quitar archivo',
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _files.remove(file)))),
            ]),
            const SizedBox(height: AppTheme.space4),
            FilledButton.icon(
                onPressed:
                    _saving ? null : () => _save(session.role, contracts),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: const Text('Registrar pago de demostración')),
          ]),
        ));
  }

  List<PagoProgramadoModel> _matchingSchedules(
          List<PagoProgramadoModel> list) =>
      list.where((s) => s.contratoId == _contractId).toList();

  Widget _section(BuildContext context, String title, List<Widget> children) =>
      Container(
          padding: const EdgeInsets.all(AppTheme.space4),
          decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border.all(color: AppTheme.line),
              borderRadius: BorderRadius.circular(AppTheme.radius)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const Divider(height: AppTheme.space5),
            ...children
          ]));

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
      if (normalized.contains('.') && normalized.split('.').last.length > 2) {
        return 'Usa máximo dos decimales.';
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
        lastDate: DateTime(2100));
    if (date != null && mounted) setState(() => _date = date);
  }

  Future<void> _pickFile() async {
    final file = await _filePlatform.chooseFile();
    if (file == null || !mounted) return;
    final validation = validateEvidence(file);
    setState(() {
      _fileError = validation;
      if (validation == null) _files.add(file);
    });
  }

  Future<void> _save(UserRole role, List<ContratoModel> contracts) async {
    if (!_formKey.currentState!.validate()) return;
    final contract = contracts.where((item) => item.id == _contractId).first;
    setState(() => _saving = true);
    final amount = Decimal.parse(
        _amount.text.replaceAll(',', '').replaceAll('\$', '').trim());
    final method = switch (_methodId) {
      1 => 'Transferencia',
      2 => 'Depósito',
      3 => 'Efectivo',
      _ => 'Cheque'
    };
    final payment = ref
        .read(pagosControllerProvider(role).notifier)
        .createPayment(
            contract: contract,
            methodId: _methodId,
            method: method,
            amount: amount,
            date: _date,
            reference: _reference.text.trim(),
            observations: _observations.text.trim(),
            scheduleId: _scheduleId,
            receiptFolio: _receipt.text.trim(),
            receivedBy: _receivedById,
            evidenceFiles: _files);
    if (!mounted) return;
    setState(() => _saving = false);
    context.go('/pagos/${payment.id}');
  }
}
