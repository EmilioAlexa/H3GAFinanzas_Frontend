import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/env.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../../auth/auth.dart';
import '../../../comisiones/fixtures/comisiones_demo_fixtures.dart';
import '../../../pagos/fixtures/pagos_demo_fixtures.dart';
import '../../../pagos/models/pago_model.dart';
import '../../controllers/contratos_controller.dart';
import '../../models/contrato_model.dart';

class ContratoDetallePage extends ConsumerWidget {
  const ContratoDetallePage({required this.contratoId, super.key});

  final String contratoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return auth.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const AppStatePanel(
        icon: Icons.lock_outline,
        title: 'No se pudo cargar la sesión',
        message: 'Vuelve a iniciar sesión para consultar el contrato.',
      ),
      data: (session) {
        if (session == null) {
          return const AppStatePanel(
            icon: Icons.lock_outline,
            title: 'Inicia sesión para continuar',
            message: 'El detalle requiere una sesión activa.',
          );
        }
        final state = ref.watch(contratosControllerProvider(session.role));
        return state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => AppStatePanel(
            icon: Icons.cloud_off_outlined,
            title: 'No se pudo cargar el contrato',
            message: 'Inténtalo de nuevo.',
            action: TextButton.icon(
              onPressed: () => ref
                  .read(contratosControllerProvider(session.role).notifier)
                  .load(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ),
          data: (contracts) {
            if (contracts == null) {
              return const AppStatePanel(
                icon: Icons.description_outlined,
                title: 'Detalle no disponible',
                message: 'No fue posible consultar el contrato.',
              );
            }
            final contract =
                contracts.where((item) => item.id == contratoId).firstOrNull;
            if (contract == null) {
              return const AppStatePanel(
                icon: Icons.search_off_outlined,
                title: 'Contrato no disponible',
                message: '',
              );
            }
            return _content(context, ref, contract, session.role);
          },
        );
      },
    );
  }

  Widget _content(
    BuildContext context,
    WidgetRef ref,
    ContratoModel contract,
    UserRole role,
  ) {
    final canEdit =
        role != UserRole.asesor || contract.assignedToCurrentAdvisor;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBackButton(
            label: 'Contratos',
            onPressed: () => context.go('/contratos'),
          ),
          AppPageHeader(
            eyebrow: 'Contrato ${contract.folio}',
            title: contract.servicioNombre,
            description:
                '${contract.clienteNombre} · Creado el ${_date(contract.creadoEn)}',
            actions: [
              if (canEdit && AppEnv.demoMode)
                OutlinedButton.icon(
                  onPressed: () =>
                      _showEditDialog(context, ref, role, contract),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
              OutlinedButton.icon(
                onPressed: () {
                  final payment = PagosDemoFixtures.payments
                      .where((item) => item.contratoId == contract.id)
                      .firstOrNull;
                  context.go(payment == null ? '/pagos' : '/pagos/${payment.id}');
                },
                icon: const Icon(Icons.credit_card_outlined),
                label: const Text('Ver pagos'),
              ),
            ],
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 1000;
              return Wrap(
                spacing: AppTheme.space4,
                runSpacing: AppTheme.space4,
                crossAxisAlignment: WrapCrossAlignment.start,
                children: [
                  SizedBox(
                    width: compact
                        ? constraints.maxWidth
                        : constraints.maxWidth - 336,
                    child: _infoCard(context, contract),
                  ),
                  SizedBox(
                    width: compact ? constraints.maxWidth : 320,
                    child: _observationsCard(context, contract),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppTheme.space4),
          _economicSummary(context, contract),
          const SizedBox(height: AppTheme.space4),
          _paymentCalendar(context, contract),
          const SizedBox(height: AppTheme.space4),
          _dispersionCard(context, contract),
          if (contract.servicioId == 50) ...[
            const SizedBox(height: AppTheme.space4),
            _penaltiesCard(context, ref, role, contract, canEdit),
          ],
        ],
      ),
    );
  }

  Widget _infoCard(BuildContext context, ContratoModel contract) => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Información del contrato',
                style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: AppTheme.space6),
            Wrap(
              spacing: AppTheme.space8,
              runSpacing: AppTheme.space5,
              children: [
                _field('Cliente', contract.clienteNombre),
                _field('Asesor', contract.asesorNombre),
                _field('Servicio', contract.servicioNombre),
                _field('Folio', contract.folio),
                _field('Fecha de contrato', _date(contract.fechaContrato)),
                _field('Estado contractual', contract.estadoNombre),
                _field('Cantidad de pagos',
                    contract.cantidadPagos?.toString() ?? 'No especificada'),
              ],
            ),
            const SizedBox(height: AppTheme.space4),
            Align(
              alignment: Alignment.centerLeft,
              child: AppBadge(
                label: contract.estadoNombre,
                tone: _tone(contract.estadoNombre),
              ),
            ),
          ],
        ),
      );

  Widget _observationsCard(BuildContext context, ContratoModel contract) =>
      _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Observaciones',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.space3),
            Text(contract.observaciones?.trim().isNotEmpty == true
                ? contract.observaciones!
                : 'Sin observaciones registradas.'),
            const SizedBox(height: AppTheme.space4),
            Text('Creado el ${_date(contract.creadoEn)}',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );

  Widget _economicSummary(BuildContext context, ContratoModel contract) {
    final payments = PagosDemoFixtures.payments
        .where((item) => item.contratoId == contract.id)
        .toList();
    final monthly = contract.montoMensual == null
        ? payments.firstOrNull?.monto ?? Decimal.zero
        : Decimal.parse(contract.montoMensual!);
    final count = contract.cantidadPagos ??
        payments.firstOrNull?.cantidadPagos ??
        1;
    final total = contract.totalPagar == null
        ? monthly * Decimal.fromInt(count)
        : Decimal.parse(contract.totalPagar!);
    final paid = payments
        .where((item) => item.estado == 'Validado')
        .fold<Decimal>(Decimal.zero, (sum, item) => sum + item.monto);
    final balance = contract.saldoPendiente == null
        ? total - paid
        : Decimal.parse(contract.saldoPendiente!);
    return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Resumen económico',
                style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: AppTheme.space6),
            Wrap(
              spacing: AppTheme.space8,
              runSpacing: AppTheme.space4,
              children: [
                _field('Total a pagar', MoneyFormatter.format(total)),
                _field('Monto mensual', MoneyFormatter.format(monthly)),
                _field('Saldo pendiente', MoneyFormatter.format(balance)),
              ],
            ),
          ],
        ),
      );
  }

  Widget _paymentCalendar(BuildContext context, ContratoModel contract) {
    final payments = PagosDemoFixtures.payments
        .where((item) => item.contratoId == contract.id)
        .toList();
    final count = contract.cantidadPagos ??
        payments.map((item) => item.cantidadPagos ?? 0).fold<int>(
              0,
              (maximum, value) => maximum > value ? maximum : value,
            );
    if (count == 0) {
      return _card(child: const Text('No hay mensualidades configuradas.'));
    }
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Calendario de mensualidades',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppTheme.space2),
          const Text('Consulta qué pagos están cubiertos y cuáles faltan.'),
          const Divider(height: AppTheme.space6),
          Wrap(
            spacing: AppTheme.space3,
            runSpacing: AppTheme.space3,
            children: [
              for (var number = 1; number <= count; number++)
                _paymentCalendarItem(context, number, payments),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paymentCalendarItem(
    BuildContext context,
    int number,
    List<PagoModel> payments,
  ) {
    final payment = payments
        .where((item) => item.numeroPago == number)
        .firstOrNull;
    final state = payment?.estado ?? 'Pendiente';
    final tone = state == 'Validado'
        ? AppBadgeTone.success
        : state.startsWith('Pendiente')
            ? AppBadgeTone.warning
            : AppBadgeTone.info;
    return SizedBox(
      width: 148,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mensualidad $number',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppTheme.space1),
          AppBadge(label: state, tone: tone),
          if (payment != null)
            Text(MoneyFormatter.format(payment.monto),
                style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _dispersionCard(BuildContext context, ContratoModel contract) {
    final payment = ComisionesDemoFixtures.payments
        .where((item) => item.contractId == contract.id)
        .firstOrNull;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Dispersión de recursos',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppTheme.space2),
          const Text('Detalle de comisiones asociado al contrato (solo lectura).'),
          const Divider(height: AppTheme.space6),
          if (payment == null)
            const Text('No hay una dispersiÃ³n asociada a este contrato.')
          else
            for (final line in payment.snapshot)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.space3),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(line.concept,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(line.receiverName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppTheme.muted)),
                        ],
                      ),
                    ),
                    AppBadge(label: line.status, tone: line.status == 'Dispersada'
                        ? AppBadgeTone.success
                        : AppBadgeTone.warning),
                    const SizedBox(width: AppTheme.space3),
                    Text(MoneyFormatter.format(line.amount),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _penaltiesCard(
    BuildContext context,
    WidgetRef ref,
    UserRole role,
    ContratoModel contract,
    bool canEdit,
  ) {
    final penalties = ref
        .read(contratosControllerProvider(role).notifier)
        .penaltiesFor(contract.id);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppTheme.space3,
            runSpacing: AppTheme.space2,
            children: [
              Text('Penalizaciones',
                  style: Theme.of(context).textTheme.titleLarge),
              FilledButton.icon(
                onPressed: AppEnv.demoMode && canEdit
                    ? () => _showPenaltyDialog(context, ref, role, contract)
                    : null,
                icon: const Icon(Icons.add),
                label: const Text('Registrar penalización'),
              ),
            ],
          ),
          const Divider(height: AppTheme.space6),
          if (penalties.isEmpty)
            const Text('No hay penalizaciones asignadas a este contrato.')
          else
            for (final penalty in penalties)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(penalty.concepto,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                    '${_date(penalty.fecha)}${penalty.observaciones == null ? '' : ' Â· ${penalty.observaciones}'}'),
                trailing: Wrap(
                  spacing: AppTheme.space2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AppBadge(label: penalty.estado, tone: AppBadgeTone.warning),
                    Text(MoneyFormatter.format(penalty.monto),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    UserRole role,
    ContratoModel contract,
  ) async {
    var observations = contract.observaciones ?? '';
    final key = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: 'Editar contrato',
        description: 'Solo los campos editables por el API.',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              key.currentState!.save();
              ref
                  .read(contratosControllerProvider(role).notifier)
                  .updateObservationsDemo(contract.id, observations.isEmpty ? null : observations);
              Navigator.pop(dialogContext);
            },
            child: const Text('Guardar'),
          ),
        ],
        child: Form(
          key: key,
          child: TextFormField(
            initialValue: observations,
            minLines: 4,
            maxLines: 7,
            decoration: const InputDecoration(labelText: 'Observaciones'),
            onSaved: (value) => observations = value?.trim() ?? '',
          ),
        ),
      ),
    );
  }

  Future<void> _showPenaltyDialog(
    BuildContext context,
    WidgetRef ref,
    UserRole role,
    ContratoModel contract,
  ) async {
    var concept = '';
    var amount = '';
    var observations = '';
    final key = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: 'Registrar penalización',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (!key.currentState!.validate()) return;
              key.currentState!.save();
              ref.read(contratosControllerProvider(role).notifier).createPenaltyDemo(
                    contractId: contract.id,
                    concepto: concept,
                    monto: _parseDecimal(amount)!,
                    fecha: DateTime.now(),
                    estado: 'Pendiente',
                    observaciones: observations.isEmpty ? null : observations,
                  );
              Navigator.pop(dialogContext);
            },
            child: const Text('Guardar'),
          ),
        ],
        child: Form(
          key: key,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Concepto o motivo *'),
                validator: _required,
                onSaved: (value) => concept = value?.trim() ?? '',
              ),
              const SizedBox(height: AppTheme.space3),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Monto *'),
                keyboardType: TextInputType.number,
                validator: (value) => _parseDecimal(value?.trim() ?? '') == null
                    ? 'Escribe un monto vÃ¡lido'
                    : null,
                onSaved: (value) => amount = value?.trim() ?? '',
              ),
              const SizedBox(height: AppTheme.space3),
              TextFormField(
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Observaciones'),
                onSaved: (value) => observations = value?.trim() ?? '',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(AppTheme.space5),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.line),
          borderRadius: BorderRadius.circular(AppTheme.radius),
          boxShadow: AppTheme.elevation,
        ),
        child: child,
      );

  Widget _field(String label, String value) => SizedBox(
        width: 240,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.muted)),
            const SizedBox(height: AppTheme.space1),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );

  AppBadgeTone _tone(String status) => switch (status) {
        'Activo' => AppBadgeTone.success,
        'En proceso' || 'Pago pendiente' => AppBadgeTone.warning,
        'Pausado' => AppBadgeTone.danger,
        _ => AppBadgeTone.neutral,
      };

  Decimal? _parseDecimal(String value) {
    try {
      return Decimal.parse(value);
    } on FormatException {
      return null;
    }
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo obligatorio' : null;

  String _date(DateTime date) => '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
