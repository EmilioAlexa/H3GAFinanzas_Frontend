import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_notice.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/auth.dart';
import '../../../contratos/contratos.dart';
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
  DateTime? _expected;
  DateTime? _due;
  DateTime? _period;

  @override
  void dispose() {
    _number.dispose();
    _amount.dispose();
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
    final controller =
        ref.watch(pagosControllerProvider(session.role).notifier);
    if (!controller.demoMode) {
      return const AppStatePanel(
          icon: Icons.link_off,
          title: 'Programación sin conectar',
          message: 'El formulario se habilitará al integrar el endpoint B5.');
    }
    final contracts = ContratosDemoFixtures.contracts
        .where((item) =>
            session.role != UserRole.asesor || item.assignedToCurrentAdvisor)
        .toList();
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
                  onChanged: (value) => setState(() => _contractId = value),
                  validator: (value) =>
                      value == null ? 'Selecciona un contrato.' : null),
              const SizedBox(height: AppTheme.space3),
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
            FilledButton.icon(
                onPressed: () => _save(session.role, contracts),
                icon: const Icon(Icons.event_available),
                label: const Text('Guardar programación demo')),
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

  void _save(UserRole role, List<ContratoModel> contracts) {
    if (!_formKey.currentState!.validate()) return;
    final contract = contracts.firstWhere((item) => item.id == _contractId);
    final raw = _amount.text.trim();
    final amount = raw.isEmpty ? null : Decimal.parse(raw);
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
