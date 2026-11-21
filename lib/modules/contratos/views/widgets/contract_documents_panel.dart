import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../../../core/platform/file_platform_factory.dart';
import '../../models/contract_document_model.dart';
import '../../repositories/contratos_repository.dart';

final contractDocumentsProvider = FutureProvider.autoDispose
    .family<List<ContractDocument>, String>(
        (ref, id) => ref.watch(contratosRepositoryProvider).documents(id));

class ContractDocumentsPanel extends ConsumerStatefulWidget {
  const ContractDocumentsPanel(
      {required this.contractId, required this.ready, super.key});
  final String contractId;
  final bool ready;
  @override
  ConsumerState<ContractDocumentsPanel> createState() => _State();
}

class _State extends ConsumerState<ContractDocumentsPanel> {
  bool _busy = false;
  String? _error;
  Future<void> _retry() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(contratosRepositoryProvider)
          .retryDocuments(widget.contractId);
      ref.invalidate(contractDocumentsProvider(widget.contractId));
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Hay documentos pendientes. Reintenta la carga; el contrato ya existe.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add() async {
    final file = await createFilePlatform().chooseFile(allowPng: true);
    if (file == null || !mounted) return;
    try {
      contractFileMime(file);
    } catch (error) {
      setState(() => _error = error.toString());
      return;
    }
    final repository = ref.read(contratosRepositoryProvider);
    repository.retainPendingDocuments(widget.contractId, [
      ...repository.pendingDocuments(widget.contractId),
      PendingContractDocument(file)
    ]);
    await _retry();
  }

  Future<void> _open(ContractDocument doc, bool download) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final bytes = await ref
          .read(contratosRepositoryProvider)
          .documentBytes(widget.contractId, doc.id);
      if (!mounted) return;
      if (download) {
        await createFilePlatform().downloadFile(doc.name, bytes);
      } else {
        await showDialog<void>(
            context: context,
            builder: (_) => Dialog(
                child: SizedBox(
                    width: 760,
                    height: 620,
                    child: doc.mime == 'application/pdf'
                        ? PdfViewer.data(bytes, sourceName: doc.name)
                        : InteractiveViewer(
                            child: Image.memory(bytes, fit: BoxFit.contain)))));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo consultar el documento privado.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.ready) {
      return const ListTile(
          leading: Icon(Icons.description_outlined),
          title: Text('Documentos contractuales'),
          subtitle: Text(
              'Pendiente de instalar y verificar el esquema de documentos'));
    }
    final pending = ref
        .watch(contratosRepositoryProvider)
        .pendingDocuments(widget.contractId);
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ref.watch(contractDocumentsProvider(widget.contractId)).when(
              loading: () => const LinearProgressIndicator(),
              error: (e, s) => TextButton(
                  onPressed: () => ref
                      .invalidate(contractDocumentsProvider(widget.contractId)),
                  child: const Text(
                      'No se pudieron consultar los documentos. Reintentar')),
              data: (docs) => Column(mainAxisSize: MainAxisSize.min, children: [
                    if (docs.isEmpty)
                      const ListTile(title: Text('Sin documentos registrados')),
                    for (final doc in docs)
                      ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(doc.name),
                          subtitle: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${doc.mime} | ${(doc.size / 1024).toStringAsFixed(1)} KiB | ${doc.date.toLocal()}'),
                                Wrap(children: [
                                  TextButton(
                                      onPressed: _busy
                                          ? null
                                          : () => _open(doc, false),
                                      child: const Text('Ver documento')),
                                  TextButton(
                                      onPressed:
                                          _busy ? null : () => _open(doc, true),
                                      child: const Text('Descargar')),
                                ]),
                              ])),
                  ])),
          if (_error != null) Text(_error!),
          if (pending.isNotEmpty) ...[
            for (final file in pending) Text('Pendiente: ${file.file.name}'),
            TextButton(
                onPressed: _busy ? null : _retry,
                child: const Text('Reintentar documentos pendientes'))
          ],
          OutlinedButton.icon(
              onPressed: _busy ? null : _add,
              icon: const Icon(Icons.attach_file),
              label: Text(_busy ? 'Procesando...' : 'Adjuntar documento')),
        ]);
  }
}
