import 'commission_payment_model.dart';
import 'dispersion_receiver_model.dart';

class ComisionesStateModel {
  const ComisionesStateModel({required this.payments, required this.receivers});

  final List<CommissionPaymentModel> payments;
  final List<DispersionReceiverModel> receivers;
}
