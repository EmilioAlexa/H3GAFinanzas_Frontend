import '../../auth/models/user_role_model.dart';
import 'pago_model.dart';

List<String> paymentReviewActions(PagoModel payment, UserRole role) {
  final initial = payment.estado == 'Pendiente de revisión financiera' ||
      payment.estado == 'Por revisar';
  if (role == UserRole.administradorFinanciero && initial) {
    return [
      'rechazar',
      if (payment.hasEvidenceForApproval) 'enviar_a_autorizacion'
    ];
  }
  if (role == UserRole.administrador &&
      (initial || payment.estado == 'Pendiente de autorización')) {
    return ['rechazar', if (payment.hasEvidenceForApproval) 'validar'];
  }
  return [];
}
