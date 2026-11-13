import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_notice.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../../auth/auth.dart';
import '../../controllers/comisiones_controller.dart';
import '../../fixtures/comisiones_demo_fixtures.dart';
import '../../models/dispersion_receiver_model.dart';

class ReceptoresPage extends ConsumerWidget {
  const ReceptoresPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    if (session == null || session.role == UserRole.asesor) {
      return const AppStatePanel(
        icon: Icons.lock_outline,
        title: 'Acceso restringido',
        message: 'Solo los perfiles administrativos gestionan receptores.',
      );
    }
    final async = ref.watch(comisionesControllerProvider(session.role));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => AppStatePanel(
        icon: Icons.cloud_off_outlined,
        title: 'No se pudieron cargar los receptores',
        message: 'Inténtalo de nuevo.',
        action: TextButton(
          onPressed: () => ref
              .read(comisionesControllerProvider(session.role).notifier)
              .load(),
          child: const Text('Reintentar'),
        ),
      ),
      data: (state) {
        if (state == null) {
          return const AppStatePanel(
            icon: Icons.link_off,
            title: 'Receptores sin conectar',
            message: 'Se conectará en la etapa de integración de comisiones.',
          );
        }
        return ListView(
          padding: const EdgeInsets.all(AppTheme.space6),
          children: [
            AppPageHeader(
              title: 'Receptores de dispersión',
              description: 'Catálogo. No se guardan cambios en el backend.',
              actions: [
                FilledButton.icon(
                  onPressed: () => _showCreate(context, ref, session.role),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Agregar receptor'),
                ),
              ],
            ),
            const AppNotice(
              text: 'Las personas internas se eligen del catálogo de usuarios. '
                  'Solo el receptor externo usa nombre libre.',
            ),
            const SizedBox(height: AppTheme.space4),
            for (final receiver in state.receivers)
              Card(
                child: ListTile(
                  leading: Icon(receiver.external
                      ? Icons.business_outlined
                      : Icons.person_outline),
                  title: Text(receiver.name),
                  subtitle: Text(
                    '${receiver.concept} · ${receiver.role ?? (receiver.external ? 'Externo' : 'Usuario')}',
                  ),
                  trailing: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Chip(
                          label: Text(receiver.active ? 'Activo' : 'Inactivo')),
                      if (receiver.active)
                        IconButton(
                          tooltip: 'Desactivar ${receiver.name}',
                          icon: const Icon(Icons.person_off_outlined),
                          onPressed: () => _deactivate(
                            context,
                            ref,
                            session.role,
                            receiver,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _deactivate(
    BuildContext context,
    WidgetRef ref,
    UserRole role,
    DispersionReceiverModel receiver,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desactivar receptor'),
        content: Text('¿Desactivar a ${receiver.name} en la maqueta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      ref
          .read(comisionesControllerProvider(role).notifier)
          .deactivateReceiverDemo(receiver.id);
    } on StateError catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message.toString())),
        );
      }
    }
  }

  Future<void> _showCreate(
    BuildContext context,
    WidgetRef ref,
    UserRole role,
  ) async {
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => _CreateReceiverDialog(role: role),
    );
    if (created == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receptor agregado.')),
      );
    }
  }
}

class _CreateReceiverDialog extends ConsumerStatefulWidget {
  const _CreateReceiverDialog({required this.role});
  final UserRole role;

  @override
  ConsumerState<_CreateReceiverDialog> createState() =>
      _CreateReceiverDialogState();
}

class _CreateReceiverDialogState extends ConsumerState<_CreateReceiverDialog> {
  int? _conceptId;
  String? _userId;
  final _name = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final concept =
        ComisionesDemoFixtures.concepts.where((item) => item.id == _conceptId);
    final selectedConcept = concept.isEmpty ? null : concept.first;
    final controller =
        ref.read(comisionesControllerProvider(widget.role).notifier);
    final users = selectedConcept == null || selectedConcept.external
        ? <DispersionReceiverModel>[]
        : controller.activeReceiversFor(selectedConcept.id);
    return AlertDialog(
      title: const Text('Agregar receptor'),
      content: SizedBox(
        width: 420,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<int>(
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Concepto'),
            items: ComisionesDemoFixtures.concepts
                .map((item) =>
                    DropdownMenuItem(value: item.id, child: Text(item.name)))
                .toList(),
            onChanged: (value) => setState(() {
              _conceptId = value;
              _userId = null;
              _error = null;
            }),
          ),
          const SizedBox(height: AppTheme.space3),
          if (selectedConcept?.external == true)
            TextField(
              controller: _name,
              maxLength: 150,
              decoration: const InputDecoration(labelText: 'Nombre externo'),
            )
          else
            DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Usuario activo'),
              items: users
                  .where((item) => item.userId != null)
                  .map((item) => DropdownMenuItem(
                        value: item.userId,
                        child: Text('${item.name} · ${item.role ?? 'Usuario'}'),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _userId = value),
            ),
          if (_error != null) ...[
            const SizedBox(height: AppTheme.space2),
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _save, child: const Text('Agregar')),
      ],
    );
  }

  void _save() {
    if (_conceptId == null) {
      setState(() => _error = 'Selecciona un concepto.');
      return;
    }
    final concept = ComisionesDemoFixtures.concepts
        .firstWhere((item) => item.id == _conceptId);
    try {
      ref
          .read(comisionesControllerProvider(widget.role).notifier)
          .createReceiverDemo(
            conceptId: _conceptId!,
            userId: concept.external ? null : _userId,
            externalName: concept.external ? _name.text : null,
          );
      Navigator.pop(context, true);
    } on StateError catch (error) {
      setState(() => _error = error.message.toString());
    }
  }
}
