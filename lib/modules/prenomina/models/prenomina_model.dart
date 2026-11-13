import 'package:decimal/decimal.dart';

import 'prenomina_movement_model.dart';

class PrenominaModel {
  const PrenominaModel({
    required this.id,
    required this.cutId,
    required this.cutName,
    required this.period,
    required this.recipientId,
    required this.recipient,
    required this.position,
    required this.status,
    required this.movements,
  });

  final String id;
  final String cutId;
  final String cutName;
  final String period;
  final String recipientId;
  final String recipient;
  final String position;
  final String status;
  final List<PrenominaMovementModel> movements;

  Decimal get total => movements.fold(
        Decimal.zero,
        (sum, movement) => sum + movement.commissionAmount,
      );

  int get operationCount =>
      movements.map((item) => item.payment).toSet().length;
}
