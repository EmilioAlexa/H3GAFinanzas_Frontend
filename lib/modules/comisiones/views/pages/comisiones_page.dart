import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/env.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/responsive/window_size_class.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_data_column.dart';
import '../../../../core/widgets/app_metric_card.dart';
import '../../../../core/widgets/app_notice.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_responsive_collection.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../../auth/auth.dart';
import '../../controllers/comisiones_controller.dart';
import '../../models/commission_payment_model.dart';
import '../../utils/commission_math.dart';

class ComisionesPage extends ConsumerStatefulWidget {
  const ComisionesPage({super.key});

  @override
  ConsumerState<ComisionesPage> createState() => _ComisionesPageState();
}

class _ComisionesPageState extends ConsumerState<ComisionesPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final session = auth.valueOrNull;
    if (auth.isLoading) return const Center(child: CircularProgressIndicator());
    if (session == null) {
      return const AppStatePanel(
        icon: Icons.lock_outline,
        title: 'Inicia sesión para continuar',
        message: 'Comisiones requiere una sesión activa.',
      );
    }
    final data = ref.watch(comisionesControllerProvider(session.role));
    return data.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => AppStatePanel(
        icon: Icons.cloud_off_outlined,
        title: 'No se pudieron cargar las comisiones',
        message: 'Inténtalo de nuevo.',
        action: TextButton.icon(
          onPressed: () => ref
              .read(comisionesControllerProvider(session.role).notifier)
              .load(),
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      ),
      data: (state) => state == null
          ? const AppStatePanel(
              icon: Icons.link_off,
              title: 'Comisiones sin conectar',
              message:
                  'Los datos reales se conectarán a los endpoints de comisiones en B7.',
            )
          : _content(context, state.payments, session.role),
    );
  }

  Widget _content(
    BuildContext context,
    List<CommissionPaymentModel> payments,
    UserRole role,
  ) {
    final isAdvisor = role == UserRole.asesor;
    final filtered = payments.where((payment) {
      final query = _query.trim().toLowerCase();
      return query.isEmpty ||
          payment.paymentFolio.toLowerCase().contains(query) ||
          payment.clientName.toLowerCase().contains(query) ||
          payment.contractFolio.toLowerCase().contains(query);
    }).toList();
    final paidTotal = payments.fold(
        Decimal.zero, (sum, payment) => sum + payment.paymentAmount);
    final advisorTotal = payments.fold(
      Decimal.zero,
      (sum, payment) => sum + _advisorAmount(payment),
    );
    final assignedTotal = payments.fold(
      Decimal.zero,
      (sum, payment) =>
          sum +
          payment.snapshot
              .fold(Decimal.zero, (part, line) => part + line.amount),
    );
    final imssTotal = payments.fold(
      Decimal.zero,
      (sum, payment) => sum + _amountForConcept(payment, 4),
    );
    final companyTotal = payments.fold(
      Decimal.zero,
      (sum, payment) => sum + _companyRemainder(payment),
    );
    final pendingMine = payments.fold(Decimal.zero, (sum, payment) {
      final advisor = payment.snapshot.where((item) => item.conceptId == 1);
      return sum +
          (advisor.isNotEmpty &&
                  advisor.first.status == 'Pendiente de dispersión'
              ? advisor.first.amount
              : Decimal.zero);
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AppPageHeader(
          eyebrow: isAdvisor ? 'Mis comisiones' : 'Dispersión de recursos',
          title: isAdvisor ? 'Mis comisiones' : 'Comisiones por destino',
          description: isAdvisor
              ? 'Consulta tu comisión y los movimientos asociados a tus contratos.'
              : 'Consulta la distribución de cada pago y administra la dispersión.',
          actions: [
            if (!isAdvisor)
              OutlinedButton.icon(
                onPressed: () => context.go('/comisiones/receptores'),
                icon: const Icon(Icons.people_alt_outlined),
                label: const Text('Receptores'),
              ),
          ],
        ),
        if (AppEnv.demoMode) ...[
          const AppNotice(
            text:
                'Muestra local. Los receptores, importes, conceptos e IDs son ficticios; las configuraciones y dispersiones no se envían al backend.',
          ),
          const SizedBox(height: AppTheme.space4),
        ],
        LayoutBuilder(builder: (context, constraints) {
          final compact = Responsive.classify(constraints.maxWidth) ==
              WindowSizeClass.compacto;
          final cards = isAdvisor
              ? [
                  AppMetricCard(
                      label: 'Mi comisión',
                      value: MoneyFormatter.format(advisorTotal),
                      detail: '${payments.length} pagos demo',
                      icon: Icons.account_balance_wallet_outlined),
                  AppMetricCard(
                      label: 'Pagos comisionables',
                      value: '${payments.length}',
                      detail: '${MoneyFormatter.format(paidTotal)} en pagos',
                      icon: Icons.receipt_long_outlined,
                      tone: AppMetricTone.info),
                  AppMetricCard(
                      label: 'Por dispersar',
                      value: MoneyFormatter.format(pendingMine),
                      detail: 'Importe de mi comisión pendiente',
                      icon: Icons.schedule_outlined,
                      tone: AppMetricTone.warning),
                ]
              : [
                  AppMetricCard(
                      label: 'Pagos del conjunto demo',
                      value: MoneyFormatter.format(paidTotal),
                      detail: '${payments.length} pagos con snapshot',
                      icon: Icons.bar_chart_outlined),
                  AppMetricCard(
                      label: 'Comisiones asignadas',
                      value: MoneyFormatter.format(assignedTotal),
                      detail: 'Suma de los destinos del conjunto demo',
                      icon: Icons.groups_outlined,
                      tone: AppMetricTone.info),
                  AppMetricCard(
                      label: 'IMSS',
                      value: MoneyFormatter.format(imssTotal),
                      detail: 'Solo servicios compatibles',
                      icon: Icons.account_balance_outlined,
                      tone: AppMetricTone.warning),
                  AppMetricCard(
                      label: 'Empresa (remanente)',
                      value: MoneyFormatter.format(companyTotal),
                      detail: 'Pago menos los importes asignados',
                      icon: Icons.business_outlined,
                      tone: AppMetricTone.accent),
                ];
          return Wrap(
            spacing: AppTheme.space3,
            runSpacing: AppTheme.space3,
            children: [
              for (final card in cards)
                SizedBox(
                  width: compact
                      ? constraints.maxWidth
                      : (constraints.maxWidth -
                              AppTheme.space3 * (cards.length > 3 ? 3 : 2)) /
                          (cards.length > 3 ? 4 : 3),
                  child: card,
                ),
            ],
          );
        }),
        const SizedBox(height: AppTheme.space4),
        _paymentList(context, filtered, isAdvisor),
      ]),
    );
  }

  Widget _paymentList(BuildContext context,
          List<CommissionPaymentModel> payments, bool isAdvisor) =>
      Container(
        padding: const EdgeInsets.all(AppTheme.space4),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.line),
          borderRadius: BorderRadius.circular(AppTheme.radius),
          boxShadow: AppTheme.elevation,
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          LayoutBuilder(builder: (context, constraints) {
            final compact = Responsive.classify(constraints.maxWidth) ==
                WindowSizeClass.compacto;
            final search = TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                labelText: 'Buscar cliente, pago o contrato',
                prefixIcon: Icon(Icons.search),
              ),
            );
            if (compact) return search;
            return Row(children: [Expanded(child: search)]);
          }),
          const Divider(height: AppTheme.space6),
          if (payments.isEmpty)
            const AppStatePanel(
              icon: Icons.search_off_outlined,
              title: 'No hay comisiones para mostrar',
              message: 'Ajusta la búsqueda o revisa el perfil activo.',
            )
          else
            AppResponsiveCollection<CommissionPaymentModel>(
              rows: payments,
              columns: [
                AppDataColumn(
                  label: 'Cliente / pago',
                  value: (payment) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(payment.clientName,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                          '${payment.paymentFolio} · ${payment.contractFolio}'),
                    ],
                  ),
                ),
                AppDataColumn(
                    label: 'Monto del pago',
                    value: (payment) =>
                        Text(MoneyFormatter.format(payment.paymentAmount))),
                if (isAdvisor)
                  AppDataColumn(
                      label: 'Mi comisión',
                      value: (payment) =>
                          Text(MoneyFormatter.format(_advisorAmount(payment)))),
                if (isAdvisor)
                  AppDataColumn(
                      label: 'Empresa (referencial)',
                      showOnMedium: false,
                      value: (payment) => Text(MoneyFormatter.format(
                          payment.paymentAmount - _advisorAmount(payment)))),
                if (!isAdvisor)
                  AppDataColumn(
                      label: 'Asesor',
                      value: (payment) => Text(MoneyFormatter.format(
                          _amountForConcept(payment, 1)))),
                if (!isAdvisor)
                  AppDataColumn(
                      label: 'IMSS',
                      showOnMedium: false,
                      value: (payment) => Text(payment.serviceName == 'APD'
                          ? 'No aplica'
                          : MoneyFormatter.format(
                              _amountForConcept(payment, 4)))),
                if (!isAdvisor)
                  AppDataColumn(
                      label: 'Empresa',
                      showOnMedium: false,
                      value: (payment) => Text(
                          MoneyFormatter.format(_companyRemainder(payment)))),
                AppDataColumn(
                    label: 'Estado', value: (payment) => _statusBadge(payment)),
                AppDataColumn(
                    label: '',
                    value: (payment) => const Icon(Icons.chevron_right)),
              ],
              compactCardBuilder: (context, payment) =>
                  _paymentCard(context, payment, isAdvisor),
              onRowTap: (payment) => context.go('/comisiones/${payment.id}'),
            ),
        ]),
      );

  Widget _paymentCard(
    BuildContext context,
    CommissionPaymentModel payment,
    bool isAdvisor,
  ) =>
      Container(
        padding: const EdgeInsets.all(AppTheme.space4),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.line),
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(payment.clientName,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          Text('${payment.paymentFolio} · ${payment.contractFolio}'),
          const SizedBox(height: AppTheme.space2),
          _line('Servicio', payment.serviceName),
          _line('Monto del pago', MoneyFormatter.format(payment.paymentAmount)),
          if (isAdvisor) ...[
            _line(
                'Mi comisión', MoneyFormatter.format(_advisorAmount(payment))),
            _line(
                'Empresa (referencial)',
                MoneyFormatter.format(
                    payment.paymentAmount - _advisorAmount(payment))),
          ] else ...[
            _line(
                'Asesor', MoneyFormatter.format(_amountForConcept(payment, 1))),
            _line(
                'IMSS',
                payment.serviceName == 'APD'
                    ? 'No aplica'
                    : MoneyFormatter.format(_amountForConcept(payment, 4))),
            _line('Empresa (remanente)',
                MoneyFormatter.format(_companyRemainder(payment))),
          ],
          const SizedBox(height: AppTheme.space2),
          Row(children: [
            _statusBadge(payment),
            const Spacer(),
            IconButton(
              tooltip: 'Ver detalle de ${payment.paymentFolio}',
              onPressed: () => context.go('/comisiones/${payment.id}'),
              icon: const Icon(Icons.chevron_right),
            ),
          ]),
        ]),
      );

  Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.only(top: AppTheme.space1),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 140, child: Text(label)),
          Expanded(child: Text(value)),
        ]),
      );

  Decimal _advisorAmount(CommissionPaymentModel payment) =>
      _amountForConcept(payment, 1);

  Decimal _amountForConcept(CommissionPaymentModel payment, int conceptId) =>
      payment.snapshot
          .where((item) => item.conceptId == conceptId)
          .fold(Decimal.zero, (sum, item) => sum + item.amount);

  Decimal _companyRemainder(CommissionPaymentModel payment) =>
      CommissionMath.remainderAmount(
        payment.paymentAmount,
        payment.snapshot.map((item) => item.amount),
      );

  AppBadge _statusBadge(CommissionPaymentModel payment) {
    final personal = payment.snapshot.where((item) => item.conceptId == 1);
    final dispersed = personal.isNotEmpty &&
        personal.every((item) => item.status == 'Dispersada');
    return AppBadge(
      label: dispersed ? 'Dispersada' : 'Pendiente de dispersión',
      tone: dispersed ? AppBadgeTone.success : AppBadgeTone.warning,
    );
  }
}
