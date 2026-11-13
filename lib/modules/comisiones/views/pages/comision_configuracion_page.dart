import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/env.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_notice.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../../auth/auth.dart';
import '../../controllers/comisiones_controller.dart';
import '../../fixtures/comisiones_demo_fixtures.dart';
import '../../models/commission_line_model.dart';
import '../../models/commission_payment_model.dart';
import '../../models/dispersion_receiver_model.dart';
import '../../utils/commission_math.dart';

class ComisionConfiguracionPage extends ConsumerStatefulWidget {
  const ComisionConfiguracionPage({required this.contractId, super.key});
  final String contractId;

  @override
  ConsumerState<ComisionConfiguracionPage> createState() =>
      _ComisionConfiguracionPageState();
}

class _ComisionConfiguracionPageState
    extends ConsumerState<ComisionConfiguracionPage> {
  String? _initializedContract;
  List<CommissionLineModel> _draft = [];
  int? _addConceptId;
  String? _addReceiverId;
  final _addPercentage = TextEditingController(text: '5');
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _addPercentage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    if (session == null || session.role == UserRole.asesor) {
      return const AppStatePanel(
        icon: Icons.lock_outline,
        title: 'Acceso restringido',
        message: 'Solo los perfiles administrativos editan la distribución.',
      );
    }
    if (!AppEnv.demoMode) {
      return const AppStatePanel(
        icon: Icons.link_off,
        title: 'Configuración sin conectar',
        message: 'La configuración real se habilitará en B7.',
      );
    }
    final asyncState = ref.watch(comisionesControllerProvider(session.role));
    return asyncState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => AppStatePanel(
        icon: Icons.cloud_off_outlined,
        title: 'No se pudo cargar la configuración',
        message: 'Inténtalo de nuevo.',
        action: TextButton.icon(
          onPressed: () => ref
              .read(comisionesControllerProvider(session.role).notifier)
              .load(),
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      ),
      data: (state) {
        final payment = ref
            .read(comisionesControllerProvider(session.role).notifier)
            .findContract(widget.contractId);
        if (state == null || payment == null) {
          return const AppStatePanel(
            icon: Icons.search_off_outlined,
            title: 'Contrato sin configuración',
            message: 'No hay una configuración  para este contrato.',
          );
        }
        if (_initializedContract != payment.contractId) {
          _initializedContract = payment.contractId;
          _draft = List.of(payment.configuration);
        }
        return _body(context, session.role, payment);
      },
    );
  }

  Widget _body(
      BuildContext context, UserRole role, CommissionPaymentModel payment) {
    final totalPercentage =
        CommissionMath.sum(_draft.map((line) => line.percentage));
    final remainingPercentage = Decimal.fromInt(100) - totalPercentage;
    final invalidSteps = _draft.any(
      (line) => !CommissionMath.isAllowedPercentage(line.percentage),
    );
    final exceeds = totalPercentage > Decimal.fromInt(100);
    final imssOnApd = payment.serviceName == 'APD' &&
        _draft.any((line) => line.conceptId == 4);
    final availableConcepts = ComisionesDemoFixtures.concepts
        .where((concept) =>
            !(payment.serviceName == 'APD' && concept.onlyImssServices))
        .toList();
    final assignedAmounts = _draft.map((line) =>
        CommissionMath.amountFor(payment.paymentAmount, line.percentage));
    final companyAmount = CommissionMath.remainderAmount(
      payment.paymentAmount,
      assignedAmounts,
    );
    final valid = !invalidSteps && !exceeds && !imssOnApd;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AppPageHeader(
          eyebrow: 'Contrato ${payment.contractFolio}',
          title: 'Configuración de comisiones',
          description:
              'Los cambios aplican a pagos futuros. Los snapshots existentes se conservan.',
          actions: [
            TextButton.icon(
              onPressed: () => context.go('/comisiones/${payment.id}'),
              icon: const Icon(Icons.close),
              label: const Text('Volver al detalle'),
            ),
          ],
        ),
        const AppNotice(
          text:
              'Empresa se calcula como remanente y no se captura. Los receptores se seleccionan del catálogo; sus IDs deben reemplazarse por los del backend.',
        ),
        const SizedBox(height: AppTheme.space4),
        _section(context, 'Distribución del pago de referencia', [
          _summary('Pago de referencia',
              MoneyFormatter.format(payment.paymentAmount)),
          _summary('Porcentaje asignado', '$totalPercentage%'),
          _summary('Empresa · remanente',
              '$remainingPercentage% · ${MoneyFormatter.format(companyAmount)}'),
        ]),
        const SizedBox(height: AppTheme.space4),
        _section(context, 'Destinos configurados', [
          if (_draft.isEmpty)
            const Text(
                'Aún no hay destinos. Agrega al menos uno o guarda la lista vacía.'),
          for (var index = 0; index < _draft.length; index++)
            _configRow(context, role, payment.serviceName, index),
          const Divider(height: AppTheme.space5),
          Text('Agregar comisión',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppTheme.space2),
          DropdownButtonFormField<int>(
            initialValue: _addConceptId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Concepto'),
            items: availableConcepts
                .map((item) => DropdownMenuItem(
                      value: item.id,
                      child: Text(item.name),
                    ))
                .toList(),
            onChanged: (value) => setState(() {
              _addConceptId = value;
              _addReceiverId = null;
              _error = null;
            }),
          ),
          const SizedBox(height: AppTheme.space2),
          _receiverDropdown(
            label: 'Receptor',
            conceptId: _addConceptId,
            selectedId: _addReceiverId,
            onChanged: (value) => setState(() => _addReceiverId = value),
          ),
          const SizedBox(height: AppTheme.space2),
          TextField(
            controller: _addPercentage,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Porcentaje',
              suffixText: '%',
              helperText: 'Incrementos de 0.5, desde 0 hasta 100.',
            ),
          ),
          const SizedBox(height: AppTheme.space2),
          OutlinedButton.icon(
            onPressed: _draft.length >= 20 ? null : _addLine,
            icon: const Icon(Icons.add),
            label: const Text('Agregar destino'),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppTheme.space2),
            AppNotice(type: AppNoticeType.error, text: _error!),
          ],
          if (invalidSteps || exceeds || imssOnApd) ...[
            const SizedBox(height: AppTheme.space2),
            AppNotice(
              type: AppNoticeType.error,
              text: imssOnApd
                  ? 'IMSS solo se permite en M10, M40 y M40 Retroactiva.'
                  : exceeds
                      ? 'La suma supera 100%; Empresa no puede ser negativa.'
                      : 'Todos los porcentajes deben avanzar en incrementos de 0.5.',
            ),
          ],
          const SizedBox(height: AppTheme.space3),
          FilledButton.icon(
            onPressed: valid && !_saving
                ? () => _save(role, payment.contractId, payment.contractFolio)
                : null,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Guardar configuración'),
          ),
        ]),
        const SizedBox(height: AppTheme.space4),
        _section(context, 'Historial del contrato', [
          for (final entry in payment.configurationHistory)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history),
              title: Text(entry),
              subtitle: const Text('Registro local'),
            ),
        ]),
      ]),
    );
  }

  Widget _configRow(
    BuildContext context,
    UserRole role,
    String serviceName,
    int index,
  ) {
    final line = _draft[index];
    final imssDisallowed = line.conceptId == 4 && serviceName == 'APD';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space3),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space3),
        decoration: BoxDecoration(
          color: AppTheme.surfaceSecondary,
          borderRadius: BorderRadius.circular(AppTheme.radiusField),
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
              child: Text(line.concept,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            IconButton(
              tooltip: 'Quitar ${line.concept}',
              onPressed: () => _removeLine(index),
              icon: const Icon(Icons.delete_outline),
            ),
          ]),
          _receiverDropdown(
            label: 'Receptor',
            conceptId: line.conceptId,
            selectedId: line.receiverId,
            onChanged: (value) {
              if (value == null) return;
              final receiver = ref
                  .read(comisionesControllerProvider(role).notifier)
                  .activeReceiversFor(line.conceptId)
                  .where((item) => item.id == value)
                  .first;
              setState(() => _draft[index] = line.copyWith(
                    receiverId: value,
                    receiverName: receiver.name,
                  ));
            },
          ),
          const SizedBox(height: AppTheme.space2),
          TextFormField(
            key: ValueKey('percentage-$index-${line.conceptId}'),
            initialValue: line.percentage.toString(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration:
                const InputDecoration(labelText: 'Porcentaje', suffixText: '%'),
            onChanged: (value) {
              final decimal = Decimal.tryParse(value);
              if (decimal != null) {
                setState(
                    () => _draft[index] = line.copyWith(percentage: decimal));
              }
            },
          ),
          if (imssDisallowed)
            const Padding(
              padding: EdgeInsets.only(top: AppTheme.space2),
              child: Text('IMSS no aplica a APD.'),
            ),
        ]),
      ),
    );
  }

  Widget _receiverDropdown({
    required String label,
    required int? conceptId,
    required String? selectedId,
    required ValueChanged<String?> onChanged,
  }) {
    final all = conceptId == null
        ? const <DispersionReceiverModel>[]
        : ref
            .read(comisionesControllerProvider(
                    ref.read(authControllerProvider).valueOrNull!.role)
                .notifier)
            .activeReceiversFor(conceptId);
    final validValue =
        all.any((receiver) => receiver.id == selectedId) ? selectedId : null;
    return DropdownButtonFormField<String>(
      initialValue: validValue,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: all
          .map((receiver) => DropdownMenuItem(
                value: receiver.id,
                child: Text(
                  receiver.role == null
                      ? receiver.name
                      : '${receiver.name} · ${receiver.role}',
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .toList(),
      onChanged: conceptId == null ? null : onChanged,
    );
  }

  void _addLine() {
    final concept = ComisionesDemoFixtures.concepts
        .where((item) => item.id == _addConceptId);
    final receivers = _addConceptId == null
        ? <DispersionReceiverModel>[]
        : ref
            .read(comisionesControllerProvider(
                    ref.read(authControllerProvider).valueOrNull!.role)
                .notifier)
            .activeReceiversFor(_addConceptId!);
    final receiver = receivers.where((item) => item.id == _addReceiverId);
    final percentage = Decimal.tryParse(_addPercentage.text.trim());
    if (concept.isEmpty || receiver.isEmpty || percentage == null) {
      setState(
          () => _error = 'Selecciona concepto, receptor e ingresa porcentaje.');
      return;
    }
    if (!CommissionMath.isAllowedPercentage(percentage)) {
      setState(() => _error = 'Usa porcentajes en incrementos de 0.5.');
      return;
    }
    if (_draft.length >= 20) {
      setState(() => _error = 'El máximo es 20 destinos.');
      return;
    }
    setState(() {
      _draft.add(CommissionLineModel(
        conceptId: concept.first.id,
        concept: concept.first.name,
        receiverId: receiver.first.id,
        receiverName: receiver.first.name,
        percentage: percentage,
      ));
      _error = null;
      _addReceiverId = null;
      _addConceptId = null;
      _addPercentage.text = '5';
    });
  }

  Future<void> _removeLine(int index) async {
    final line = _draft[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitar comisión'),
        content: Text(
            'Se eliminará ${line.concept} de la configuración. Se guardará el listado completo actualizado.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Quitar')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _draft.removeAt(index));
    }
  }

  Future<void> _save(
      UserRole role, String contractId, String contractFolio) async {
    final assigned = CommissionMath.sum(_draft.map((line) => line.percentage));
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Guardar configuración'),
        content: Text(
            'Se enviaría la lista completa de destinos del contrato $contractFolio. Total asignado: $assigned%; Empresa conservará el remanente.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Seguir editando')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Guardar')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      ref
          .read(comisionesControllerProvider(role).notifier)
          .saveConfigurationDemo(
            contractId: contractId,
            lines: List.unmodifiable(_draft),
            actor:
                ref.read(authControllerProvider).valueOrNull?.name ?? 'Usuario',
          );
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Configuración guardada; los snapshots previos no cambiaron.')));
      }
    } on StateError catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.message.toString();
        });
      }
    }
  }

  Widget _section(BuildContext context, String title, List<Widget> children) =>
      Container(
        padding: const EdgeInsets.all(AppTheme.space4),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.line),
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const Divider(height: AppTheme.space5),
          ...children,
        ]),
      );

  Widget _summary(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space1),
        child: Row(children: [Expanded(child: Text(label)), Text(value)]),
      );
}
