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
        message: 'El detalle requiere una sesión activa.',
      );
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
        message: 'El registro puede no estar disponible para este perfil.',
      );
    }
    return _content(context, session, payment);
  }

  Widget _content(
      BuildContext context, AuthSessionModel session, PagoModel payment) {
    final compact = Responsive.of(context) == WindowSizeClass.compacto;
    final evidenceAnchor = GlobalKey();
    final canOpenReview =
        session.role != UserRole.asesor && _isReviewable(payment.estado);

    final information = _section(context, 'Información del pago', [
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth < 520 ? 1 : 2;
          final gap = AppTheme.space4;
          final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: AppTheme.space4,
            children: [
              for (final entry in <String, String>{
                'Cliente': payment.clienteNombre,
                'Contrato': payment.contratoFolio,
                'Servicio': payment.servicioNombre,
                'Número de pago': payment.numeroPago == null
                    ? '—'
                    : '${payment.numeroPago} de ${payment.cantidadPagos ?? '—'}',
                'Importe del pago': MoneyFormatter.format(payment.monto),
                'Fecha de pago': MoneyFormatter.formatDate(payment.fechaPago),
                'Método': payment.formaPago,
                'Referencia': payment.referencia.isEmpty
                    ? 'Sin referencia'
                    : payment.referencia,
                'Asesor': payment.asesorNombre,
              }.entries)
                SizedBox(
                  width: width,
                  child: _field(entry.key, entry.value),
                ),
            ],
          );
        },
      ),
      const SizedBox(height: AppTheme.space4),
      _observations(payment.observaciones),
    ]);

    final evidence = _section(
      context,
      'Comprobante',
      [
        if (payment.evidencias.isEmpty) const Text('Sin evidencias adjuntas.'),
        for (final file in payment.evidencias)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.description_outlined,
                color: AppTheme.secondaryDark),
            title:
                Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${file.mimeType} · ${_size(file.sizeBytes)}'),
          ),
      ],
      key: evidenceAnchor,
    );

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
              label: const Text('Pagos'),
            ),
          ),
          AppPageHeader(
            eyebrow: 'Pago ${payment.folio}',
            title: payment.numeroPago == null
                ? payment.folio
                : 'Mensualidad ${payment.numeroPago} de ${payment.cantidadPagos ?? '—'}',
            description:
                'Registrado el ${MoneyFormatter.formatDate(payment.fechaPago)}',
            actions: [
              if (session.role != UserRole.asesor &&
                  payment.evidencias.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => Scrollable.ensureVisible(
                    evidenceAnchor.currentContext!,
                    duration: const Duration(milliseconds: 250),
                    alignment: .15,
                  ),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Comprobante'),
                ),
              if (canOpenReview)
                FilledButton.icon(
                  onPressed: () => context.go('/validacion/${payment.id}'),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Revisar evidencia'),
                ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(AppTheme.space4),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border.all(color: AppTheme.line),
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppTheme.space4,
              runSpacing: AppTheme.space2,
              children: [
                AppBadge(
                  label: _displayState(payment.estado),
                  tone: _stateTone(payment.estado),
                ),
                Text(
                  MoneyFormatter.format(payment.monto),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          if (compact) ...[
            information,
            const SizedBox(height: AppTheme.space4),
            evidence,
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: information),
                const SizedBox(width: AppTheme.space4),
                Expanded(child: evidence),
              ],
            ),
          const SizedBox(height: AppTheme.space4),
          _stateHistory(context, payment),
        ],
      ),
    );
  }

  Widget _stateHistory(BuildContext context, PagoModel payment) {
    const states = [
      'Pendiente de revisión financiera',
      'Pendiente de autorización',
      'Validado',
    ];
    final activeIndex = _stateIndex(payment.estado);
    final rejected = payment.estado == 'Rechazado';
    return _section(context, 'Historial de estados', [
      if (rejected)
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.cancel_outlined, color: AppTheme.danger),
          title: Text('Rechazado'),
          subtitle: Text('Estado final'),
        )
      else
        for (var index = 0; index < states.length; index++)
          _progressRow(
            states[index],
            index,
            activeIndex,
            isLast: index == states.length - 1,
          ),
      const Divider(height: AppTheme.space5),
      if (payment.historial.isEmpty)
        const Text('Sin movimientos de historial.'),
      for (final entry in payment.historial)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.history, color: AppTheme.secondaryDark),
          title: Text(entry, style: const TextStyle(fontSize: 12)),
        ),
    ]);
  }

  Widget _progressRow(String label, int index, int activeIndex,
      {required bool isLast}) {
    final completed = activeIndex >= 0 && index < activeIndex;
    final current = index == activeIndex;
    final color =
        completed || current ? AppTheme.secondaryDark : AppTheme.lineStrong;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 30,
          child: Column(
            children: [
              Icon(
                completed
                    ? Icons.check_circle
                    : current
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                color: color,
                size: 20,
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 28,
                  color: completed ? AppTheme.secondaryDark : AppTheme.line,
                ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2, bottom: AppTheme.space3),
            child: Text(
              label,
              style: TextStyle(
                color: current || completed ? AppTheme.ink : AppTheme.muted,
                fontWeight: current ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
        if (current) const AppBadge(label: 'Actual', tone: AppBadgeTone.info),
        if (!current && !completed)
          const AppBadge(label: 'Por validar', tone: AppBadgeTone.neutral),
      ],
    );
  }

  Widget _observations(String value) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.space3),
        decoration: BoxDecoration(
          color: AppTheme.surfaceSecondary,
          borderRadius: BorderRadius.circular(AppTheme.radiusField),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Observaciones',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppTheme.space1),
            Text(
              value.isEmpty ? 'Sin observaciones registradas.' : value,
              style: const TextStyle(color: AppTheme.inkSecondary),
            ),
          ],
        ),
      );

  Widget _field(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
          const SizedBox(height: AppTheme.space1),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      );

  Widget _section(
    BuildContext context,
    String title,
    List<Widget> children, {
    Key? key,
  }) =>
      Container(
        key: key,
        padding: const EdgeInsets.all(AppTheme.space4),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.line),
          boxShadow: AppTheme.elevation,
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

  bool _isReviewable(String status) =>
      _stateIndex(status) >= 0 && status != 'Validado' && status != 'Rechazado';

  int _stateIndex(String status) => switch (status) {
        'Por revisar' || 'Pendiente de revisión financiera' => 0,
        'Pendiente de autorización' => 1,
        'Validado' => 2,
        _ => -1,
      };

  String _displayState(String status) =>
      status == 'Por revisar' ? 'Pendiente de revisión financiera' : status;

  AppBadgeTone _stateTone(String status) => switch (status) {
        'Validado' => AppBadgeTone.success,
        'Rechazado' => AppBadgeTone.danger,
        _ => AppBadgeTone.warning,
      };

  String _size(int bytes) => bytes < 1024 * 1024
      ? '${(bytes / 1024).ceil()} KB'
      : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
