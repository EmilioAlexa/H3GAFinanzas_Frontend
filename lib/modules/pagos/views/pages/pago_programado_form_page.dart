import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/env.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/network/api_error_model.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_notice.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/auth.dart';
import '../../../contratos/contratos.dart';
import '../../controllers/pago_options_controller.dart';
import '../../controllers/pagos_controller.dart';

class PagoProgramadoFormPage extends ConsumerStatefulWidget {
  const PagoProgramadoFormPage({super.key});
  @override
  ConsumerState<PagoProgramadoFormPage> createState() =>
      _PagoProgramadoFormPageState();
}

class _PagoProgramadoFormPageState
    extends ConsumerState<PagoProgramadoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _number = TextEditingController(text: '1');
  final _amount = TextEditingController();
  String? _contractId;
  int? _chargeTypeId;
  String? _classification;
  final _penaltyReason = TextEditingController();
  final _duplicateReason = TextEditingController();
  final _beneficiaryAmount = TextEditingController();
  bool _saving = false;
  DateTime? _expected;
  DateTime? _due;
  DateTime? _period;

  @override
  void dispose() {
    _number.dispose();
    _amount.dispose();
    _penaltyReason.dispose();
    _duplicateReason.dispose();
    _beneficiaryAmount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    if (session == null) {
      return const AppStatePanel(
          icon: Icons.lock_outline,
          title: 'Inicia sesión para continuar',
          message: 'La programación requiere sesión activa.');
    }
    final optionsState =
        AppEnv.demoMode ? null : ref.watch(pagoOptionsProvider(session.role));
    final options = optionsState?.valueOrNull;
    final contracts = AppEnv.demoMode
        ? ContratosDemoFixtures.contracts
            .where((item) =>
                session.role != UserRole.asesor ||
                item.assignedToCurrentAdvisor)
            .toList()
        : options?.contracts ?? <ContratoModel>[];
    final selectedContract =
        contracts.where((e) => e.id == _contractId).firstOrNull;
    final isApd = selectedContract?.servicioNombre.toLowerCase() == 'apd';
    final isPenalty = options?.chargeTypes
            .where((e) => e.id == _chargeTypeId)
            .any((e) =>
                e.name.toLowerCase().replaceAll('ó', 'o') == 'penalizacion') ??
        false;
    return SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space6),
        child: Form(
          key: _formKey,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AppPageHeader(
                eyebrow: 'Cobro esperado',
                title: 'Programar pago',
                description: 'Agrega un cobro esperado a un contrato.',
                actions: [
                  TextButton.icon(
                      onPressed: () => context.go('/pagos-programados'),
                      icon: const Icon(Icons.close),
                      label: const Text('Cancelar'))
                ]),
            const AppNotice(
                text:
                    'Los pagos programados son previsiones y no generan automáticamente un pago. No se simulan recurrencias ni vencimientos calculados.'),
            const SizedBox(height: AppTheme.space4),
            _section(context, 'Datos del cobro', [
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
                        _classification = null;
                        _beneficiaryAmount.clear();
                      }),
                  validator: (value) =>
                      value == null ? 'Selecciona un contrato.' : null),
              const SizedBox(height: AppTheme.space3),
              if (!AppEnv.demoMode) ...[
                DropdownButtonFormField<int>(
                    initialValue: _chargeTypeId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                        labelText: 'Tipo de cobro (opcional)'),
                    items: [
                      const DropdownMenuItem<int>(
                          value: null, child: Text('Sin tipo específico')),
                      for (final type in options?.chargeTypes ?? <PagoOption>[])
                        DropdownMenuItem(value: type.id, child: Text(type.name))
                    ],
                    onChanged: (value) => setState(() {
                          _chargeTypeId = value;
                          _penaltyReason.clear();
                        })),
                if (isPenalty)
                  TextFormField(
                      controller: _penaltyReason,
                      maxLength: 1000,
                      decoration: const InputDecoration(
                          labelText: 'Motivo de penalización *'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Indica el motivo.'
                              : null),
                TextFormField(
                    controller: _duplicateReason,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                        labelText:
                            'Justificación de duplicado (si corresponde)')),
                if (isApd) ...[
                  DropdownButtonFormField<String>(
                      initialValue: _classification,
                      decoration: const InputDecoration(
                          labelText: 'Clasificación APD (opcional)'),
                      items: const [
                        DropdownMenuItem<String>(
                            value: null, child: Text('Sin clasificación')),
                        DropdownMenuItem(
                            value: 'TOPADO', child: Text('Topado')),
                        DropdownMenuItem(
                            value: 'NO_TOPADO', child: Text('No topado'))
                      ],
                      onChanged: (value) =>
                          setState(() => _classification = value)),
                  TextFormField(
                      controller: _beneficiaryAmount,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText:
                              'Importe recibido por beneficiario APD (opcional)'),
                      validator: (value) => value == null ||
                              value.trim().isEmpty ||
                              RegExp(r'^\d{1,10}(\.\d{1,2})?$')
                                  .hasMatch(value.trim())
                          ? null
                          : 'Importe inválido.'),
                ],
              ],
              AppTextField(
                  controller: _number,
                  label: 'Número de pago *',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final number = int.tryParse(value ?? '');
                    return number == null || number < 1 || number > 32767
                        ? 'Ingresa un número entre 1 y 32767.'
                        : null;
                  }),
              const SizedBox(height: AppTheme.space3),
              AppTextField(
                  controller: _amount,
                  label: 'Monto esperado (opcional)',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    try {
                      final d = Decimal.parse(value.trim());
                      if (d < Decimal.zero ||
                          (value.contains('.') &&
                              value.split('.').last.length > 2)) {
                        return 'Monto inválido (máximo dos decimales).';
                      }
                    } on FormatException {
                      return 'Ingresa un monto válido.';
                    }
                    return null;
                  }),
              const SizedBox(height: AppTheme.space2),
              _datePicker('Fecha esperada', _expected,
                  (date) => setState(() => _expected = date)),
              _datePicker('Fecha de vencimiento', _due,
                  (date) => setState(() => _due = date)),
              _datePicker('Periodo (opcional)', _period,
                  (date) => setState(() => _period = date)),
            ]),
            const SizedBox(height: AppTheme.space4),
            if (!AppEnv.demoMode) ...[
              if (optionsState?.isLoading == true)
                const Text('Cargando opciones…'),
              if (optionsState?.hasError == true)
                Text(ApiErrorModel.fromObject(optionsState!.error!).message),
              if (options?.chargeError != null)
                const Text(
                    'No se pudieron consultar los tipos de cobro. Puedes reintentar la carga.'),
              if (contracts.isEmpty) const Text('Sin contratos disponibles.'),
              TextButton(
                  onPressed: () =>
                      ref.invalidate(pagoOptionsProvider(session.role)),
                  child: const Text('Actualizar opciones')),
            ],
            FilledButton.icon(
                onPressed: _saving ||
                        (!AppEnv.demoMode &&
                            (options == null || contracts.isEmpty))
                    ? null
                    : () => _save(session.role, contracts),
                icon: const Icon(Icons.event_available),
                label: const Text('Guardar programación')),
          ]),
        ));
  }

  Widget _datePicker(
          String label, DateTime? value, ValueChanged<DateTime?> onChanged) =>
      ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          subtitle: Text(
              value == null ? 'Sin fecha' : MoneyFormatter.formatDate(value)),
          trailing: const Icon(Icons.calendar_month),
          onTap: () async {
            final date = await showDatePicker(
                context: context,
                initialDate: value ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100));
            if (date != null) onChanged(date);
          });

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

  Future<void> _save(UserRole role, List<ContratoModel> contracts) async {
    if (!_formKey.currentState!.validate() || _saving) return;
    if (!AppEnv.demoMode && _due == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('La fecha de vencimiento es obligatoria.')));
      return;
    }
    final contract = contracts.firstWhere((item) => item.id == _contractId);
    final raw = _amount.text.trim();
    final amount = raw.isEmpty ? null : Decimal.parse(raw);
    if (!AppEnv.demoMode) {
      setState(() => _saving = true);
      try {
        String date(DateTime value) =>
            '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
        await ref.read(pagosRepositoryProvider).createSchedule({
          'contrato_id': contract.id,
          'numero_pago': int.parse(_number.text),
          'fecha_vencimiento': date(_due!),
          if (_chargeTypeId != null) 'tipo_cobro_id': _chargeTypeId,
          if (_expected != null) 'fecha_esperada': date(_expected!),
          if (amount != null) 'monto_esperado': amount.toString(),
          if (_period != null) 'periodo': date(_period!),
          if (_penaltyReason.text.trim().isNotEmpty)
            'motivo_penalizacion': _penaltyReason.text.trim(),
          if (_duplicateReason.text.trim().isNotEmpty)
            'justificacion_duplicado': _duplicateReason.text.trim(),
          if (_classification != null)
            'clasificacion_tope_apd': _classification,
          if (_beneficiaryAmount.text.trim().isNotEmpty)
            'monto_recibido_beneficiario_apd': _beneficiaryAmount.text.trim(),
        });
        if (!mounted) return;
        await ref.read(pagosControllerProvider(role).notifier).load();
        if (mounted) context.go('/pagos-programados');
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(ApiErrorModel.fromObject(error).message)));
        }
      } finally {
        if (mounted) setState(() => _saving = false);
      }
      return;
    }
    ref.read(pagosControllerProvider(role).notifier).createScheduled(
        contract: contract,
        number: int.parse(_number.text),
        amount: amount,
        expectedDate: _expected,
        dueDate: _due,
        period: _period);
    context.go('/pagos-programados');
  }
}
