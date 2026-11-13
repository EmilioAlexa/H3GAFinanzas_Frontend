import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/env.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_notice.dart';
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
    return _content(context, ref, session, payment);
  }

  Widget _content(
    BuildContext context,
    WidgetRef ref,
    AuthSessionModel session,
    CommissionPaymentModel payment,
  ) {
    final isAdvisor = session.role == UserRole.asesor;
    final myCommission = payment.snapshot
        .where((item) => item.conceptId == 1)
        .fold(Decimal.zero, (sum, item) => sum + item.amount);
    final companyReference = payment.paymentAmount - myCommission;
    final companyRemainder = CommissionMath.remainderAmount(
      payment.paymentAmount,
      payment.snapshot.map((item) => item.amount),
    );
    final distributed =
        payment.snapshot.fold(Decimal.zero, (sum, item) => sum + item.amount);
    final status = payment.snapshot.every((item) => item.status == 'Dispersada')
        ? 'Dispersada'
        : 'Pendiente de dispersión';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AppPageHeader(
          eyebrow: isAdvisor
              ? 'Mi comisión · ${payment.paymentFolio}'
              : 'Dispersión · ${payment.paymentFolio}',
          title: MoneyFormatter.format(payment.paymentAmount),
          description:
              'Pago ${payment.paymentFolio} · Contrato ${payment.contractFolio}',
          actions: [
            OutlinedButton.icon(
              onPressed: () => context.go('/comisiones'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Volver a comisiones'),
            ),
          ],
        ),
        if (AppEnv.demoMode)
          const AppNotice(
            text:
                'Detalle local. Los snapshots ya generados no cambian al editar la configuración del contrato.',
          ),
        const SizedBox(height: AppTheme.space4),
        _section(context, 'Estado', [
          AppBadge(
            label: isAdvisor ? _myStatus(payment) : status,
            tone: status == 'Dispersada'
                ? AppBadgeTone.success
                : AppBadgeTone.warning,
          ),
          const SizedBox(height: AppTheme.space2),
          Text(isAdvisor
              ? (_myStatus(payment) == 'Dispersada'
                  ? 'Tu comisión ya fue dispersada.'
                  : 'Tu comisión queda pendiente de dispersión.')
              : 'La distribución del pago conserva los importes calculados al validarlo.'),
        ]),
        const SizedBox(height: AppTheme.space4),
        _section(context, 'Origen de los recursos', [
          _field('Cliente', payment.clientName),
          if (!isAdvisor) _field('Asesor', payment.advisorName),
          _field('Contrato', payment.contractFolio),
          _field('Servicio', payment.serviceName),
          _field('Pago origen', payment.paymentFolio),
          _field('Método de pago', payment.paymentMethod),
          _field(
              'Fecha del pago', MoneyFormatter.formatDate(payment.paymentDate)),
        ]),
        const SizedBox(height: AppTheme.space4),
        _section(
          context,
          isAdvisor ? 'Mi participación' : 'Conciliación',
          isAdvisor
              ? [
                  _amountRow('Monto del pago', payment.paymentAmount),
                  _amountRow('Mi comisión', myCommission),
                  _amountRow('Corresponde a la empresa (referencial)',
                      companyReference),
                  const AppNotice(
                    text:
                        'Importe referencial: monto del pago menos tu comisión. No se muestra el desglose de otros receptores.',
                  ),
                ]
              : [
                  _amountRow('Monto origen', payment.paymentAmount),
                  _field('Destinos de comisión', '${payment.snapshot.length}'),
                  _amountRow('Total asignado', distributed),
                  _amountRow('Empresa (remanente)', companyRemainder),
                  _amountRow(
                      'Total conciliado', distributed + companyRemainder),
                ],
        ),
        const SizedBox(height: AppTheme.space4),
        _section(
          context,
          isAdvisor ? 'Mi comisión' : 'Distribución aplicada al pago',
          isAdvisor
              ? _advisorRows(context, payment)
              : _distributionRows(context, ref, session, payment),
        ),
        if (!isAdvisor) ...[
          const SizedBox(height: AppTheme.space4),
          _section(context, 'Configuración vigente del contrato', [
            const Text(
                'Los cambios aplican a pagos futuros. Empresa se calcula como remanente.'),
            const Divider(height: AppTheme.space4),
            for (final line in payment.configuration)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(line.concept),
                subtitle: Text(line.receiverName),
                trailing: Text('${line.percentage}%'),
              ),
            const SizedBox(height: AppTheme.space2),
            Wrap(
                spacing: AppTheme.space2,
                runSpacing: AppTheme.space2,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.go(
                        '/comisiones/contratos/${payment.contractId}/configuracion'),
                    icon: const Icon(Icons.tune),
                    label: const Text('Configurar contrato'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/comisiones/receptores'),
                    icon: const Icon(Icons.people_alt_outlined),
                    label: const Text('Administrar receptores'),
                  ),
                ]),
            const Divider(height: AppTheme.space4),
            Text('Historial de configuración',
                style: Theme.of(context).textTheme.titleSmall),
            for (final entry in payment.configurationHistory)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history),
                title: Text(entry),
                subtitle: const Text('Evento'),
              ),
          ]),
        ],
      ]),
    );
  }

  List<Widget> _advisorRows(
    BuildContext context,
    CommissionPaymentModel payment,
  ) =>
      payment.snapshot
          .where((item) => item.conceptId == 1)
          .map((item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.concept),
                subtitle: Text(item.status),
                trailing: Text(MoneyFormatter.format(item.amount)),
              ))
          .toList();

  List<Widget> _distributionRows(
    BuildContext context,
    WidgetRef ref,
    AuthSessionModel session,
    CommissionPaymentModel payment,
  ) =>
      payment.snapshot
          .map((item) => _snapshotTile(context, ref, session, payment, item))
          .toList()
        ..add(ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Empresa · remanente'),
          subtitle: const Text('Se calcula automáticamente'),
          trailing: Text(MoneyFormatter.format(CommissionMath.remainderAmount(
            payment.paymentAmount,
            payment.snapshot.map((item) => item.amount),
          ))),
        ));

  Widget _snapshotTile(
    BuildContext context,
    WidgetRef ref,
    AuthSessionModel session,
    CommissionPaymentModel payment,
    CommissionSnapshotModel item,
  ) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space1),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(item.concept),
            subtitle: Text('${item.receiverName} · ${item.percentage}%'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(MoneyFormatter.format(item.amount),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(item.status, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (session.role != UserRole.asesor &&
              item.status == 'Pendiente de dispersión')
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () =>
                    _confirmDispersion(context, ref, session, payment, item),
                icon: const Icon(Icons.account_balance_outlined),
                label: const Text('Confirmar dispersión'),
              ),
            ),
          if (item.history.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                  left: AppTheme.space3, bottom: AppTheme.space2),
              child: Text(item.history.last,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          const Divider(height: AppTheme.space2),
        ]),
      );

  Future<void> _confirmDispersion(
    BuildContext context,
    WidgetRef ref,
    AuthSessionModel session,
    CommissionPaymentModel payment,
    CommissionSnapshotModel item,
  ) async {
    final comment = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar dispersión'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
              '¿Confirmas la transferencia de ${MoneyFormatter.format(item.amount)} a ${item.receiverName}?'),
          const SizedBox(height: AppTheme.space3),
          TextField(
            controller: comment,
            maxLength: 500,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Comentario opcional'),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
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
            const SnackBar(content: Text('Estado actualizado en la .')));
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

  Widget _field(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space1),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: AppTheme.muted)),
          const SizedBox(height: AppTheme.space1),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _amountRow(String label, Decimal amount) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space1),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Text(label)),
          const SizedBox(width: AppTheme.space2),
          Text(MoneyFormatter.format(amount),
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
      );

  String _myStatus(CommissionPaymentModel payment) {
    final mine = payment.snapshot.where((item) => item.conceptId == 1);
    if (mine.isEmpty) return 'Sin comisión asignada';
    return mine.every((item) => item.status == 'Dispersada')
        ? 'Dispersada'
        : 'Pendiente de dispersión';
  }
}
