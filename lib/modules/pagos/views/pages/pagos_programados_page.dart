import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/env.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_data_column.dart';
import '../../../../core/widgets/app_notice.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_responsive_collection.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../../auth/auth.dart';
import '../../controllers/pagos_controller.dart';
import '../../models/pago_programado_model.dart';

class PagosProgramadosPage extends ConsumerWidget {
  const PagosProgramadosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    if (session == null) {
      return const AppStatePanel(
          icon: Icons.lock_outline,
          title: 'Inicia sesión para continuar',
          message: 'Los pagos programados requieren sesión activa.');
    }
    final state = ref.watch(pagosControllerProvider(session.role));
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => AppStatePanel(
          icon: Icons.cloud_off_outlined,
          title: 'No se pudieron cargar los pagos programados',
          message: 'Inténtalo de nuevo.',
          action: TextButton.icon(
              onPressed: () => ref
                  .read(pagosControllerProvider(session.role).notifier)
                  .load(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'))),
      data: (value) => value == null
          ? const AppStatePanel(
              icon: Icons.link_off,
              title: 'Pagos programados sin conectar',
              message:
                  'La integración se realizará en B5; no se muestran fixtures en sesión real.')
          : _content(context, value.scheduled),
    );
  }

  Widget _content(BuildContext context, List<PagoProgramadoModel> rows) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space6),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AppPageHeader(
              eyebrow: 'Calendario de cobros',
              title: 'Pagos programados',
              description: 'Consulta cargos esperados asociados a contratos.',
              actions: [
                OutlinedButton.icon(
                    onPressed: () => context.go('/pagos'),
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Pagos recibidos')),
                if (AppEnv.demoMode)
                  FilledButton.icon(
                      onPressed: () => context.go('/pagos-programados/nuevo'),
                      icon: const Icon(Icons.add),
                      label: const Text('Programar pago')),
              ]),
          if (AppEnv.demoMode) ...[
            const AppNotice(
                text:
                    'Programar un pago representa un cobro esperado; no crea un pago real. Los cambios de esta maqueta solo viven en memoria.'),
            const SizedBox(height: AppTheme.space4),
          ],
          if (rows.isEmpty)
            const AppStatePanel(
                icon: Icons.event_busy,
                title: 'Sin pagos programados',
                message: 'No hay registros para este perfil.')
          else
            AppResponsiveCollection<PagoProgramadoModel>(
              rows: rows,
              columns: [
                AppDataColumn(
                    label: 'Cliente / Contrato',
                    value: (p) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.clienteNombre,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              Text(p.contratoFolio)
                            ])),
                AppDataColumn(
                    label: 'Servicio',
                    showOnMedium: false,
                    value: (p) => Text(p.servicioNombre)),
                AppDataColumn(
                    label: 'Pago', value: (p) => Text('N.º ${p.numeroPago}')),
                AppDataColumn(
                    label: 'Fecha esperada',
                    showOnMedium: false,
                    value: (p) => Text(p.fechaEsperada == null
                        ? '—'
                        : MoneyFormatter.formatDate(p.fechaEsperada!))),
                AppDataColumn(
                    label: 'Vencimiento',
                    value: (p) => Text(p.fechaVencimiento == null
                        ? '—'
                        : MoneyFormatter.formatDate(p.fechaVencimiento!))),
                AppDataColumn(
                    label: 'Monto esperado',
                    numeric: true,
                    value: (p) => Text(p.montoEsperado == null
                        ? 'Sin monto'
                        : MoneyFormatter.format(p.montoEsperado!))),
                AppDataColumn(
                    label: 'Estado',
                    value: (p) => AppBadge(
                        label: p.estado,
                        tone: p.estado == 'Cubierto'
                            ? AppBadgeTone.success
                            : AppBadgeTone.warning)),
              ],
              compactCardBuilder: (context, p) => _card(context, p),
            ),
        ]),
      );

  Widget _card(BuildContext context, PagoProgramadoModel p) => Container(
        padding: const EdgeInsets.all(AppTheme.space4),
        decoration: BoxDecoration(
            border: Border.all(color: AppTheme.line),
            borderRadius: BorderRadius.circular(AppTheme.radius)),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
                child: Text(p.clienteNombre,
                    style: const TextStyle(fontWeight: FontWeight.w700))),
            AppBadge(
                label: p.estado,
                tone: p.estado == 'Cubierto'
                    ? AppBadgeTone.success
                    : AppBadgeTone.warning)
          ]),
          Text('${p.contratoFolio} · ${p.servicioNombre}'),
          const Divider(height: AppTheme.space4),
          Text('Pago número ${p.numeroPago}'),
          Text(
              'Esperado: ${p.fechaEsperada == null ? '—' : MoneyFormatter.formatDate(p.fechaEsperada!)}'),
          Text(
              'Vencimiento: ${p.fechaVencimiento == null ? '—' : MoneyFormatter.formatDate(p.fechaVencimiento!)}'),
          Text(
              'Monto esperado: ${p.montoEsperado == null ? 'Sin monto' : MoneyFormatter.format(p.montoEsperado!)}'),
          Text('Pagos registrados: ${p.pagosRegistrados}'),
        ]),
      );
}
