import 'package:decimal/decimal.dart';

import '../../auth/models/user_role_model.dart';
import '../fixtures/comisiones_demo_fixtures.dart';
import '../models/commission_concept_model.dart';
import '../models/commission_line_model.dart';
import '../models/commission_payment_model.dart';
import '../models/commission_snapshot_model.dart';
import '../models/dispersion_receiver_model.dart';
import '../utils/commission_math.dart';

class ComisionesRepository {
  final List<CommissionPaymentModel> _payments =
      List.of(ComisionesDemoFixtures.payments);
  final List<DispersionReceiverModel> _receivers =
      List.of(ComisionesDemoFixtures.receivers);
  int _nextReceiverId = 1;

  List<CommissionPaymentModel>? loadPayments(
    UserRole role, {
    required bool demoMode,
  }) =>
      demoMode ? _visiblePayments(role) : null;

  List<DispersionReceiverModel>? loadReceivers(
    UserRole role, {
    required bool demoMode,
  }) =>
      demoMode && role != UserRole.asesor
          ? List.of(_receivers)
          : demoMode
              ? const []
              : null;

  CommissionPaymentModel? findPayment(String id, UserRole role) {
    for (final payment in _visiblePayments(role)) {
      if (payment.id == id) return payment;
    }
    return null;
  }

  CommissionPaymentModel? findContract(String contractId, UserRole role) {
    for (final payment in _visiblePayments(role)) {
      if (payment.contractId == contractId) return payment;
    }
    return null;
  }

  List<DispersionReceiverModel> activeReceiversFor(int conceptId) => _receivers
      .where((item) => item.active && item.conceptId == conceptId)
      .toList();

  List<CommissionConceptModel> get concepts => ComisionesDemoFixtures.concepts;

  CommissionPaymentModel saveConfigurationDemo({
    required String contractId,
    required List<CommissionLineModel> lines,
    required UserRole role,
    required String actor,
  }) {
    _requireManagementRole(role);
    if (lines.length > 20) throw StateError('El máximo es 20 receptores.');
    final contractIndex =
        _payments.indexWhere((item) => item.contractId == contractId);
    if (contractIndex < 0) throw StateError('Contrato demo no disponible.');
    final current = _payments[contractIndex];
    if (lines
        .any((line) => !CommissionMath.isAllowedPercentage(line.percentage))) {
      throw StateError('Usa porcentajes en pasos de 0.5 entre 0 y 100.');
    }
    if (CommissionMath.sum(lines.map((line) => line.percentage)) >
        Decimal.fromInt(100)) {
      throw StateError('La suma no puede superar 100%.');
    }
    if (current.serviceName == 'APD' &&
        lines.any((line) => line.conceptId == 4)) {
      throw StateError('IMSS no aplica para APD.');
    }
    for (final line in lines) {
      final receiver = _receivers.where((item) => item.id == line.receiverId);
      if (receiver.isEmpty ||
          !receiver.first.active ||
          receiver.first.conceptId != line.conceptId) {
        throw StateError('Selecciona un receptor activo del concepto.');
      }
    }
    final updated = current.withConfiguration(
      lines: List.unmodifiable(lines),
      historyEntry: 'Configuración demo guardada por $actor',
    );
    _payments[contractIndex] = updated;
    return updated;
  }

  DispersionReceiverModel createReceiverDemo({
    required int conceptId,
    required String? userId,
    required String? externalName,
    required UserRole role,
  }) {
    _requireManagementRole(role);
    final concept = concepts.where((item) => item.id == conceptId);
    if (concept.isEmpty) throw StateError('Selecciona un concepto demo.');
    final definition = concept.first;
    String name;
    String? receiverUserId;
    if (definition.external) {
      name = externalName?.trim() ?? '';
      if (name.isEmpty || name.length > 150) {
        throw StateError(
            'El nombre externo debe tener entre 1 y 150 caracteres.');
      }
    } else {
      final user = _receivers.where((item) =>
          item.active && item.conceptId == conceptId && item.userId == userId);
      if (user.isEmpty) {
        throw StateError('Selecciona un usuario activo del concepto.');
      }
      name = user.first.name;
      receiverUserId = userId;
    }
    final receiver = DispersionReceiverModel(
      id: 'demo-receiver-new-${_nextReceiverId++}',
      conceptId: conceptId,
      concept: definition.name,
      name: name,
      active: true,
      external: definition.external,
      userId: receiverUserId,
      role: definition.external ? 'Externo' : 'Usuario activo demo',
    );
    _receivers.add(receiver);
    return receiver;
  }

  DispersionReceiverModel deactivateReceiverDemo(
    String receiverId,
    UserRole role,
  ) {
    _requireManagementRole(role);
    final index = _receivers.indexWhere((item) => item.id == receiverId);
    if (index < 0 || !_receivers[index].active) {
      throw StateError('El receptor ya está inactivo o no existe.');
    }
    final deactivated = _receivers[index].deactivate();
    _receivers[index] = deactivated;
    return deactivated;
  }

  CommissionSnapshotModel disperseDemo({
    required String paymentId,
    required String commissionId,
    required UserRole role,
    required String comment,
    required String actor,
  }) {
    _requireManagementRole(role);
    if (comment.length > 500) {
      throw StateError('El comentario no puede superar 500 caracteres.');
    }
    final paymentIndex = _payments.indexWhere((item) => item.id == paymentId);
    if (paymentIndex < 0) throw StateError('Comisión demo no disponible.');
    final payment = _payments[paymentIndex];
    final itemIndex =
        payment.snapshot.indexWhere((item) => item.id == commissionId);
    if (itemIndex < 0) throw StateError('Comisión demo no disponible.');
    final commission = payment.snapshot[itemIndex];
    if (commission.status != 'Pendiente de dispersión') {
      throw StateError('Solo se dispersan comisiones pendientes.');
    }
    final updatedCommission = commission.copyWithStatus(
      'Dispersada',
      'Dispersada por $actor${comment.trim().isEmpty ? '' : ' · ${comment.trim()}'}',
    );
    final snapshot = List<CommissionSnapshotModel>.of(payment.snapshot)
      ..[itemIndex] = updatedCommission;
    _payments[paymentIndex] = payment.withSnapshot(snapshot);
    return updatedCommission;
  }

  List<CommissionPaymentModel> _visiblePayments(UserRole role) => _payments
      .where((item) => role != UserRole.asesor || item.assignedToCurrentAdvisor)
      .toList();

  void _requireManagementRole(UserRole role) {
    if (role == UserRole.asesor) {
      throw StateError('Esta operación requiere rol administrativo.');
    }
  }
}
