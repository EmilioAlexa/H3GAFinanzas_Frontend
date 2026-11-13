import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_notice.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../../auth/auth.dart';
import '../../../pagos/pagos.dart';

class ValidacionDetallePage extends ConsumerWidget {
  const ValidacionDetallePage({required this.paymentId, super.key});
  final String paymentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    if (session == null || session.role == UserRole.asesor) {
      return const AppStatePanel(
        icon: Icons.lock_outline,
        title: 'Acceso restringido',
        message: 'Solo administración puede revisar pagos.',
      );
    }
    final asyncState = ref.watch(pagosControllerProvider(session.role));
    final payment = ref
        .read(pagosControllerProvider(session.role).notifier)
        .findPayment(paymentId);
    if (asyncState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (payment == null) {
      return const AppStatePanel(
        icon: Icons.search_off_outlined,
        title: 'Pago no disponible',
        message: 'No se encontró el pago para esta sesión.',
      );
    }
    return _body(context, ref, session, payment);
  }

  Widget _body(BuildContext context, WidgetRef ref, AuthSessionModel session,
      PagoModel payment) {
    final initial = payment.estado == 'Pendiente de revisión financiera';
    final awaitingAdmin = payment.estado == 'Pendiente de autorización';
    final canFinancialReview =
        session.role == UserRole.administradorFinanciero && initial;
    final canAdminReview =
        session.role == UserRole.administrador && (initial || awaitingAdmin);
    final canReview = canFinancialReview || canAdminReview;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AppPageHeader(
          eyebrow: 'Pago ${payment.folio}',
          title: payment.numeroPago == null || payment.cantidadPagos == null
              ? payment.clienteNombre
              : payment.cantidadPagos == 1
                  ? 'Pago único · ${payment.numeroPago} de ${payment.cantidadPagos}'
                  : 'Mensualidad ${payment.numeroPago} de ${payment.cantidadPagos}',
          description:
              '${payment.clienteNombre} · ${payment.contratoFolio} · ${MoneyFormatter.formatDate(payment.fechaPago)}',
          actions: [
            OutlinedButton.icon(
              onPressed: () => context.go('/validacion'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Bandeja de validación'),
            ),
          ],
        ),
        _section(context, 'Estado actual', [
          AppBadge(
              label: payment.estado,
              tone: payment.estado == 'Validado'
                  ? AppBadgeTone.success
                  : payment.estado == 'Rechazado'
                      ? AppBadgeTone.danger
                      : AppBadgeTone.warning),
          const SizedBox(height: AppTheme.space3),
          Text(MoneyFormatter.format(payment.monto),
              style: Theme.of(context).textTheme.headlineMedium),
          Text('${payment.formaPago} · ${payment.servicioNombre}'),
        ]),
        const SizedBox(height: AppTheme.space4),
        _section(context, 'Información del pago', [
          _field('Cliente', payment.clienteNombre),
          _field('Contrato', payment.contratoFolio),
          _field('Servicio', payment.servicioNombre),
          _field('Número de pago', _paymentNumber(payment)),
          _field('Monto', '${MoneyFormatter.format(payment.monto)} MXN'),
          _field('Método', payment.formaPago),
          _field(
              'Referencia',
              payment.referencia.isEmpty
                  ? 'Sin referencia'
                  : payment.referencia),
          _field('Asesor', payment.asesorNombre),
          if (payment.observaciones.isNotEmpty)
            _field('Observaciones', payment.observaciones),
        ]),
        const SizedBox(height: AppTheme.space4),
        _section(
          context,
          'Evidencias',
          payment.evidencias.isEmpty
              ? [
                  const AppNotice(
                    type: AppNoticeType.warning,
                    text:
                        'Sin evidencia tipificada. El pago no puede validarse hasta tener evidencia compatible con su método.',
                  ),
                ]
              : payment.evidencias
                  .map((file) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.description_outlined),
                        title: Text(file.name),
                        subtitle:
                            Text('${file.mimeType} · ${_size(file.sizeBytes)}'),
                        trailing: const Tooltip(
                          message: 'Selecciona la evidencia para consultarla.',
                          child: Icon(Icons.visibility_outlined),
                        ),
                      ))
                  .toList(),
        ),
        const SizedBox(height: AppTheme.space4),
        _section(
          context,
          'Historial de estados',
          payment.historial
              .map((entry) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history),
                    title: Text(entry),
                    subtitle: const Text('Movimiento'),
                  ))
              .toList(),
        ),
        if (canReview) ...[
          const SizedBox(height: AppTheme.space4),
          _section(context, 'Decisión', [
            if (canFinancialReview) ...[
              FilledButton.icon(
                onPressed: () => _confirmAction(
                    context, ref, session, payment, 'enviar_a_autorizacion'),
                icon: const Icon(Icons.forward_to_inbox_outlined),
                label: const Text('Enviar a autorización'),
              ),
              const SizedBox(height: AppTheme.space2),
            ],
            if (canAdminReview)
              FilledButton.icon(
                onPressed: payment.hasEvidenceForApproval
                    ? () => _confirmAction(
                        context, ref, session, payment, 'validar')
                    : null,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Validar pago'),
              ),
            if (canAdminReview && !payment.hasEvidenceForApproval) ...[
              const SizedBox(height: AppTheme.space2),
              const AppNotice(
                type: AppNoticeType.warning,
                text:
                    'Se requiere una evidencia compatible con el método de pago.',
              ),
            ],
            const SizedBox(height: AppTheme.space2),
            OutlinedButton.icon(
              onPressed: () =>
                  _confirmAction(context, ref, session, payment, 'rechazar'),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Rechazar'),
            ),
          ]),
        ] else ...[
          const SizedBox(height: AppTheme.space4),
          AppNotice(
            text: payment.estado == 'Validado' || payment.estado == 'Rechazado'
                ? 'Este pago ya tiene una decisión final. La bandeja conserva su historial.'
                : session.role == UserRole.administradorFinanciero
                    ? 'La decisión final de un pago enviado a autorización corresponde a administración.'
                    : 'No hay acciones disponibles para el estado actual.',
          ),
        ],
      ]),
    );
  }

  Future<void> _confirmAction(BuildContext context, WidgetRef ref,
      AuthSessionModel session, PagoModel payment, String action) async {
    final commentController = TextEditingController();
    final labels = switch (action) {
      'rechazar' => ('Rechazar pago', 'Rechazar'),
      'enviar_a_autorizacion' => (
          'Enviar a autorización',
          'Enviar a autorización'
        ),
      _ => ('Validar pago', 'Confirmar validación'),
    };
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(labels.$1),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(switch (action) {
              'rechazar' =>
                'La decisión quedará registrada en el historial del pago.',
              'enviar_a_autorizacion' =>
                'El pago pasará a Pendiente de autorización.',
              _ => 'El pago quedará como Validado en la .',
            }),
            const SizedBox(height: AppTheme.space3),
            TextField(
              controller: commentController,
              maxLength: 1000,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Comentario (opcional)',
                hintText: 'Agrega contexto a la decisión',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(labels.$2),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      commentController.dispose();
      return;
    }
    try {
      ref
          .read(pagosControllerProvider(session.role).notifier)
          .changeReviewStateDemo(
            paymentId: payment.id,
            action: action,
            comment: commentController.text,
            actor: session.name,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estado actualizado en la .')),
        );
      }
    } on StateError catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      commentController.dispose();
    }
  }

  String _paymentNumber(PagoModel payment) {
    final number = payment.numeroPago;
    final total = payment.cantidadPagos;
    if (number == null || total == null) return 'Sin número en la respuesta';
    return total == 1
        ? 'Pago único · $number de $total'
        : 'Mensualidad $number de $total';
  }

  Widget _section(BuildContext context, String title, List<Widget> children) =>
      Container(
        padding: const EdgeInsets.all(AppTheme.space4),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.line),
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const Divider(height: AppTheme.space5),
            ...children,
          ],
        ),
      );

  Widget _field(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space1),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: AppTheme.muted)),
          const SizedBox(height: AppTheme.space1),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
      );

  String _size(int bytes) => bytes < 1024 * 1024
      ? '${(bytes / 1024).ceil()} KB'
      : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
