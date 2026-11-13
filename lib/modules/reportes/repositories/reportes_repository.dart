import '../fixtures/reportes_demo_fixtures.dart';
import '../models/report_data_model.dart';
import '../models/report_type_model.dart';

class ReportesRepository {
  const ReportesRepository({required this.demoMode});

  final bool demoMode;

  List<ReportDataModel> listDemo() =>
      List.unmodifiable(ReportesDemoFixtures.reports.values);

  ReportDataModel? findDemo(ReportType type) =>
      ReportesDemoFixtures.reports[type];
}
