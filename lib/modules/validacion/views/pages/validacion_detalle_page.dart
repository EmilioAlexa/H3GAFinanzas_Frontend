import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/platform/file_platform_factory.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/responsive/window_size_class.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_notice.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../../auth/auth.dart';
import '../../../pagos/pagos.dart';

class ValidacionDetallePage extends ConsumerStatefulWidget {
  const ValidacionDetallePage({required this.paymentId, super.key});

  final String paymentId;

  @override
  ConsumerState<ValidacionDetallePage> createState() =>
      _ValidacionDetallePageState();
}

class _ValidacionDetallePageState extends ConsumerState<ValidacionDetallePage> {
  String? _selectedEvidenceId;

  @override
  Widget build(BuildContext context) {
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
        .findPayment(widget.paymentId);
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
    final initial = _isInitial(payment.estado);
    final awaitingAdmin = payment.estado == 'Pendiente de autorización';
    final canFinancialReview =
        session.role == UserRole.administradorFinanciero && initial;
    final canAdminReview =
        session.role == UserRole.administrador && (initial || awaitingAdmin);
    final canReview = canFinancialReview || canAdminReview;
    final selectedEvidence = _selectedEvidence(payment.evidencias);
    final expanded = Responsive.of(context) == WindowSizeClass.expandido;

    final informationColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _paymentInformation(context, payment),
        const SizedBox(height: AppTheme.space3),
        _stateHistory(context, payment),
        const SizedBox(height: AppTheme.space3),
        if (canReview)
          _decisionCard(context, ref, session, payment,
              canFinancialReview: canFinancialReview,
              canAdminReview: canAdminReview)
        else
          AppNotice(
            text: payment.estado == 'Validado' || payment.estado == 'Rechazado'
                ? 'Este pago ya tiene una decisión final. El historial se conserva en el registro.'
                : session.role == UserRole.administradorFinanciero
                    ? 'La decisión final de un pago enviado a autorización corresponde a administración.'
                    : 'No hay acciones disponibles para el estado actual.',
          ),
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          _paymentBanner(context, payment),
          const SizedBox(height: AppTheme.space4),
          if (expanded)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: _evidencePreview(payment.evidencias, selectedEvidence),
                ),
                const SizedBox(width: AppTheme.space4),
                Expanded(flex: 4, child: informationColumn),
              ],
            )
          else ...[
            _evidencePreview(payment.evidencias, selectedEvidence),
            const SizedBox(height: AppTheme.space4),
            informationColumn,
          ],
        ],
      ),
    );
  }

  Widget _paymentBanner(BuildContext context, PagoModel payment) => Container(
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
      );

  Widget _evidencePreview(
    List<EvidenciaPagoModel> evidences,
    EvidenciaPagoModel? evidence,
  ) {
    final bytes = evidence?.previewBytes;
    final isImage = evidence?.mimeType.startsWith('image/') ?? false;
    return Container(
      constraints: const BoxConstraints(minHeight: 420),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.line),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: AppTheme.elevation,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppTheme.space4, AppTheme.space3,
                AppTheme.space3, AppTheme.space3),
            child: Row(
              children: [
                const Icon(Icons.attach_file, color: AppTheme.secondaryDark),
                const SizedBox(width: AppTheme.space2),
                Expanded(
                  child: Text(
                    evidence?.name ?? 'Evidencia del pago',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Descargar evidencia',
                  onPressed: evidence == null || bytes == null
                      ? null
                      : () => createFilePlatform()
                          .downloadFile(evidence.name, bytes),
                  icon: const Icon(Icons.download_outlined),
                ),
              ],
            ),
          ),
          if (evidences.length > 1)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space3),
              child: Row(
                children: [
                  for (final file in evidences)
                    Padding(
                      padding: const EdgeInsets.only(right: AppTheme.space2),
                      child: ChoiceChip(
                        label: Text(
                          file.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        selected: file.id == evidence?.id,
                        onSelected: (_) =>
                            setState(() => _selectedEvidenceId = file.id),
                      ),
                    ),
                ],
              ),
            ),
          const Divider(height: 1),
          SizedBox(
            height: 460,
            child: ColoredBox(
              color: AppTheme.canvas,
              child: bytes != null && isImage
                  ? Center(
                      child: InteractiveViewer(
                        minScale: .8,
                        maxScale: 4,
                        child: Image.memory(
                          bytes,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              _previewUnavailable(evidence?.name),
                        ),
                      ),
                    )
                  : _documentPreview(evidence),
            ),
          ),
          if (evidence != null)
            Padding(
              padding: const EdgeInsets.all(AppTheme.space3),
              child: Text(
                '${evidence.mimeType} · ${_size(evidence.sizeBytes)}',
                style: const TextStyle(color: AppTheme.muted, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _documentPreview(EvidenciaPagoModel? evidence) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                evidence?.mimeType == 'application/pdf'
                    ? Icons.picture_as_pdf_outlined
                    : Icons.image_not_supported_outlined,
                color: AppTheme.secondaryDark,
                size: 64,
              ),
              const SizedBox(height: AppTheme.space3),
              Text(
                evidence == null ? 'No hay evidencia adjunta' : evidence.name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppTheme.space1),
              Text(
                evidence == null
                    ? 'Cuando exista un comprobante, su vista previa aparecerá aquí.'
                    : evidence.mimeType == 'application/pdf'
                        ? 'El comprobante PDF está listo para descargar.'
                        : 'No se pudo cargar la vista previa de este archivo.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.muted),
              ),
            ],
          ),
        ),
      );

  Widget _previewUnavailable(String? name) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image_outlined,
                color: AppTheme.muted, size: 48),
            const SizedBox(height: AppTheme.space2),
            Text('No se pudo mostrar ${name ?? 'el archivo'}.'),
          ],
        ),
      );

  Widget _paymentInformation(BuildContext context, PagoModel payment) =>
      _section(context, 'Información del pago', [
        _field('Cliente', payment.clienteNombre),
        _field('Contrato', payment.contratoFolio),
        _field('Servicio', payment.servicioNombre),
        _field('Número de pago', _paymentNumber(payment)),
        _field('Monto', '${MoneyFormatter.format(payment.monto)} MXN'),
        _field('Método', payment.formaPago),
        _field(
          'Referencia',
          payment.referencia.isEmpty ? 'Sin referencia' : payment.referencia,
        ),
        _field('Asesor', payment.asesorNombre),
        _field(
          'Observaciones',
          payment.observaciones.isEmpty
              ? 'Sin observaciones registradas'
              : payment.observaciones,
        ),
      ]);

  Widget _stateHistory(BuildContext context, PagoModel payment) {
    const states = [
      'Pendiente de revisión financiera',
      'Pendiente de autorización',
      'Validado',
    ];
    final activeIndex = _stateIndex(payment.estado);
    return _section(context, 'Estado e historial', [
      if (payment.estado == 'Rechazado')
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
      const Divider(height: AppTheme.space4),
      if (payment.historial.isEmpty) const Text('Sin movimientos registrados.'),
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
    final current = activeIndex == index;
    final color =
        completed || current ? AppTheme.secondaryDark : AppTheme.lineStrong;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Column(
            children: [
              Icon(
                completed
                    ? Icons.check_circle
                    : current
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                color: color,
                size: 19,
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 23,
                  color: completed ? AppTheme.secondaryDark : AppTheme.line,
                ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2, bottom: AppTheme.space2),
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

  Widget _decisionCard(
    BuildContext context,
    WidgetRef ref,
    AuthSessionModel session,
    PagoModel payment, {
    required bool canFinancialReview,
    required bool canAdminReview,
  }) {
    final positiveAction =
        canFinancialReview ? 'enviar_a_autorizacion' : 'validar';
    final positiveLabel =
        canFinancialReview ? 'Enviar a autorización' : 'Aprobar pago';
    final canApprove = canFinancialReview || payment.hasEvidenceForApproval;
    return _section(context, 'Decisión de revisión', [
      const Text(
        'Confirma que los datos y el comprobante correspondan al pago.',
        style: TextStyle(color: AppTheme.muted),
      ),
      const SizedBox(height: AppTheme.space3),
      if (canAdminReview && !payment.hasEvidenceForApproval) ...[
        const AppNotice(
          type: AppNoticeType.warning,
          text:
              'Se requiere evidencia compatible con el método de pago para aprobar.',
        ),
        const SizedBox(height: AppTheme.space2),
      ],
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: canApprove
              ? () => _confirmAction(
                    context,
                    ref,
                    session,
                    payment,
                    positiveAction,
                  )
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.success,
            foregroundColor: AppTheme.white,
            minimumSize: const Size(48, 48),
          ),
          icon: const Icon(Icons.check_circle_outline),
          label: Text(positiveLabel),
        ),
      ),
      const SizedBox(height: AppTheme.space2),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () =>
              _confirmAction(context, ref, session, payment, 'rechazar'),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.danger,
            foregroundColor: AppTheme.white,
            minimumSize: const Size(48, 48),
          ),
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Rechazar pago'),
        ),
      ),
    ]);
  }

  Future<void> _confirmAction(BuildContext context, WidgetRef ref,
      AuthSessionModel session, PagoModel payment, String action) async {
    final commentController = TextEditingController();
    final rejecting = action == 'rechazar';
    final sending = action == 'enviar_a_autorizacion';
    final title = rejecting
        ? 'Rechazar pago'
        : sending
            ? 'Enviar a autorización'
            : 'Aprobar pago';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              rejecting
                  ? 'La decisión quedará registrada en el historial del pago.'
                  : sending
                      ? 'El pago pasará a Pendiente de autorización.'
                      : 'El pago quedará como Validado.',
            ),
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
            style: FilledButton.styleFrom(
              backgroundColor: rejecting ? AppTheme.danger : AppTheme.success,
              foregroundColor: AppTheme.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(rejecting ? 'Rechazar pago' : 'Confirmar'),
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
          const SnackBar(content: Text('Estado actualizado.')),
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

  EvidenciaPagoModel? _selectedEvidence(List<EvidenciaPagoModel> evidences) {
    if (evidences.isEmpty) return null;
    for (final evidence in evidences) {
      if (evidence.id == _selectedEvidenceId) return evidence;
    }
    return evidences.first;
  }

  int _stateIndex(String status) => switch (status) {
        'Por revisar' || 'Pendiente de revisión financiera' => 0,
        'Pendiente de autorización' => 1,
        'Validado' => 2,
        _ => -1,
      };

  bool _isInitial(String status) =>
      status == 'Por revisar' || status == 'Pendiente de revisión financiera';

  String _displayState(String status) =>
      status == 'Por revisar' ? 'Pendiente de revisión financiera' : status;

  Widget _section(BuildContext context, String title, List<Widget> children) =>
      Container(
        padding: const EdgeInsets.all(AppTheme.space4),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.line),
          borderRadius: BorderRadius.circular(AppTheme.radius),
          boxShadow: AppTheme.elevation,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.muted)),
            const SizedBox(height: AppTheme.space1),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );

  String _paymentNumber(PagoModel payment) {
    final number = payment.numeroPago;
    final total = payment.cantidadPagos;
    if (number == null || total == null) return 'Sin número en la respuesta';
    return total == 1
        ? 'Pago único · $number de $total'
        : 'Mensualidad $number de $total';
  }

  AppBadgeTone _stateTone(String status) => switch (status) {
        'Validado' => AppBadgeTone.success,
        'Rechazado' => AppBadgeTone.danger,
        _ => AppBadgeTone.warning,
      };

  String _size(int bytes) => bytes < 1024 * 1024
      ? '${(bytes / 1024).ceil()} KB'
      : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
