class DispersionReceiverModel {
  const DispersionReceiverModel({
    required this.id,
    required this.conceptId,
    required this.concept,
    required this.name,
    required this.active,
    required this.external,
    this.userId,
    this.role,
  });

  final String id;
  final int conceptId;
  final String concept;
  final String name;
  final bool active;
  final bool external;
  final String? userId;
  final String? role;

  DispersionReceiverModel deactivate() => DispersionReceiverModel(
        id: id,
        conceptId: conceptId,
        concept: concept,
        name: name,
        active: false,
        external: external,
        userId: userId,
        role: role,
      );

  Map<String, Object?> toCreatePayload() => {
        'concepto_id': conceptId,
        if (external) 'nombre_externo': name else 'usuario_id': userId,
      };
}
