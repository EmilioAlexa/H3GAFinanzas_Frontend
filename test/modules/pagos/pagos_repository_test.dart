import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/core/platform/selected_file.dart';
import 'package:h3ga_finanzas/modules/auth/auth.dart';
import 'package:h3ga_finanzas/modules/pagos/pagos.dart';

void main() {
  test('advisor only receives assigned payments and scheduled charges', () {
    final repository = PagosRepository();

    final payments = repository.loadPayments(UserRole.asesor, demoMode: true)!;
    final scheduled =
        repository.loadScheduled(UserRole.asesor, demoMode: true)!;

    expect(payments, hasLength(2));
    expect(payments.every((item) => item.assignedToCurrentAdvisor), isTrue);
    expect(scheduled, hasLength(2));
    expect(scheduled.every((item) => item.assignedToCurrentAdvisor), isTrue);
    expect(repository.loadPayments(UserRole.administrador, demoMode: false),
        isNull);
  });

  test(
      'payment payload contains only API fields and serializes Decimal exactly',
      () {
    final payment = PagosDemoFixtures.payments.first;
    final payload = payment.toCreatePayload(
      contratoId: 'contract-id',
      formaPagoId: 2,
      monto: Decimal.parse('1234.50'),
      fechaPago: DateTime(2025, 5, 2),
      referencia: 'REF-1',
      observaciones: 'Nota',
    );

    expect(
        Decimal.parse(payload['monto']! as String), Decimal.parse('1234.50'));
    expect(payload['contrato_id'], 'contract-id');
    expect(payload['forma_pago_id'], 2);
    expect(payload['referencia_pago'], 'REF-1');
    expect(payload, isNot(contains('estado')));
    expect(payload, isNot(contains('evidencias')));
  });

  test('evidence validation allows API file types up to 10 MB only', () {
    SelectedFile file(String name, int size) {
      final bytes = Uint8List(size);
      if (size >= 5) {
        bytes.setAll(
            0, name.endsWith('.pdf') ? '%PDF-'.codeUnits : [0xff, 0xd8, 0xff]);
      }
      return SelectedFile(name: name, bytes: bytes);
    }

    expect(validateEvidence(file('recibo.pdf', maxEvidenceBytes)), isNull);
    expect(validateEvidence(file('foto.jpeg', 12)), isNull);
    expect(validateEvidence(file('foto.png', 12)), isNotNull);
    expect(
        validateEvidence(SelectedFile(name: 'falso.pdf', bytes: Uint8List(20))),
        isNotNull);
    expect(
        validateEvidence(file('grande.jpg', maxEvidenceBytes + 1)), isNotNull);
  });
}
