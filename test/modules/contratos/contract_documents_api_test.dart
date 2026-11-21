import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/core/platform/selected_file.dart';
import 'package:h3ga_finanzas/modules/contratos/models/contract_document_model.dart';
import 'package:h3ga_finanzas/modules/contratos/repositories/contratos_repository.dart';

void main() {
  test('document retry preserves request key and never posts a second contract',
      () async {
    final dio = Dio();
    final ids = <String>[];
    var attempts = 0;
    dio.interceptors.add(InterceptorsWrapper(onRequest: (r, h) {
      expect(r.path, '/finanzas/contratos/contract/documentos');
      final body = r.data as FormData;
      ids.add(body.fields.single.value);
      expect(body.files.single.value.contentType.toString(), 'application/pdf');
      attempts++;
      if (attempts == 1) {
        h.reject(DioException(requestOptions: r));
        return;
      }
      h.resolve(Response(requestOptions: r, data: {
        'id': 'document',
        'contrato_id': 'contract',
        'solicitud_id': ids.last
      }));
    }));
    final repo = ContratosRepository(demoMode: false, dio: dio);
    final pending = PendingContractDocument(SelectedFile(
        name: 'contract.pdf',
        bytes: Uint8List.fromList('%PDF-1.7 test %%EOF'.codeUnits)));
    repo.retainPendingDocuments('contract', [pending]);
    await expectLater(
        repo.retryDocuments('contract'), throwsA(isA<DioException>()));
    expect(repo.pendingDocuments('contract'), hasLength(1));
    await repo.retryDocuments('contract');
    expect(ids, [pending.requestId, pending.requestId]);
    expect(repo.pendingDocuments('contract'), isEmpty);
  });
  test(
      'content validation rejects spoofed executables, empty and oversized files',
      () {
    for (final file in [
      SelectedFile(
          name: 'fake.pdf',
          bytes: Uint8List.fromList('MZ executable'.codeUnits)),
      SelectedFile(name: 'empty.png', bytes: Uint8List(0)),
      SelectedFile(name: 'big.jpg', bytes: Uint8List(10485761))
    ]) {
      expect(() => contractFileMime(file), throwsFormatException);
    }
  });
}
