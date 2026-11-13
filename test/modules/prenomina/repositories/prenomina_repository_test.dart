import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/modules/prenomina/repositories/prenomina_repository.dart';

void main() {
  test('recipient totals use exact Decimal arithmetic', () {
    final repository = PrenominaRepository();
    final daniela = repository.findDemo('demo-daniela')!;
    expect(daniela.total, Decimal.parse('2700'));
    expect(daniela.operationCount, 2);
  });

  test('generation marks local details included and cannot run twice', () {
    final repository = PrenominaRepository();
    repository.generateDemo('demo-cut-021');
    expect(
      repository
          .recipientsForCut('demo-cut-021')
          .every((item) => item.status == 'Preparada'),
      isTrue,
    );
    expect(
      repository
          .recipientsForCut('demo-cut-021')
          .expand((item) => item.movements)
          .every((movement) => movement.status == 'Incluida'),
      isTrue,
    );
    expect(() => repository.generateDemo('demo-cut-021'), throwsStateError);
  });
}
