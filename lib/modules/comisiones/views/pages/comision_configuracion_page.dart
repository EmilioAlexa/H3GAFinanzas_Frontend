import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/env.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../../auth/auth.dart';
import '../../controllers/comisiones_controller.dart';
import '../../models/commission_concept_model.dart';
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
  List<CommissionConceptModel> get _concepts => ref
      .read(comisionesControllerProvider(
              ref.read(authControllerProvider).valueOrNull!.role)
          .notifier)
      .concepts;
  String? _initializedContract;
  List<CommissionLineModel> _draft = [];
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    if (session == null || session.role == UserRole.asesor) {
      return const AppStatePanel(
        icon: Icons.lock_outline,
        title: 'Acceso restringido',
        message: 'Solo administración puede configurar la dispersión.',
      );
    }
    if (!AppEnv.demoMode) {
      ref.watch(comisionesControllerProvider(session.role));
      return ref.watch(contractualCommissionProvider(widget.contractId)).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => AppStatePanel(
              icon: Icons.cloud_off,
              title: 'No se pudo cargar',
              message: e.toString(),
              action: TextButton(
                  onPressed: () => ref.invalidate(
                      contractualCommissionProvider(widget.contractId)),
                  child: const Text('Reintentar'))),
          data: (payment) {
            if (_initializedContract != payment.contractId) {
              _initializedContract = payment.contractId;
              _draft = List.of(payment.configuration);
            }
            return _body(context, session, payment);
          });
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
            message: 'No hay una configuración disponible para este contrato.',
          );
        }
        if (_initializedContract != payment.contractId) {
          _initializedContract = payment.contractId;
          _draft = List.of(payment.configuration);
        }
        return _body(context, session, payment);
      },
    );
  }

  Widget _body(
    BuildContext context,
    AuthSessionModel session,
    CommissionPaymentModel payment,
  ) {
    final assigned = CommissionMath.sum(_draft.map((line) => line.percentage));
    final companyPercentage = Decimal.fromInt(100) - assigned;
    final companyAmount = CommissionMath.remainderAmount(
      payment.paymentAmount,
      _draft.map((line) =>
          CommissionMath.amountFor(payment.paymentAmount, line.percentage)),
    );
    final invalid = assigned > Decimal.fromInt(100) ||
        _hasDuplicateConcepts ||
        _draft.any(
          (line) => !CommissionMath.isAllowedPercentage(line.percentage),
        ) ||
        (payment.serviceName == 'APD' &&
            _draft.any((line) => line.conceptId == 4));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBackButton(
            label: 'Detalle de comisiones',
            onPressed: () => context.go('/contratos/${payment.contractId}'),
          ),
          AppPageHeader(
            eyebrow: 'Configuración del contrato',
            title: 'Comisiones · ${payment.contractFolio}',
            description:
                'Los cambios aplican a pagos futuros si el estado es "Pendiente". Empresa recibe automáticamente el remanente.',
          ),
          _contractSummary(
              context, payment, assigned, companyPercentage, companyAmount),
          const SizedBox(height: AppTheme.space4),
          _configurationCard(context, session, payment),
          if (invalid) ...[
            const SizedBox(height: AppTheme.space3),
            _errorBanner(payment, assigned),
          ],
          const SizedBox(height: AppTheme.space4),
          _historyCard(context, payment),
        ],
      ),
    );
  }

  Widget _contractSummary(
    BuildContext context,
    CommissionPaymentModel payment,
    Decimal assigned,
    Decimal companyPercentage,
    Decimal companyAmount,
  ) =>
      Container(
        padding: const EdgeInsets.all(AppTheme.space5),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.line),
          borderRadius: BorderRadius.circular(AppTheme.radius),
          boxShadow: AppTheme.elevation,
        ),
        child: Wrap(
          spacing: AppTheme.space8,
          runSpacing: AppTheme.space4,
          children: [
            _summaryMetric('Cliente', payment.clientName),
            _summaryMetric('Servicio', payment.serviceName),
            _summaryMetric('Asesor', payment.advisorName),
            _summaryMetric(
                'Pago de referencia',
                payment.paymentFolio.isEmpty
                    ? 'Pendiente de cálculo'
                    : payment.paymentFolio),
            _summaryMetric(
                'Monto origen',
                payment.paymentAmount == Decimal.zero
                    ? 'Pendiente de cálculo'
                    : _money(payment.paymentAmount)),
            _summaryMetric('Asignado', '$assigned%'),
            _summaryMetric('Empresa · remanente',
                '$companyPercentage% · ${_money(companyAmount)}'),
          ],
        ),
      );

  Widget _configurationCard(
    BuildContext context,
    AuthSessionModel session,
    CommissionPaymentModel payment,
  ) =>
      Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.line),
          borderRadius: BorderRadius.circular(AppTheme.radius),
          boxShadow: AppTheme.elevation,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTheme.space5),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configuración de comisiones del contrato ${payment.contractFolio}',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: AppTheme.space1),
                        const Text(
                          'Agrega o edita destinos. Empresa no se captura: es el remanente automático.',
                          style: TextStyle(color: AppTheme.muted),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _openEditor(context, payment),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar comisión'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            LayoutBuilder(
              builder: (context, constraints) {
                final table = _commissionTable(context, session, payment);
                if (constraints.maxWidth >= 760) return table;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(width: 760, child: table),
                );
              },
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppTheme.space5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total distribuido ${_money(payment.paymentAmount)}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  FilledButton(
                    onPressed: _saving || !_canSave(payment)
                        ? null
                        : () => _save(session, payment),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Guardar configuración del contrato'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _commissionTable(
    BuildContext context,
    AuthSessionModel session,
    CommissionPaymentModel payment,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _tableHeader(payment),
          for (var index = 0; index < _draft.length; index++)
            _lineRow(context, session, payment, index),
          _companyRow(payment),
        ],
      );

  Widget _tableHeader(CommissionPaymentModel payment) => Container(
        padding: const EdgeInsets.fromLTRB(
            AppTheme.space5, AppTheme.space3, AppTheme.space5, AppTheme.space3),
        color: AppTheme.canvas,
        child: Row(
          children: [
            const Expanded(flex: 2, child: Text('DESTINO')),
            const Expanded(flex: 3, child: Text('RECEPTOR')),
            const SizedBox(width: 118, child: Text('PORCENTAJE')),
            SizedBox(
                width: 125,
                child: Text('IMPORTE · ${_money(payment.paymentAmount)}')),
            const SizedBox(width: 116),
          ],
        ),
      );

  Widget _lineRow(
    BuildContext context,
    AuthSessionModel session,
    CommissionPaymentModel payment,
    int index,
  ) {
    final line = _draft[index];
    final amount =
        CommissionMath.amountFor(payment.paymentAmount, line.percentage);
    final locked = line.payrollIncluded && line.conceptId != 4;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space5, vertical: AppTheme.space4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.line)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(Icons.circle,
                    size: 11, color: _conceptColor(line.conceptId)),
                const SizedBox(width: AppTheme.space2),
                Expanded(
                    child: Text(line.concept,
                        style: const TextStyle(fontWeight: FontWeight.w700))),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
                '${line.receiverName}${line.payrollName == null ? '' : ' · ${line.payrollName}'}'),
          ),
          SizedBox(
            width: 88,
            child: Text('${line.percentage}%',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          SizedBox(width: 125, child: Text(_money(amount))),
          SizedBox(
            width: 116,
            child: locked
                ? Tooltip(
                    message:
                        'Incluida en prenómina ${line.payrollName ?? 'activa'}. No muestran Editar ni Quitar. IMSS sigue editable.',
                    child:
                        const Icon(Icons.lock_outline, color: AppTheme.muted),
                  )
                : Wrap(
                    spacing: AppTheme.space1,
                    children: [
                      TextButton(
                        onPressed: () =>
                            _openEditor(context, payment, index: index),
                        child: const Text('Editar'),
                      ),
                      TextButton(
                        onPressed: () => _removeLine(context, payment, index),
                        style: TextButton.styleFrom(
                            foregroundColor: AppTheme.danger),
                        child: const Text('Quitar'),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _companyRow(CommissionPaymentModel payment) {
    final assignedAmounts = _draft.map((line) =>
        CommissionMath.amountFor(payment.paymentAmount, line.percentage));
    final amount =
        CommissionMath.remainderAmount(payment.paymentAmount, assignedAmounts);
    final percentage = Decimal.fromInt(100) -
        CommissionMath.sum(_draft.map((line) => line.percentage));
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space5, vertical: AppTheme.space4),
      color: AppTheme.canvas,
      child: Row(
        children: [
          const Expanded(
              flex: 2,
              child: Text('Empresa',
                  style: TextStyle(fontWeight: FontWeight.w700))),
          const Expanded(
              flex: 3,
              child: Text('Remanente · se calcula automáticamente',
                  style: TextStyle(color: AppTheme.muted))),
          SizedBox(width: 88, child: Text('$percentage%')),
          SizedBox(width: 125, child: Text(_money(amount))),
          const SizedBox(
              width: 116,
              child: Tooltip(
                  message: 'Empresa siempre recibe el remanente.',
                  child: Icon(Icons.lock_outline, color: AppTheme.muted))),
        ],
      ),
    );
  }

  Widget _historyCard(BuildContext context, CommissionPaymentModel payment) =>
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
            Text('Historial del contrato',
                style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: AppTheme.space6),
            for (final entry in payment.configurationHistory)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history),
                title: Text(entry),
                subtitle: const Text('Evento de configuración'),
              ),
          ],
        ),
      );

  Widget _errorBanner(CommissionPaymentModel payment, Decimal assigned) {
    final excess = assigned - Decimal.fromInt(100);
    final text = assigned > Decimal.fromInt(100)
        ? 'La suma excede 100% por $excess%; Empresa no puede ser negativa'
        : _hasDuplicateConcepts
            ? 'Cada destino solo puede existir una vez por contrato.'
            : payment.serviceName == 'APD' &&
                    _draft.any((line) => line.conceptId == 4)
                ? 'IMSS solo aplica a Modalidad 10, Modalidad 40 y M40 Retroactiva.'
                : 'Usa porcentajes en incrementos de 0.5.';
    return Container(
      padding: const EdgeInsets.all(AppTheme.space3),
      decoration: BoxDecoration(
        color: AppTheme.dangerBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusField),
        border: Border.all(color: AppTheme.danger.withValues(alpha: .3)),
      ),
      child: Text(text, style: const TextStyle(color: AppTheme.danger)),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    CommissionPaymentModel payment, {
    int? index,
  }) async {
    final byConcept = <int, List<DispersionReceiverModel>>{
      for (final concept in _concepts)
        concept.id: ref
            .read(comisionesControllerProvider(
                    ref.read(authControllerProvider).valueOrNull!.role)
                .notifier)
            .activeReceiversFor(concept.id),
    };
    final result = await showGeneralDialog<_CommissionEditorResult>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar panel',
      barrierColor: AppTheme.primary.withValues(alpha: .28),
      pageBuilder: (context, animation, secondaryAnimation) => Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: AppTheme.surface,
          child: SizedBox(
            width: (MediaQuery.sizeOf(context).width * .9).clamp(360.0, 460.0),
            height: double.infinity,
            child: _CommissionEditorPanel(
              concepts: _concepts,
              payment: payment,
              currentLines: _draft,
              initialIndex: index,
              receiversByConcept: byConcept,
            ),
          ),
        ),
      ),
    );
    if (result == null) return;
    if (!mounted) return;
    final next = List<CommissionLineModel>.of(_draft);
    final replacing = result.index != null && result.index! < next.length;
    if (replacing) {
      final confirmed = await _confirmMutation(
        title: 'Confirmar cambio de comisión',
        before: next,
        after: [...next]..[result.index!] = result.line,
        payment: payment,
      );
      if (!confirmed || !mounted) return;
      next[result.index!] = result.line;
    } else {
      next.add(result.line);
    }
    setState(() => _draft = next);
  }

  Future<void> _removeLine(
    BuildContext context,
    CommissionPaymentModel payment,
    int index,
  ) async {
    final next = List<CommissionLineModel>.of(_draft)..removeAt(index);
    final confirmed = await _confirmMutation(
      title: 'Confirmar retiro de comisión',
      before: _draft,
      after: next,
      payment: payment,
      destructive: true,
    );
    if (confirmed && mounted) setState(() => _draft = next);
  }

  Future<bool> _confirmMutation({
    required String title,
    required List<CommissionLineModel> before,
    required List<CommissionLineModel> after,
    required CommissionPaymentModel payment,
    bool destructive = false,
  }) async {
    final dispersed = payment.snapshot.isNotEmpty &&
        payment.snapshot.every((item) => item.status == 'Dispersada');
    return await showDialog<bool>(
          context: this.context,
          builder: (context) => AppDialog(
            title: title,
            description: 'Revisa el impacto antes de confirmar.',
            maxWidth: 720,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (dispersed)
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space3),
                    color: AppTheme.warningBackground,
                    child: const Text(
                      'Este pago ya fue dispersado; el cambio solo afectará pagos futuros del contrato.',
                      style: TextStyle(color: AppTheme.warning),
                    ),
                  ),
                if (dispersed) const SizedBox(height: AppTheme.space3),
                _comparisonTable(before, after, payment.paymentAmount),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: destructive
                    ? FilledButton.styleFrom(backgroundColor: AppTheme.danger)
                    : null,
                child: Text(destructive ? 'Quitar' : 'Confirmar cambio'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _comparisonTable(
    List<CommissionLineModel> before,
    List<CommissionLineModel> after,
    Decimal amount,
  ) {
    final names = <String>{
      ...before.map((line) => line.concept),
      ...after.map((line) => line.concept),
      'Empresa',
    }.toList();
    Decimal percentageFor(List<CommissionLineModel> lines, String name) {
      if (name == 'Empresa') {
        return Decimal.fromInt(100) -
            CommissionMath.sum(lines.map((line) => line.percentage));
      }
      return lines
          .where((line) => line.concept == name)
          .fold(Decimal.zero, (sum, line) => sum + line.percentage);
    }

    return Column(
      children: [
        const Row(
          children: [
            Expanded(child: Text('Destino')),
            SizedBox(width: 115, child: Text('Antes')),
            SizedBox(width: 115, child: Text('Después')),
          ],
        ),
        const Divider(),
        for (final name in names)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.space1),
            child: Row(
              children: [
                Expanded(child: Text(name)),
                SizedBox(
                  width: 115,
                  child: Text(
                      '${percentageFor(before, name)}% · ${_money(CommissionMath.amountFor(amount, percentageFor(before, name)))}'),
                ),
                SizedBox(
                  width: 115,
                  child: Text(
                      '${percentageFor(after, name)}% · ${_money(CommissionMath.amountFor(amount, percentageFor(after, name)))}'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _save(
      AuthSessionModel session, CommissionPaymentModel payment) async {
    if (!_canSave(payment)) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(comisionesControllerProvider(session.role).notifier)
          .saveConfigurationDemo(
            contractId: payment.contractId,
            lines: List.unmodifiable(_draft),
            actor: session.name,
          );
      if (mounted) {
        ref.invalidate(contractualCommissionProvider(widget.contractId));
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Configuración actualizada para el contrato ${payment.contractFolio} · aplica a pagos futuros'),
        ));
      }
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  bool get _hasDuplicateConcepts =>
      _draft.map((line) => line.conceptId).toSet().length != _draft.length;

  bool _canSave(CommissionPaymentModel payment) {
    final assigned = CommissionMath.sum(_draft.map((line) => line.percentage));
    return !_hasDuplicateConcepts &&
        assigned <= Decimal.fromInt(100) &&
        !(_draft.any(
            (line) => line.conceptId == 4 && payment.serviceName == 'APD')) &&
        _draft.every(
            (line) => CommissionMath.isAllowedPercentage(line.percentage));
  }

  Widget _summaryMetric(String label, String value) => SizedBox(
        width: 195,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
            const SizedBox(height: AppTheme.space1),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Color _conceptColor(int conceptId) => switch (conceptId) {
        1 => AppTheme.primary,
        2 => AppTheme.secondaryDark,
        3 => AppTheme.infoBase,
        4 => AppTheme.gold,
        _ => AppTheme.muted,
      };

  String _money(Decimal value) =>
      AppEnv.demoMode ? MoneyFormatter.format(value) : 'Pendiente de cálculo';
}

class _CommissionEditorPanel extends StatefulWidget {
  const _CommissionEditorPanel({
    required this.payment,
    required this.concepts,
    required this.currentLines,
    required this.initialIndex,
    required this.receiversByConcept,
  });

  final List<CommissionConceptModel> concepts;
  final CommissionPaymentModel payment;
  final List<CommissionLineModel> currentLines;
  final int? initialIndex;
  final Map<int, List<DispersionReceiverModel>> receiversByConcept;

  @override
  State<_CommissionEditorPanel> createState() => _CommissionEditorPanelState();
}

class _CommissionEditorPanelState extends State<_CommissionEditorPanel> {
  int? _conceptId;
  String? _receiverId;
  int? _editingIndex;
  late final TextEditingController _percentage;
  String? _error;

  @override
  void initState() {
    super.initState();
    _editingIndex = widget.initialIndex;
    final initial = widget.initialIndex == null
        ? null
        : widget.currentLines[widget.initialIndex!];
    _conceptId = initial?.conceptId;
    _receiverId = initial?.receiverId;
    _percentage =
        TextEditingController(text: initial?.percentage.toString() ?? '');
  }

  @override
  void dispose() {
    _percentage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final concept = _concept;
    final candidate = _candidate;
    final next = _nextLines(candidate);
    final assigned = CommissionMath.sum(next.map((line) => line.percentage));
    final excess = assigned - Decimal.fromInt(100);
    final invalid = candidate == null ||
        _locked ||
        !CommissionMath.isAllowedPercentage(candidate.percentage) ||
        assigned > Decimal.fromInt(100);
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppTheme.space5, AppTheme.space5,
                AppTheme.space3, AppTheme.space4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CONTRATO ${widget.payment.contractFolio}',
                          style: const TextStyle(
                              color: AppTheme.secondaryDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1)),
                      const SizedBox(height: AppTheme.space2),
                      Text(
                        _editingIndex == null || concept == null
                            ? 'Agregar comisión'
                            : 'Editar comisión · ${concept.name}',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.space5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Destino',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppTheme.space2),
                  _destinationGrid(),
                  const SizedBox(height: AppTheme.space4),
                  if (concept != null) ...[
                    const Text('Receptor',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: AppTheme.space2),
                    DropdownButtonFormField<String>(
                      initialValue: _receiverId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Receptor'),
                      items: _receivers
                          .map((item) => DropdownMenuItem(
                                value: item.id,
                                child: Text(item.role == null
                                    ? item.name
                                    : '${item.name} · ${item.role}'),
                              ))
                          .toList(),
                      onChanged: _locked
                          ? null
                          : (value) => setState(() => _receiverId = value),
                    ),
                    const SizedBox(height: AppTheme.space3),
                    TextField(
                      controller: _percentage,
                      enabled: !_locked,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'Porcentaje', suffixText: '%'),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Row(
                      children: [
                        Expanded(
                            child: _previewMetric(
                                'Importe estimado',
                                candidate == null
                                    ? '—'
                                    : _money(CommissionMath.amountFor(
                                        widget.payment.paymentAmount,
                                        candidate.percentage)))),
                        const SizedBox(width: AppTheme.space3),
                        Expanded(
                            child: _previewMetric('Empresa (remanente)',
                                '${Decimal.fromInt(100) - assigned}%')),
                      ],
                    ),
                    if (_error != null ||
                        assigned > Decimal.fromInt(100) ||
                        (candidate != null &&
                            !CommissionMath.isAllowedPercentage(
                                candidate.percentage))) ...[
                      const SizedBox(height: AppTheme.space3),
                      Text(
                        _error ??
                            (assigned > Decimal.fromInt(100)
                                ? 'La suma excede 100% por $excess%; Empresa no puede ser negativa'
                                : 'Usa porcentajes en incrementos de 0.5.'),
                        style: const TextStyle(color: AppTheme.danger),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppTheme.space4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar')),
                const SizedBox(width: AppTheme.space2),
                FilledButton(
                  onPressed: invalid ? null : _save,
                  child: Text(_editingIndex == null
                      ? 'Agregar comisión'
                      : 'Guardar cambios'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _destinationGrid() => Wrap(
        spacing: AppTheme.space2,
        runSpacing: AppTheme.space2,
        children: [
          for (final concept in widget.concepts) _destinationTile(concept),
        ],
      );

  Widget _destinationTile(CommissionConceptModel concept) {
    final existingIndex =
        widget.currentLines.indexWhere((line) => line.conceptId == concept.id);
    final disabled = concept.name == 'Referidor' ||
        concept.name == 'Empresa' ||
        concept.name == 'IMSS' && widget.payment.serviceName == 'APD';
    final selected = _conceptId == concept.id;
    final child = InkWell(
      onTap: disabled || _locked ? null : () => _selectConcept(concept.id),
      borderRadius: BorderRadius.circular(AppTheme.radiusField),
      child: Container(
        width: 116,
        padding: const EdgeInsets.all(AppTheme.space2),
        decoration: BoxDecoration(
          color: disabled ? AppTheme.surfaceSecondary : AppTheme.surface,
          border: Border.all(
            color: selected ? AppTheme.secondaryDark : AppTheme.line,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusField),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.circle,
                    size: 9,
                    color: disabled ? AppTheme.lineStrong : _color(concept.id)),
                const SizedBox(width: AppTheme.space1),
                Expanded(
                    child: Text(concept.name, overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: AppTheme.space1),
            Text(
                disabled
                    ? 'No aplica'
                    : existingIndex >= 0
                        ? 'Existente'
                        : 'Nuevo',
                style: const TextStyle(color: AppTheme.muted, fontSize: 10)),
          ],
        ),
      ),
    );
    return disabled
        ? Tooltip(
            message:
                'IMSS solo aplica a Modalidad 10, Modalidad 40 y M40 Retroactiva',
            child: child,
          )
        : child;
  }

  void _selectConcept(int conceptId) {
    final existingIndex =
        widget.currentLines.indexWhere((line) => line.conceptId == conceptId);
    final existing =
        existingIndex < 0 ? null : widget.currentLines[existingIndex];
    setState(() {
      _conceptId = conceptId;
      _editingIndex = existingIndex < 0 ? widget.initialIndex : existingIndex;
      _receiverId = existing?.receiverId ?? _receivers.firstOrNull?.id;
      _percentage.text = existing?.percentage.toString() ?? '';
      _error = null;
    });
  }

  CommissionConceptModel? get _concept => _conceptId == null
      ? null
      : widget.concepts.where((item) => item.id == _conceptId).firstOrNull;

  List<DispersionReceiverModel> get _receivers => _conceptId == null
      ? const []
      : widget.receiversByConcept[_conceptId!] ?? const [];

  bool get _locked {
    final index = _editingIndex;
    return index != null &&
        index < widget.currentLines.length &&
        widget.currentLines[index].payrollIncluded &&
        widget.currentLines[index].conceptId != 4;
  }

  CommissionLineModel? get _candidate {
    final concept = _concept;
    final receiver =
        _receivers.where((item) => item.id == _receiverId).firstOrNull;
    final percentage = Decimal.tryParse(_percentage.text.trim());
    if (concept == null ||
        receiver == null && concept.name != 'IMSS' ||
        percentage == null) {
      return null;
    }
    return CommissionLineModel(
      conceptId: concept.id,
      concept: concept.name,
      receiverId: receiver?.id ?? '',
      receiverName: receiver?.name ?? '',
      percentage: percentage,
      payrollIncluded:
          _editingIndex != null && _editingIndex! < widget.currentLines.length
              ? widget.currentLines[_editingIndex!].payrollIncluded
              : false,
      payrollName:
          _editingIndex != null && _editingIndex! < widget.currentLines.length
              ? widget.currentLines[_editingIndex!].payrollName
              : null,
    );
  }

  List<CommissionLineModel> _nextLines(CommissionLineModel? candidate) {
    final next = List<CommissionLineModel>.of(widget.currentLines);
    if (candidate == null) return next;
    if (_editingIndex != null && _editingIndex! < next.length) {
      next[_editingIndex!] = candidate;
    } else {
      next.add(candidate);
    }
    return next;
  }

  Widget _previewMetric(String label, String value) => Container(
        padding: const EdgeInsets.all(AppTheme.space3),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.line),
          borderRadius: BorderRadius.circular(AppTheme.radiusField),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
            const SizedBox(height: AppTheme.space1),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );

  String _money(Decimal value) =>
      AppEnv.demoMode ? MoneyFormatter.format(value) : 'Pendiente de cálculo';

  Color _color(int id) => switch (id) {
        1 => AppTheme.primary,
        2 => AppTheme.secondaryDark,
        3 => AppTheme.infoBase,
        4 => AppTheme.gold,
        _ => AppTheme.muted,
      };

  void _save() {
    if (_locked) {
      setState(() => _error =
          'Incluida en prenómina. No muestran Editar ni Quitar. IMSS sigue editable.');
      return;
    }
    final candidate = _candidate;
    if (candidate == null) {
      setState(
          () => _error = 'Selecciona destino, receptor e ingresa porcentaje.');
      return;
    }
    final next = _nextLines(candidate);
    final assigned = CommissionMath.sum(next.map((line) => line.percentage));
    if (assigned > Decimal.fromInt(100)) {
      setState(() => _error =
          'La suma excede 100% por ${assigned - Decimal.fromInt(100)}%; Empresa no puede ser negativa');
      return;
    }
    if (!CommissionMath.isAllowedPercentage(candidate.percentage)) {
      setState(() => _error = 'Usa porcentajes en incrementos de 0.5.');
      return;
    }
    Navigator.pop(
      context,
      _CommissionEditorResult(index: _editingIndex, line: candidate),
    );
  }
}

class _CommissionEditorResult {
  const _CommissionEditorResult({required this.index, required this.line});

  final int? index;
  final CommissionLineModel line;
}
