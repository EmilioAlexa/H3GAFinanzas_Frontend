enum GlobalSearchHitType { cliente, contrato, pago }

class GlobalSearchHitModel {
  const GlobalSearchHitModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.type,
  });

  final String id;
  final String title;
  final String subtitle;
  final String route;
  final GlobalSearchHitType type;
}
