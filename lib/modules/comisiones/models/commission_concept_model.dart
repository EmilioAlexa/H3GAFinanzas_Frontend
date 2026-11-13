class CommissionConceptModel {
  const CommissionConceptModel({
    required this.id,
    required this.name,
    required this.external,
    this.onlyImssServices = false,
  });

  final int id;
  final String name;
  final bool external;
  final bool onlyImssServices;
}
