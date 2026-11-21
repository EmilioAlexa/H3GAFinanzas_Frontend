import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/modules/contratos/repositories/contratos_repository.dart';
import 'package:h3ga_finanzas/modules/contratos/views/widgets/contract_documents_panel.dart';

void main() {
  testWidgets(
      'does not query uninstalled schema and lists private actions without repeated requests',
      (tester) async {
    final dio = Dio();
    var calls = 0;
    dio.interceptors.add(InterceptorsWrapper(onRequest: (r, h) {
      calls++;
      expect(r.path, '/finanzas/contratos/contract/documentos');
      h.resolve(Response(requestOptions: r, data: [
        {
          'id': 'doc',
          'nombre_original': 'contrato.pdf',
          'mime_type': 'application/pdf',
          'tamano_bytes': 1400,
          'creado_en': '2026-11-21T12:00:00Z'
        }
      ]));
    }));
    final repo = ContratosRepository(demoMode: false, dio: dio);
    Widget app(bool ready) => ProviderScope(
        overrides: [contratosRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
            home: Scaffold(
                body: SingleChildScrollView(
                    child: ContractDocumentsPanel(
                        contractId: 'contract', ready: ready)))));
    await tester.pumpWidget(app(false));
    await tester.pumpAndSettle();
    expect(calls, 0);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(true));
    await tester.pumpAndSettle();
    expect(find.text('contrato.pdf'), findsOneWidget);
    expect(find.text('Ver documento'), findsOneWidget);
    expect(find.text('Descargar'), findsOneWidget);
    expect(calls, 1);
    await tester.pump();
    expect(calls, 1);
    expect(tester.takeException(), isNull);
  });
}
