import 'package:decimal/decimal.dart';

class PrenominaCutModel {
  const PrenominaCutModel({
    required this.id,
    required this.name,
    required this.period,
    required this.status,
    required this.people,
    required this.operations,
    required this.total,
    required this.generated,
  });

  final String id;
  final String name;
  final String period;
  final String status;
  final int people;
  final int operations;
  final Decimal total;
  final bool generated;
}
