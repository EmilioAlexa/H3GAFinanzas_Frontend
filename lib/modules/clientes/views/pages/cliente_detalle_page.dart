import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/config/env.dart';
import '../../../../core/network/api_error_model.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/responsive/window_size_class.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../../auth/auth.dart';
import '../../../contratos/controllers/contratos_controller.dart';
import '../../../contratos/models/contrato_model.dart';
import '../../../pagos/controllers/pagos_controller.dart';
import '../../../pagos/models/pago_model.dart';
import '../../controllers/clientes_controller.dart';
import '../../models/cliente_model.dart';

class ClienteDetallePage extends ConsumerWidget {
  const ClienteDetallePage({required this.clienteId, super.key});

  final String clienteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return auth.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const AppStatePanel(
        icon: Icons.person_off_outlined,
        title: 'No se pudo cargar la sesión',
        message: 'Vuelve a iniciar sesión para consultar el cliente.',
      ),
      data: (session) {
        if (session == null) {
          return const AppStatePanel(
            icon: Icons.lock_outline,
            title: 'Inicia sesión para continuar',
            message: 'El detalle requiere una sesión activa.',
          );
        }
        if (!AppEnv.demoMode) {
          return ref.watch(clienteDetalleProvider(clienteId)).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => AppStatePanel(
                    icon: Icons.error_outline,
                    title: 'Cliente no disponible',
                    message: ApiErrorModel.fromObject(error).message),
                data: (client) =>
                    _page(context, client, const [], const [], isReal: true),
              );
        }
        return ref.watch(clientesControllerProvider(session.role)).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => AppStatePanel(
                icon: Icons.cloud_off_outlined,
                title: 'No se pudo cargar el cliente',
                message: 'Inténtalo de nuevo.',
                action: TextButton.icon(
                  onPressed: () => ref
                      .read(clientesControllerProvider(session.role).notifier)
                      .load(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ),
              data: (clients) {
                if (clients == null) {
                  return const AppStatePanel(
                    icon: Icons.people_outline,
                    title: 'Sin información disponible',
                    message: 'No fue posible consultar el detalle del cliente.',
                  );
                }
                final client =
                    clients.where((item) => item.id == clienteId).firstOrNull;
                if (client == null) {
                  return const AppStatePanel(
                    icon: Icons.person_search_outlined,
                    title: 'Cliente no disponible',
                    message: '',
                  );
                }
                final contracts = ref
                        .watch(contratosControllerProvider(session.role))
                        .valueOrNull ??
                    const <ContratoModel>[];
                final payments = ref
                        .watch(pagosControllerProvider(session.role))
                        .valueOrNull
                        ?.payments ??
                    const <PagoModel>[];
                return _page(context, client, contracts, payments);
              },
            );
      },
    );
  }

  Widget _page(BuildContext context, ClienteModel client,
      List<ContratoModel> contracts, List<PagoModel> payments,
      {bool isReal = false}) {
    final clientContracts =
        contracts.where((contract) => contract.clienteId == client.id).toList();
    final contractIds = clientContracts.map((contract) => contract.id).toSet();
    final clientPayments = payments
        .where((payment) => contractIds.contains(payment.contratoId))
        .toList();
    final metadata = client.demoMetadata;

    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context, client, metadata),
          const Material(
            color: AppTheme.canvas,
            child: TabBar(
              labelColor: AppTheme.ink,
              unselectedLabelColor: AppTheme.muted,
              indicatorColor: AppTheme.secondaryDark,
              dividerColor: AppTheme.line,
              isScrollable: true,
              tabs: [
                Tab(text: 'Resumen'),
                Tab(text: 'Servicios y contratos'),
                Tab(text: 'Pagos'),
                Tab(text: 'Historial'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _summary(
                    context, client, metadata, clientContracts, clientPayments,
                    isReal: isReal),
                isReal
                    ? _unavailableTab(Icons.description_outlined)
                    : _contractsTab(context, clientContracts),
                isReal
                    ? _unavailableTab(Icons.payments_outlined)
                    : _paymentsTab(context, clientPayments),
                isReal
                    ? _unavailableTab(Icons.history_outlined)
                    : _historyTab(context, clientContracts, clientPayments),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(
    BuildContext context,
    ClienteModel client,
    ClienteDemoMetadata? metadata,
  ) {
    final initials = _initials(client.nombreCompleto);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space6,
        AppTheme.space3,
        AppTheme.space6,
        AppTheme.space3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBackButton(
            label: 'Clientes',
            onPressed: () => context.go('/clientes'),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppTheme.accentSoft,
                foregroundColor: AppTheme.primary,
                child: Text(initials),
              ),
              const SizedBox(width: AppTheme.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cliente',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppTheme.secondaryDark,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppTheme.space1),
                    Text(
                      client.nombreCompleto,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppTheme.space2),
                    Wrap(
                      spacing: AppTheme.space2,
                      runSpacing: AppTheme.space1,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (metadata != null)
                          AppBadge(
                            label: metadata.status,
                            tone: switch (metadata.status) {
                              'Activo' => AppBadgeTone.success,
                              'Pausado' => AppBadgeTone.danger,
                              _ => AppBadgeTone.warning,
                            },
                          ),
                        if (metadata == null && client.pausado != null)
                          _statusBadge(client.pausado! ? 'Pausado' : 'Activo'),
                        if (metadata?.advisorName != null)
                          Text(
                            'Asesor: ${metadata!.advisorName}',
                            style: const TextStyle(color: AppTheme.muted),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summary(
          BuildContext context,
          ClienteModel client,
          ClienteDemoMetadata? metadata,
          List<ContratoModel> contracts,
          List<PagoModel> payments,
          {bool isReal = false}) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final expanded = Responsive.of(context) == WindowSizeClass.expandido;
          final info = _informationCard(context, client, metadata);
          final references = isReal
              ? _panel(context,
                  title: 'Referencias',
                  child: const Text('Información financiera aún no conectada.'))
              : _referencesCard(context, metadata, contracts, payments);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.space6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (expanded)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: info),
                      const SizedBox(width: AppTheme.space4),
                      Expanded(child: references),
                    ],
                  )
                else ...[
                  info,
                  const SizedBox(height: AppTheme.space4),
                  references,
                ],
                const SizedBox(height: AppTheme.space4),
                if (isReal)
                  _panel(context,
                      title: 'Trayectoria del cliente',
                      child: const Text(
                          'Información financiera aún no conectada.'))
                else
                  _trajectoryCard(context, contracts, payments),
              ],
            ),
          );
        },
      );

  Widget _informationCard(
    BuildContext context,
    ClienteModel client,
    ClienteDemoMetadata? metadata,
  ) =>
      _panel(
        context,
        title: 'Información general',
        child: Wrap(
          spacing: AppTheme.space6,
          runSpacing: AppTheme.space5,
          children: [
            _field('Nombre', client.nombre),
            _field('Apellido paterno', client.apellidoPaterno),
            _field('Apellido materno', client.apellidoMaterno),
            _field('Teléfono', client.telefono),
            _field('Correo electrónico', client.correoElectronico),
            _field('CURP', client.curp),
            _field('RFC', client.rfc),
            _field(
                'Fecha de ingreso',
                client.fechaIngreso == null
                    ? null
                    : _date(client.fechaIngreso!)),
            _field(
                'Fecha de nacimiento',
                client.fechaNacimiento == null
                    ? null
                    : _date(client.fechaNacimiento!)),
            _field('Dirección', client.direccion),
            _field('Asesor', metadata?.advisorName ?? client.asesorId),
            _field('Referido por', client.referidoPor),
            _field('Observaciones', client.observaciones),
          ],
        ),
      );

  Widget _referencesCard(
    BuildContext context,
    ClienteDemoMetadata? metadata,
    List<ContratoModel> contracts,
    List<PagoModel> payments,
  ) {
    final activeContract = contracts
        .where((contract) => contract.estadoNombre.toLowerCase() == 'activo')
        .firstOrNull;
    final firstPayment = payments.firstOrNull;
    return Column(
      children: [
        _panel(
          context,
          title: 'Resumen financiero',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _summaryLine('Contratos registrados', '${contracts.length}'),
              _summaryLine('Pagos registrados', '${payments.length}'),
              _summaryLine(
                'Último pago',
                firstPayment == null
                    ? 'No registrado'
                    : MoneyFormatter.format(firstPayment.monto),
              ),
              if (metadata?.service != null)
                _summaryLine('Servicio principal', metadata!.service!),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.space4),
        _panel(
          context,
          title: 'Accesos rápidos',
          child: Column(
            children: [
              _quickLink(
                context,
                icon: Icons.description_outlined,
                label: 'Contrato activo',
                route: activeContract == null
                    ? null
                    : '/contratos/${activeContract.id}',
              ),
              const Divider(),
              _quickLink(
                context,
                icon: Icons.calendar_month_outlined,
                label: 'Servicios',
                route: '/servicios',
              ),
              const Divider(),
              _quickLink(
                context,
                icon: Icons.credit_card_outlined,
                label: 'Historial de pagos',
                route:
                    firstPayment == null ? null : '/pagos/${firstPayment.id}',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _contractsTab(
    BuildContext context,
    List<ContratoModel> contracts,
  ) {
    if (contracts.isEmpty) {
      return _emptyTab(
        icon: Icons.business_center_outlined,
        title: 'Sin servicios o contratos registrados',
        message:
            'Este cliente aún no tiene ningún servicio o contrato registrado.',
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final contract in contracts) ...[
            _panel(
              context,
              title: contract.servicioNombre,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(contract.folio,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      _statusBadge(contract.estadoNombre),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space3),
                  Wrap(
                    spacing: AppTheme.space6,
                    runSpacing: AppTheme.space2,
                    children: [
                      _field(
                          'Fecha de contrato', _date(contract.fechaContrato)),
                      _field('Asesor', contract.asesorNombre),
                      _field('Pagos contratados',
                          contract.cantidadPagos?.toString()),
                      _field('Observaciones', contract.observaciones),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/contratos/${contract.id}'),
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Ver detalle del contrato'),
                    ),
                  ),
                ],
              ),
            ),
            if (contract != contracts.last)
              const SizedBox(height: AppTheme.space4),
          ],
        ],
      ),
    );
  }

  Widget _paymentsTab(BuildContext context, List<PagoModel> payments) {
    if (payments.isEmpty) {
      return _emptyTab(
        icon: Icons.payments_outlined,
        title: 'Sin pagos registrados',
        message: 'Este cliente aún no tiene ningún pago registrado.',
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final payment in payments) ...[
            _panel(
              context,
              title: payment.folio,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(payment.contratoFolio,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      _statusBadge(payment.estado),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space3),
                  Wrap(
                    spacing: AppTheme.space6,
                    runSpacing: AppTheme.space2,
                    children: [
                      _field('Servicio', payment.servicioNombre),
                      _field('Monto', MoneyFormatter.format(payment.monto)),
                      _field('Fecha de pago', _date(payment.fechaPago)),
                      _field('Método', payment.formaPago),
                      _field('Referencia', payment.referencia),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/pagos/${payment.id}'),
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Ver detalle del pago'),
                    ),
                  ),
                ],
              ),
            ),
            if (payment != payments.last)
              const SizedBox(height: AppTheme.space4),
          ],
        ],
      ),
    );
  }

  Widget _historyTab(
    BuildContext context,
    List<ContratoModel> contracts,
    List<PagoModel> payments,
  ) {
    final events = [
      for (final contract in contracts)
        _TimelineEntry(
          date: contract.fechaContrato,
          title: 'Contrato registrado',
          detail: '${contract.servicioNombre} · ${contract.folio}',
        ),
      for (final payment in payments)
        _TimelineEntry(
          date: payment.fechaPago,
          title: 'Pago ${payment.estado.toLowerCase()}',
          detail: '${MoneyFormatter.format(payment.monto)} · ${payment.folio}',
        ),
    ]..sort((a, b) => b.date.compareTo(a.date));
    if (events.isEmpty) {
      return _emptyTab(
        icon: Icons.history_outlined,
        title: 'Sin historial registrado',
        message: 'Aún no hay movimientos relacionados con este cliente.',
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space6),
      child: _panel(
        context,
        title: 'Historial del cliente',
        child: Column(
          children: [
            for (var index = 0; index < events.length; index++)
              _timelineItem(
                context,
                _date(events[index].date),
                events[index].title,
                events[index].detail,
                last: index == events.length - 1,
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyTab({
    required IconData icon,
    required String title,
    required String message,
  }) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space6),
        child: Center(
          child: AppStatePanel(icon: icon, title: title, message: message),
        ),
      );

  Widget _unavailableTab(IconData icon) => _emptyTab(
        icon: icon,
        title: 'Información no disponible',
        message: 'Esta sección aún no está conectada.',
      );

  Widget _trajectoryCard(
    BuildContext context,
    List<ContratoModel> contracts,
    List<PagoModel> payments,
  ) =>
      _panel(
        context,
        title: 'Trayectoria del cliente',
        child: Column(
          children: [
            for (final payment in payments)
              _timelineItem(
                context,
                _date(payment.fechaPago),
                'Pago ${payment.estado.toLowerCase()}',
                '${MoneyFormatter.format(payment.monto)} · ${payment.folio}',
              ),
            for (final contract in contracts)
              _timelineItem(
                context,
                _date(contract.fechaContrato),
                'Contrato registrado',
                '${contract.servicioNombre} · ${contract.folio}',
              ),
            if (contracts.isEmpty && payments.isEmpty)
              const Text(
                'Aún no hay movimientos registrados.',
                style: TextStyle(color: AppTheme.muted),
              ),
          ],
        ),
      );

  Widget _timelineItem(
    BuildContext context,
    String date,
    String title,
    String detail, {
    bool last = false,
  }) =>
      Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : AppTheme.space3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 104,
              child: Text(date,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 5),
              child: Icon(Icons.circle, size: 9, color: AppTheme.secondaryDark),
            ),
            const SizedBox(width: AppTheme.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(detail, style: const TextStyle(color: AppTheme.muted)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _quickLink(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String? route,
  }) =>
      ListTile(
        enabled: route != null,
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: route == null ? null : () => context.go(route),
      );

  Widget _statusBadge(String status) => AppBadge(
        label: status,
        tone: switch (status) {
          'Activo' || 'Validado' => AppBadgeTone.success,
          'Pausado' || 'Rechazado' => AppBadgeTone.danger,
          _ => AppBadgeTone.warning,
        },
      );

  Widget _panel(
    BuildContext context, {
    required String title,
    required Widget child,
  }) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.space5),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: AppTheme.line),
          boxShadow: AppTheme.elevation,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const Divider(height: AppTheme.space6),
            child,
          ],
        ),
      );

  Widget _summaryLine(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.space3),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
            ),
            Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _field(String label, String? value) => SizedBox(
        width: 240,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.muted)),
            const SizedBox(height: AppTheme.space1),
            Text(
              value == null || value.isEmpty
                  ? (AppEnv.demoMode ? 'No registrado' : 'No disponible')
                  : value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}'
        .toUpperCase();
  }

  String _date(DateTime date) => '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _TimelineEntry {
  const _TimelineEntry({
    required this.date,
    required this.title,
    required this.detail,
  });

  final DateTime date;
  final String title;
  final String detail;
}
