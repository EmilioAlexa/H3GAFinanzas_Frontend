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

  Widget _content(BuildContext context, PagoModel payment) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space6),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AppPageHeader(
              eyebrow: 'Detalle del movimiento',
              title: payment.folio,
              description:
                  '${payment.clienteNombre} · ${payment.contratoFolio}',
              actions: [
                OutlinedButton.icon(
                    onPressed: () => context.go('/pagos'),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Volver a pagos'))
              ]),
          const AppNotice(
              text:
                  'Vista de demostración. El historial y los archivos son muestras; las acciones de revisión corresponden a la etapa A7.'),
          const SizedBox(height: AppTheme.space4),
          _section(context, 'Resumen', [
            _item(
                'Estado',
                AppBadge(
                    label: payment.estado,
                    tone: payment.estado == 'Validado'
                        ? AppBadgeTone.success
                        : AppBadgeTone.warning)),
            _item(
                'Importe del pago',
                Text(MoneyFormatter.format(payment.monto),
                    style: Theme.of(context).textTheme.titleLarge)),
            _item('Fecha de pago',
                Text(MoneyFormatter.formatDate(payment.fechaPago))),
            _item('Forma de pago', Text(payment.formaPago)),
            _item(
                'Referencia',
                Text(payment.referencia.isEmpty
                    ? 'Sin referencia'
                    : payment.referencia)),
            _item('Contrato',
                Text('${payment.contratoFolio} · ${payment.servicioNombre}')),
            if (payment.folioRecibo != null)
              _item('Folio de recibo', Text(payment.folioRecibo!)),
            if (payment.recibidoPor != null)
              _item('Recibido por', Text(payment.recibidoPor!)),
            if (payment.observaciones.isNotEmpty)
              _item('Observaciones', Text(payment.observaciones)),
          ]),
          const SizedBox(height: AppTheme.space4),
          _section(
            context,
            'Evidencias',
            payment.evidencias.isEmpty
                ? [
                    const Text(
                        'Este movimiento no tiene evidencias de muestra.')
                  ]
                : payment.evidencias
                    .map(
                      (file) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.attach_file),
                        title: Text(file.name),
                        subtitle: Text(
                          '${file.mimeType} · ${_size(file.sizeBytes)} · muestra local',
                        ),
                        trailing: const Tooltip(
                          message:
                              'La descarga se habilitará al conectar la API y el almacenamiento.',
                          child: Icon(Icons.cloud_download_outlined),
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: AppTheme.space4),
          _section(
              context,
              'Historial',
              payment.historial.isEmpty
                  ? [const Text('Sin movimientos de historial.')]
                  : payment.historial
                      .map((item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.history),
                          title: Text(item),
                          subtitle: const Text('Evento de demostración')))
                      .toList()),
          const SizedBox(height: AppTheme.space4),
          const AppNotice(
              type: AppNoticeType.warning,
              text:
                  'El contrato no expone saldo pendiente en el detalle del pago; no se calcula ni se muestra un saldo estimado.'),
        ]),
      );

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
            ...children,
          ]));

  Widget _item(String label, Widget value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space1),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 150,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600))),
        Expanded(child: value),
      ]));

  String _size(int bytes) => bytes < 1024 * 1024
      ? '${(bytes / 1024).ceil()} KB'
      : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
