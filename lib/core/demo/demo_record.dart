class DemoRecord {
  const DemoRecord({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.status,
    this.amount,
    this.details = const {},
  });

  final String id;
  final String title;
  final String subtitle;
  final String? status;
  final String? amount;
  final Map<String, String> details;
}
