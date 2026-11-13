import 'package:decimal/decimal.dart';

import 'commission_line_model.dart';
import 'commission_snapshot_model.dart';

class CommissionPaymentModel {
  const CommissionPaymentModel({
    required this.id,
    required this.paymentFolio,
    required this.contractId,
    required this.contractFolio,
    required this.clientName,
    required this.serviceName,
    required this.advisorName,
    required this.paymentAmount,
    required this.paymentDate,
    required this.paymentMethod,
    required this.assignedToCurrentAdvisor,
    required this.snapshot,
    required this.configuration,
    required this.configurationHistory,
  });

  final String id;
  final String paymentFolio;
  final String contractId;
  final String contractFolio;
  final String clientName;
  final String serviceName;
  final String advisorName;
  final Decimal paymentAmount;
  final DateTime paymentDate;
  final String paymentMethod;
  final bool assignedToCurrentAdvisor;
  final List<CommissionSnapshotModel> snapshot;
  final List<CommissionLineModel> configuration;
  final List<String> configurationHistory;

  CommissionPaymentModel withConfiguration({
    required List<CommissionLineModel> lines,
    required String historyEntry,
  }) =>
      CommissionPaymentModel(
        id: id,
        paymentFolio: paymentFolio,
        contractId: contractId,
        contractFolio: contractFolio,
        clientName: clientName,
        serviceName: serviceName,
        advisorName: advisorName,
        paymentAmount: paymentAmount,
        paymentDate: paymentDate,
        paymentMethod: paymentMethod,
        assignedToCurrentAdvisor: assignedToCurrentAdvisor,
        snapshot: snapshot,
        configuration: lines,
        configurationHistory: [...configurationHistory, historyEntry],
      );

  CommissionPaymentModel withSnapshot(
    List<CommissionSnapshotModel> lines,
  ) =>
      CommissionPaymentModel(
        id: id,
        paymentFolio: paymentFolio,
        contractId: contractId,
        contractFolio: contractFolio,
        clientName: clientName,
        serviceName: serviceName,
        advisorName: advisorName,
        paymentAmount: paymentAmount,
        paymentDate: paymentDate,
        paymentMethod: paymentMethod,
        assignedToCurrentAdvisor: assignedToCurrentAdvisor,
        snapshot: lines,
        configuration: configuration,
        configurationHistory: configurationHistory,
      );
}
