import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/responsive/window_size_class.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../../auth/auth.dart';
import '../../controllers/pagos_controller.dart';
import '../../models/pago_model.dart';

class PagoDetallePage extends ConsumerWidget {
  const PagoDetallePage({required this.paymentId, super.key});
  final String paymentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    if (session == null) {
      return const AppStatePanel(
          icon: Icons.lock_outline,
          title: 'Inicia sesión para continuar',
          message: 'El detalle requiere sesión activa.');
    }
    final state = ref.watch(pagosControllerProvider(session.role));
    final payment = ref
        .read(pagosControllerProvider(session.role).notifier)
        .findPayment(paymentId);
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (payment == null) {
      return const AppStatePanel(
          icon: Icons.search_off,
          title: 'Pago no encontrado',
          message: 'El registro puede no estar disponible para este perfil.');
    }
    return _content(context, payment);
  }

  Widget _content(BuildContext context, PagoModel payment) {
    final compact = Responsive.of(context) == WindowSizeClass.compacto;
    final information = _section(context, 'Informaci?n del pago', [
      LayoutBuilder(
          builder: (context, constraints) =>
              Wrap(spacing: 24, runSpacing: 20, children: [
                for (final entry in <String, String>{
                  'Cliente': payment.clienteNombre,
                  'Contrato': payment.contratoFolio,
                  'Servicio': payment.servicioNombre,
                  'N?mero de pago': payment.numeroPago == null
                      ? '?'
                      : '${payment.numeroPago} de ${payment.cantidadPagos ?? '?'}',
                  'Importe del pago': MoneyFormatter.format(payment.monto),
                  'Fecha de pago': MoneyFormatter.formatDate(payment.fechaPago),
                  'M?todo': payment.formaPago,
                  'Referencia':
                      payment.referencia.isEmpty ? '?' : payment.referencia,
                  'Asesor': payment.asesorNombre,
                }.entries)
                  SizedBox(
                      width: (constraints.maxWidth - 24) / 2,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.key,
                                style: const TextStyle(
                                    color: AppTheme.muted, fontSize: 11)),
                            const SizedBox(height: 6),
                            Text(entry.value,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                          ])),
              ])),
      if (payment.observaciones.isNotEmpty) ...[
        const SizedBox(height: 24),
        Text('Observaciones', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        Text(payment.observaciones),
      ],
    ]);
    final evidence = _section(context, 'Evidencias', [
      if (payment.evidencias.isEmpty) const Text('Sin evidencias adjuntas.'),
      for (final file in payment.evidencias)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.description_outlined,
              color: AppTheme.secondaryDark),
          title: Text(file.name, style: const TextStyle(fontSize: 12)),
          subtitle: Text('${file.mimeType} ? ${_size(file.sizeBytes)}',
              style: const TextStyle(fontSize: 10)),
        ),
    ]);
    return SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                    onPressed: () => context.go('/pagos'),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Pagos'))),
            AppPageHeader(
                eyebrow: 'Pago ${payment.folio}',
                title: payment.numeroPago == null
                    ? payment.folio
                    : 'Mensualidad ${payment.numeroPago} de ${payment.cantidadPagos ?? '?'}',
                description:
                    'Registrado el ${MoneyFormatter.formatDate(payment.fechaPago)}'),
            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: AppTheme.surface,
                    border: Border.all(color: AppTheme.line),
                    borderRadius: BorderRadius.circular(AppTheme.radius)),
                child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 20,
                    runSpacing: 12,
                    children: [
                      AppBadge(
                          label: payment.estado,
                          tone: payment.estado == 'Validado'
                              ? AppBadgeTone.success
                              : AppBadgeTone.warning),
                      Text(MoneyFormatter.format(payment.monto),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ])),
            const SizedBox(height: 16),
            if (compact) ...[
              information,
              const SizedBox(height: 16),
              evidence
            ] else
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 2, child: information),
                const SizedBox(width: 16),
                Expanded(child: evidence)
              ]),
            const SizedBox(height: 16),
            _section(context, 'Historial de estados', [
              if (payment.historial.isEmpty)
                const Text('Sin movimientos de historial.'),
              for (final entry in payment.historial)
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.check_circle_outline,
                        color: AppTheme.secondaryDark),
                    title: Text(entry, style: const TextStyle(fontSize: 12))),
            ]),
          ],
        ));
  }

  Widget _section(BuildContext context, String title, List<Widget> children) =>
      Container(
          padding: const EdgeInsets.all(AppTheme.space4),
          decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border.all(color: AppTheme.line),
              boxShadow: AppTheme.elevation,
              borderRadius: BorderRadius.circular(AppTheme.radius)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const Divider(height: AppTheme.space5),
            ...children,
          ]));

  String _size(int bytes) => bytes < 1024 * 1024
      ? '${(bytes / 1024).ceil()} KB'
      : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
