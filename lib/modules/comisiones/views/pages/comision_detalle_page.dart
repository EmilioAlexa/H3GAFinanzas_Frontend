import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/env.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/export/document_export_service.dart';
import '../../../../core/network/finanzas_api.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../../auth/auth.dart';
import '../../controllers/comisiones_controller.dart';
import '../../models/commission_payment_model.dart';
import '../../models/commission_snapshot_model.dart';
import '../../utils/commission_math.dart';

class ComisionDetallePage extends ConsumerWidget {
  const ComisionDetallePage({required this.paymentId, super.key});

  final String paymentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    if (session == null) {
      return const AppStatePanel(
        icon: Icons.lock_outline,
        title: 'Inicia sesión para continuar',
        message: 'El detalle de comisión requiere sesión.',
      );
    }
    final state = ref.watch(comisionesControllerProvider(session.role));
    final payment = ref
        .read(comisionesControllerProvider(session.role).notifier)
        .findPayment(paymentId);
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (payment == null) {
      return const AppStatePanel(
        icon: Icons.search_off_outlined,
        title: 'Comisión no disponible',
        message:
            'No se encontró este pago o no está disponible para tu perfil.',
      );
    }
    return _page(context, ref, session, payment);
  }

  Widget _page(
    BuildContext context,
    WidgetRef ref,
    AuthSessionModel session,
    CommissionPaymentModel payment,
  ) {
    final advisor = session.role == UserRole.asesor;
    final dispersed = _isDispersed(payment);
    final totalAssigned =
        payment.snapshot.fold(Decimal.zero, (sum, item) => sum + item.amount);
    final companyAmount = !AppEnv.demoMode
        ? payment.snapshot
            .where((s) => s.concept == 'Empresa')
            .fold(Decimal.zero, (sum, s) => sum + s.amount)
        : CommissionMath.remainderAmount(
            payment.paymentAmount,
            payment.snapshot.map((item) => item.amount),
          );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBackButton(
            label: 'Comisiones',
            onPressed: () => context.go('/comisiones'),
          ),
          AppPageHeader(
            eyebrow: advisor
                ? 'Mi comisión · ${payment.paymentFolio}'
                : 'Dispersión ${payment.paymentFolio} · Cambaceo',
            title: MoneyFormatter.format(payment.paymentAmount),
            description:
                'Generada a partir del pago ${payment.paymentFolio} · Contrato ${payment.contractFolio}',
            actions: [
              OutlinedButton.icon(
                onPressed: () => _exportCommission(context, payment),
                icon: const Icon(Icons.download_outlined),
                label: const Text('Exportar detalle'),
              ),
            ],
          ),
          _statusCard(context, payment, advisor, dispersed),
          const SizedBox(height: AppTheme.space4),
          LayoutBuilder(
            builder: (context, constraints) {
              final origin = _originCard(context, payment, advisor);
              final reconciliation = advisor
                  ? _advisorSummary(context, payment)
                  : _reconciliationCard(
                      context, payment, totalAssigned, companyAmount);
              if (constraints.maxWidth < 900) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    origin,
                    const SizedBox(height: AppTheme.space4),
                    reconciliation,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: origin),
                  const SizedBox(width: AppTheme.space4),
                  Expanded(child: reconciliation),
                ],
              );
            },
          ),
          const SizedBox(height: AppTheme.space4),
          advisor
              ? _advisorCommissionCard(context, payment)
              : _distributionCard(context, ref, session, payment),
          if (!advisor) ...[
            const SizedBox(height: AppTheme.space4),
            _configurationCard(context, payment),
            const SizedBox(height: AppTheme.space4),
            _historyCard(context, payment),
          ],
        ],
      ),
    );
  }

  Widget _statusCard(
    BuildContext context,
    CommissionPaymentModel payment,
    bool advisor,
    bool dispersed,
  ) =>
      Container(
        padding: const EdgeInsets.all(AppTheme.space5),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.line),
          borderRadius: BorderRadius.circular(AppTheme.radius),
          boxShadow: AppTheme.elevation,
        ),
        child: Row(
          children: [
            _statusBadge(advisor
                ? _myStatus(payment)
                : dispersed
                    ? 'Dispersada'
                    : 'Pendiente de dispersión'),
            const SizedBox(width: AppTheme.space4),
            Expanded(
              child: Text(
                advisor
                    ? (dispersed
                        ? 'Tu comisión ya fue dispersada.'
                        : 'Tu comisión queda pendiente de dispersión.')
                    : dispersed
                        ? 'Dispersión conservada tal como se aplicó al validar el pago.'
                        : 'La distribución queda pendiente de dispersión.',
                style: const TextStyle(color: AppTheme.muted),
              ),
            ),
          ],
        ),
      );

  Widget _originCard(
    BuildContext context,
    CommissionPaymentModel payment,
    bool advisor,
  ) =>
      _panel(
        context,
        title: 'Origen de los recursos',
        child: Wrap(
          spacing: AppTheme.space8,
          runSpacing: AppTheme.space5,
          children: [
            if (!advisor) _field('Asesor', payment.advisorName),
            _field('Cliente', payment.clientName),
            _field('Contrato', payment.contractFolio),
            _field('Servicio', payment.serviceName),
            _field('Pago origen', payment.paymentFolio),
            _field('Método de pago', payment.paymentMethod),
            _field('Fecha de validación', _date(payment.paymentDate)),
          ],
        ),
      );

  Widget _reconciliationCard(
    BuildContext context,
    CommissionPaymentModel payment,
    Decimal assigned,
    Decimal companyAmount,
  ) =>
      _panel(
        context,
        title: 'Conciliación',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _amountRow('Monto origen', payment.paymentAmount),
            _amountRow('Destinos', Decimal.fromInt(payment.snapshot.length)),
            _amountRow('Total distribuido', assigned),
            const Divider(height: AppTheme.space5),
            _amountRow('Diferencia', payment.paymentAmount - assigned),
            Text(
              companyAmount == Decimal.zero
                  ? 'Empresa recibe el remanente · 100% asignado.'
                  : 'Empresa recibe el remanente · ${_money(companyAmount)}.',
              style: const TextStyle(color: AppTheme.muted),
            ),
          ],
        ),
      );

  Widget _advisorSummary(
    BuildContext context,
    CommissionPaymentModel payment,
  ) {
    final mine = payment.snapshot.where((item) => item.conceptId == 1);
    final amount = mine.fold(Decimal.zero, (sum, item) => sum + item.amount);
    return _panel(
      context,
      title: 'Mi participación',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _amountRow('Monto del pago', payment.paymentAmount),
          _amountRow('Mi comisión', amount),
          _field('Estado', _myStatus(payment)),
          const SizedBox(height: AppTheme.space2),
          const Text(
            'Solo se muestra la comisión correspondiente a tu perfil.',
            style: TextStyle(color: AppTheme.muted),
          ),
        ],
      ),
    );
  }

  Widget _advisorCommissionCard(
    BuildContext context,
    CommissionPaymentModel payment,
  ) {
    final mine = payment.snapshot.where((item) => item.conceptId == 1).toList();
    return _panel(
      context,
      title: 'Mi comisión',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: mine.isEmpty
            ? [const Text('No hay una comisión asignada para este pago.')]
            : [
                for (final item in mine)
                  _commissionRow(context, item, showActions: false),
              ],
      ),
    );
  }

  Widget _distributionCard(
    BuildContext context,
    WidgetRef ref,
    AuthSessionModel session,
    CommissionPaymentModel payment,
  ) =>
      _panel(
        context,
        title: 'Dispersión aplicada a este pago',
        trailing: _statusBadge(
            _isDispersed(payment) ? '100% conciliado' : 'Pendiente'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Porcentajes conservados al momento de validar el pago.',
                style: TextStyle(color: AppTheme.muted)),
            const SizedBox(height: AppTheme.space4),
            for (final item in payment.snapshot)
              _commissionRow(
                context,
                item,
                showActions:
                    item.status == 'Pendiente de dispersión',
                onDisperse: () =>
                    _confirmDispersion(context, ref, session, payment, item),
              ),
            if (AppEnv.demoMode)
              _commissionRow(
                context,
                _companySnapshot(payment),
                showActions: false,
              ),
            const Divider(height: AppTheme.space5),
            _amountRow('Total distribuido', payment.paymentAmount),
            if (!AppEnv.demoMode)
              FilledButton(
                onPressed: () => _administrativeConfirmation(context, ref, session, payment),
                child: const Text('Confirmar toda la dispersión'),
              ),
          ],
        ),
      );

  Widget _configurationCard(
    BuildContext context,
    CommissionPaymentModel payment,
  ) =>
      _panel(
        context,
        title:
            'Configuración de comisiones del contrato ${payment.contractFolio}',
        trailing: FilledButton.icon(
          onPressed: () => context
              .go('/comisiones/contratos/${payment.contractId}/configuracion'),
          icon: const Icon(Icons.tune),
          label: const Text('Configurar contrato'),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Los cambios aplican a pagos futuros si el estado es "Pendiente". Empresa recibe automáticamente el remanente.',
              style: TextStyle(color: AppTheme.muted),
            ),
            const SizedBox(height: AppTheme.space3),
            for (final line in payment.configuration)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.circle,
                    size: 10, color: _conceptColor(line.conceptId)),
                title: Text(line.concept),
                subtitle: Text(line.receiverName),
                trailing: Text('${line.percentage}%'),
              ),
          ],
        ),
      );

  Widget _historyCard(BuildContext context, CommissionPaymentModel payment) =>
      _panel(
        context,
        title: 'Historial del contrato',
        child: Column(
          children: [
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

  Widget _commissionRow(
    BuildContext context,
    CommissionSnapshotModel item, {
    required bool showActions,
    VoidCallback? onDisperse,
  }) {
    final isCompany = item.conceptId == 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.circle,
                  size: 11, color: _conceptColor(item.conceptId)),
              const SizedBox(width: AppTheme.space2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.concept,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(item.receiverName,
                        style: const TextStyle(color: AppTheme.muted)),
                  ],
                ),
              ),
              Text('${item.percentage}%',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(width: AppTheme.space5),
              SizedBox(
                width: 100,
                child: Text(_money(item.amount),
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              if (showActions && onDisperse != null)
                TextButton(
                  onPressed: onDisperse,
                  child: const Text('Confirmar dispersión'),
                )
              else if (isCompany)
                const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: AppTheme.space2),
          LinearProgressIndicator(
            value: (item.percentage.toDouble() / 100).clamp(0, 1),
            backgroundColor: AppTheme.accentSoft,
            valueColor:
                AlwaysStoppedAnimation<Color>(_conceptColor(item.conceptId)),
          ),
          if (!isCompany)
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.space1),
              child: Text(item.status,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
            ),
        ],
      ),
    );
  }

  CommissionSnapshotModel _companySnapshot(CommissionPaymentModel payment) {
    final assigned =
        payment.snapshot.fold(Decimal.zero, (sum, item) => sum + item.amount);
    return CommissionSnapshotModel(
      id: 'company',
      conceptId: 0,
      concept: 'Empresa',
      receiverName: 'Remanente · se calcula automáticamente',
      percentage: Decimal.fromInt(100) -
          payment.snapshot
              .fold(Decimal.zero, (sum, item) => sum + item.percentage),
      amount: payment.paymentAmount - assigned,
      status: 'Fija',
      history: const [],
    );
  }

  Future<void> _confirmDispersion(
    BuildContext context,
    WidgetRef ref,
    AuthSessionModel session,
    CommissionPaymentModel payment,
    CommissionSnapshotModel item,
  ) async {
    if (!AppEnv.demoMode) {
      await _administrativeConfirmation(context, ref, session, payment, item.id);
      return;
    }
    final comment = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: 'Confirmar dispersión',
        description: 'Confirma la transferencia al receptor seleccionado.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${_money(item.amount)} · ${item.receiverName}'),
            const SizedBox(height: AppTheme.space3),
            TextField(
              controller: comment,
              maxLength: 500,
              maxLines: 3,
              decoration:
                  const InputDecoration(labelText: 'Comentario opcional'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      comment.dispose();
      return;
    }
    try {
      ref
          .read(comisionesControllerProvider(session.role).notifier)
          .disperseDemo(
            paymentId: payment.id,
            commissionId: item.id,
            comment: comment.text,
            actor: session.name,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dispersión actualizada.')));
      }
    } on StateError catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message.toString())));
      }
    } finally {
      comment.dispose();
    }
  }

  Future<void> _administrativeConfirmation(BuildContext context, WidgetRef ref,
      AuthSessionModel session, CommissionPaymentModel payment, [String? id]) async {
    try {
      final api = ref.read(finanzasApiProvider);
      final preview = await api.detail('/finanzas/pagos/${payment.id}/distribucion/confirmacion');
      final rows = (preview['conceptos'] as List).map(apiMap).where((r) =>
        id != null ? r['id'] == id : r['estado'] != 'Dispersada').toList();
      if (!context.mounted) return;
      await showDialog<void>(context: context, barrierDismissible: false,
        builder: (_) => _AdministrativeDialog(paymentId: payment.id, rows: rows, general: id == null));
      await ref.read(comisionesControllerProvider(session.role).notifier).load();
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Widget _panel(
    BuildContext context, {
    required String title,
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
              children: [
                Expanded(
                  child: Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const Divider(height: AppTheme.space6),
            child,
          ],
        ),
      );

  Widget _field(String label, String value) => SizedBox(
        width: 235,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.muted)),
            const SizedBox(height: AppTheme.space1),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _amountRow(String label, Decimal value) => Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.space3),
        child: Row(
          children: [
            Expanded(
                child:
                    Text(label, style: const TextStyle(color: AppTheme.muted))),
            Text(_money(value),
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );

  AppBadge _statusBadge(String status) => AppBadge(
        label: status,
        tone: status == 'Dispersada' || status == '100% conciliado'
            ? AppBadgeTone.success
            : AppBadgeTone.warning,
      );

  bool _isDispersed(CommissionPaymentModel payment) =>
      payment.snapshot.isNotEmpty &&
      payment.snapshot.every((item) => item.status == 'Dispersada');

  String _myStatus(CommissionPaymentModel payment) {
    final mine = payment.snapshot.where((item) => item.conceptId == 1);
    if (mine.isEmpty) return 'Sin comisión asignada';
    return mine.every((item) => item.status == 'Dispersada')
        ? 'Dispersada'
        : 'Pendiente de dispersión';
  }

  Color _conceptColor(int conceptId) => switch (conceptId) {
        1 => AppTheme.primary,
        2 => AppTheme.secondaryDark,
        3 => AppTheme.infoBase,
        4 => AppTheme.gold,
        0 => AppTheme.muted,
        _ => AppTheme.muted,
      };

  String _money(Decimal value) => MoneyFormatter.format(value);

  String _date(DateTime value) => MoneyFormatter.formatDate(value);

  Future<void> _exportCommission(
    BuildContext context,
    CommissionPaymentModel payment,
  ) async {
    final rows = [
      for (final item in payment.snapshot)
        [
          item.concept,
          item.receiverName,
          '${item.percentage}%',
          _money(item.amount),
          item.status,
        ],
    ];
    try {
      await DocumentExportService.pdf(
        filename: 'comision-${payment.paymentFolio}.pdf',
        title: 'H3GA Finanzas · Dispersión ${payment.paymentFolio}',
        subtitle:
            '${payment.clientName} · Contrato ${payment.contractFolio} · ${_money(payment.paymentAmount)}',
        headers: const [
          'Destino',
          'Receptor',
          'Porcentaje',
          'Importe',
          'Estado'
        ],
        rows: rows,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Detalle exportado en PDF.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo exportar: $error')));
      }
    }
  }
}

class _AdministrativeDialog extends ConsumerStatefulWidget {
  const _AdministrativeDialog({required this.paymentId, required this.rows, required this.general});
  final String paymentId;
  final List<Map<String, dynamic>> rows;
  final bool general;
  @override
  ConsumerState<_AdministrativeDialog> createState() => _AdministrativeDialogState();
}

class _AdministrativeDialogState extends ConsumerState<_AdministrativeDialog> {
  bool busy = false;
  bool done = false;
  String? error;
  @override
  Widget build(BuildContext context) => AppDialog(
    title: widget.general ? 'Confirmar toda la dispersión' : 'Confirmar dispersión',
    actions: [
      TextButton(onPressed: busy ? null : () => Navigator.pop(context), child: const Text('Cerrar')),
      FilledButton(onPressed: busy || done || widget.rows.isEmpty || widget.rows.any((r) => r['bloqueo'] != null) ? null : () async {
        setState(() { busy = true; error = null; });
        try {
          await ref.read(finanzasApiProvider).dio.post<dynamic>('/finanzas/pagos/${widget.paymentId}/distribucion/confirmar',
            data: {'comision_ids': widget.rows.map((r) => r['id']).toList(), 'general': widget.general});
          if (mounted) setState(() => done = true);
        } catch (e) { if (mounted) setState(() => error = e.toString()); }
        finally { if (mounted) setState(() => busy = false); }
      }, child: const Text('Confirmar')),
    ],
    child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('Confirmación administrativa interna. No ejecuta una transferencia bancaria.'),
      if (widget.rows.isEmpty) const Text('No hay conceptos pendientes.'),
      for (final r in widget.rows) ListTile(title: Text('${r['concepto']} · ${r['receptor'] ?? 'Destino contable'}'),
        subtitle: Text('${r['porcentaje']}% · ${r['importe']}\n${r['bloqueo'] ?? 'Pendiente de confirmación'}')),
      if (done) const Text('Confirmación registrada.'),
      if (error != null) Text(error!),
    ])),
  );
}

