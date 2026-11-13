class ReportFiltersModel {
  const ReportFiltersModel({
    required this.from,
    required this.to,
    this.granularity = 'Semanal',
    this.compare = false,
    this.saleType = 'Todos los tipos',
    this.paymentMethod = 'Todos los métodos',
    this.applied = false,
  });

  final DateTime from;
  final DateTime to;
  final String granularity;
  final bool compare;
  final String saleType;
  final String paymentMethod;
  final bool applied;

  ReportFiltersModel copyWith({
    DateTime? from,
    DateTime? to,
    String? granularity,
    bool? compare,
    String? saleType,
    String? paymentMethod,
    bool? applied,
  }) =>
      ReportFiltersModel(
        from: from ?? this.from,
        to: to ?? this.to,
        granularity: granularity ?? this.granularity,
        compare: compare ?? this.compare,
        saleType: saleType ?? this.saleType,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        applied: applied ?? this.applied,
      );
}
