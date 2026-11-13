import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/modules/reportes/models/report_type_model.dart';
import 'package:h3ga_finanzas/modules/reportes/repositories/reportes_repository.dart';

void main() {
  test('demo repository contains only the five report routes in OpenAPI', () {
    const repository = ReportesRepository(demoMode: true);
    expect(
      repository.listDemo().map((report) => report.type).toSet(),
      ReportType.values.toSet(),
    );
  });

  test('commission destination demo total reconciles exactly', () {
    const repository = ReportesRepository(demoMode: true);
    final report = repository.findDemo(ReportType.comisionesDestino)!;
    final total =
        report.rows.fold(Decimal.zero, (sum, row) => sum + row.amount);
    expect(total, Decimal.parse('40000'));
    expect(report.total, total);
  });

  test('IMSS demo contains only supported service modalities', () {
    const repository = ReportesRepository(demoMode: true);
    final report = repository.findDemo(ReportType.imss)!;
    expect(
        report.rows.every((row) => {
              'Modalidad 10',
              'Modalidad 40',
              'M40 Retroactiva'
            }.contains(row.service)),
        isTrue);
    expect(report.total, Decimal.parse('15000'));
  });
}
