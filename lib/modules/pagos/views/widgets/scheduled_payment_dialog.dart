import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/config/env.dart';
import '../../../../core/network/api_error_model.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../auth/auth.dart';
import '../../controllers/pagos_controller.dart';
import '../../models/pago_programado_model.dart';

Future<void> showScheduledPayment(BuildContext context, WidgetRef ref,
    PagoProgramadoModel payment, UserRole role) async {
  final reason = TextEditingController();
  final form = GlobalKey<FormState>();
  var saving = false;
  try {
    await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
              builder: (dialogContext, setDialogState) => AppDialog(
                title: 'Cobro ${payment.numeroPago}',
                description:
                    '${payment.contratoFolio} · ${payment.clienteNombre}',
                actions: [
                  TextButton(
                      onPressed:
                          saving ? null : () => Navigator.pop(dialogContext),
                      child: const Text('Cerrar')),
                  if (!AppEnv.demoMode &&
                      role != UserRole.asesor &&
                      payment.pagosRegistrados == 0 &&
                      payment.estado != 'Cancelado')
                    FilledButton(
                        onPressed: saving
                            ? null
                            : () async {
                                if (!form.currentState!.validate()) return;
                                setDialogState(() => saving = true);
                                final controller = ref.read(
                                    pagosControllerProvider(role).notifier);
                                try {
                                  await ref
                                      .read(pagosRepositoryProvider)
                                      .cancelSchedule(payment.id, reason.text);
                                  await controller.load();
                                  if (dialogContext.mounted) {
                                    Navigator.pop(dialogContext);
                                  }
                                } catch (error) {
                                  if (dialogContext.mounted) {
                                    setDialogState(() => saving = false);
                                    ScaffoldMessenger.of(dialogContext)
                                        .showSnackBar(SnackBar(
                                            content: Text(
                                                ApiErrorModel.fromObject(error)
                                                    .message)));
                                  }
                                }
                              },
                        child: const Text('Cancelar obligación')),
                ],
                child: Form(
                    key: form,
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Estado: ${payment.estado}'),
                          if (payment.motivoCancelacion != null)
                            Text(
                                'Cancelación: ${payment.motivoCancelacion}\nActor: ${payment.canceladoPor}\nFecha: ${payment.canceladoEn}'),
                          Text(
                              'Vencimiento: ${payment.fechaVencimiento == null ? 'Sin fecha histórica' : MoneyFormatter.formatDate(payment.fechaVencimiento!)}'),
                          Text(
                              'Monto esperado: ${payment.montoEsperado == null ? 'Sin importe definido' : MoneyFormatter.format(payment.montoEsperado!)}'),
                          Text(
                              'Abonado validado: ${payment.montoAbonadoValidado == null ? 'No disponible' : MoneyFormatter.format(payment.montoAbonadoValidado!)}'),
                          Text(
                              'Saldo confirmado: ${payment.saldoPendienteConfirmado == null ? 'No disponible' : MoneyFormatter.format(payment.saldoPendienteConfirmado!)}'),
                          if (payment.motivoSaldoNoDisponible != null)
                            Text('Motivo: ${payment.motivoSaldoNoDisponible}'),
                          Text('Pagos vinculados: ${payment.pagosRegistrados}'),
                          if (payment.tipoCobroNombre != null)
                            Text('Tipo de cobro: ${payment.tipoCobroNombre}'),
                          if (payment.motivoPenalizacion != null)
                            Text('Motivo: ${payment.motivoPenalizacion}'),
                          if (payment.clasificacionTopeApd != null)
                            Text(
                                'Clasificación APD: ${payment.clasificacionTopeApd}'),
                          if (payment.montoRecibidoBeneficiarioApd != null)
                            Text(
                                'Recibido por beneficiario: ${MoneyFormatter.format(payment.montoRecibidoBeneficiarioApd!)}'),
                          if (!AppEnv.demoMode &&
                              role != UserRole.asesor &&
                              payment.pagosRegistrados == 0 &&
                              payment.estado != 'Cancelado')
                            TextFormField(
                                controller: reason,
                                maxLength: 1000,
                                decoration: const InputDecoration(
                                    labelText: 'Motivo de cancelación *'),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                        ? 'Indica el motivo.'
                                        : null),
                        ])),
              ),
            ));
  } finally {
    reason.dispose();
  }
}
