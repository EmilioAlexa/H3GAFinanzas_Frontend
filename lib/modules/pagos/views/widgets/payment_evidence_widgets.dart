import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../../../core/network/api_error_model.dart';
import '../../../../core/platform/file_platform_factory.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../../auth/auth.dart';
import '../../controllers/pagos_controller.dart';
import '../../models/evidencia_pago_model.dart';
import '../../models/payment_evidence_validation.dart';

class PaymentEvidenceUploadButton extends ConsumerStatefulWidget {
  const PaymentEvidenceUploadButton({required this.paymentId, super.key});
  final String paymentId;
  @override
  ConsumerState<PaymentEvidenceUploadButton> createState() =>
      _PaymentEvidenceUploadButtonState();
}

class _PaymentEvidenceUploadButtonState
    extends ConsumerState<PaymentEvidenceUploadButton> {
  bool _uploading = false;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: _uploading ? null : _upload,
        icon: const Icon(Icons.attach_file),
        label: Text(_uploading ? 'Cargando…' : 'Adjuntar evidencia'),
      );

  Future<void> _upload() async {
    if (_uploading) return;
    setState(() => _uploading = true);
    try {
      final file = await createFilePlatform().chooseFile();
      if (file == null || !mounted) return;
      final validation = validatePaymentEvidence(file);
      if (validation != null) throw StateError(validation);
      final session = ref.read(authControllerProvider).valueOrNull!;
      await ref.read(pagosRepositoryProvider).upload(widget.paymentId, file);
      if (!mounted) return;
      ref.invalidate(pagoDetailProvider(widget.paymentId));
      await ref.read(pagosControllerProvider(session.role).notifier).load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(error is StateError
                ? error.message.toString()
                : ApiErrorModel.fromObject(error).message)));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }
}

Future<void> showPaymentEvidence(
        BuildContext context, EvidenciaPagoModel evidence) =>
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
          child: SizedBox(
              width: 760,
              height: 620,
              child: _PaymentEvidenceViewer(evidence: evidence))),
    );

class _PaymentEvidenceViewer extends ConsumerWidget {
  const _PaymentEvidenceViewer({required this.evidence});
  final EvidenciaPagoModel evidence;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Uint8List?> state = evidence.demoOnly
        ? AsyncData(evidence.previewBytes)
        : ref.watch(evidenceBytesProvider(evidence.id));
    return Column(children: [
      Row(children: [
        Expanded(
            child: Padding(
                padding: const EdgeInsets.all(16), child: Text(evidence.name))),
        IconButton(
            tooltip: 'Cerrar',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close))
      ]),
      Expanded(
          child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppStatePanel(
            icon: Icons.cloud_off_outlined,
            title: 'No se pudo descargar la evidencia',
            message: ApiErrorModel.fromObject(error).message,
            action: TextButton(
                onPressed: () =>
                    ref.invalidate(evidenceBytesProvider(evidence.id)),
                child: const Text('Reintentar'))),
        data: (bytes) => bytes == null
            ? const Center(child: Text('Vista previa no disponible.'))
            : evidence.mimeType == 'application/pdf'
                ? PdfViewer.data(bytes, sourceName: evidence.name)
                : InteractiveViewer(
                    child: Image.memory(bytes,
                        errorBuilder: (_, __, ___) =>
                            const Text('Vista previa no disponible.'))),
      )),
      if (state.valueOrNull case final bytes?)
        TextButton.icon(
            onPressed: () async {
              try {
                await createFilePlatform().downloadFile(evidence.name, bytes);
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('No se pudo guardar el archivo.')));
                }
              }
            },
            icon: const Icon(Icons.download_outlined),
            label: const Text('Descargar')),
    ]);
  }
}
