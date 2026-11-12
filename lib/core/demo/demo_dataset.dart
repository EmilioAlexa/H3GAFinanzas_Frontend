import 'demo_metric.dart';
import 'demo_record.dart';

class DemoDataset {
  const DemoDataset({
    required this.module,
    this.metrics = const [],
    this.records = const [],
    this.notes = const [],
  });

  final String module;
  final List<DemoMetric> metrics;
  final List<DemoRecord> records;
  final List<String> notes;

  bool get isEmpty => metrics.isEmpty && records.isEmpty && notes.isEmpty;
}
