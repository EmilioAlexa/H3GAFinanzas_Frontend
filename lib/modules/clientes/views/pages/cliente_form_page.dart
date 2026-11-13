import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/env.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/responsive/window_size_class.dart';
import '../../../../core/widgets/app_notice.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_state_panel.dart';
import '../../../auth/auth.dart';
import '../../controllers/clientes_controller.dart';
import '../../models/cliente_model.dart';

class ClienteFormPage extends ConsumerWidget {
  const ClienteFormPage({this.clienteId, super.key});

  final String? clienteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return auth.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const AppStatePanel(
        icon: Icons.person_off_outlined,
        title: 'No se pudo cargar la sesión',
        message: 'Vuelve a iniciar sesión para continuar.',
      ),
      data: (session) {
        if (session == null) {
          return const AppStatePanel(
            icon: Icons.lock_outline,
            title: 'Inicia sesión para continuar',
            message: 'El formulario requiere una sesión activa.',
          );
        }
        final state = ref.watch(clientesControllerProvider(session.role));
        return state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => AppStatePanel(
            icon: Icons.cloud_off_outlined,
            title: 'No se pudo cargar el formulario',
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
            if (!AppEnv.demoMode || clients == null) {
              return const AppStatePanel(
                icon: Icons.edit_note_outlined,
                title: 'Formulario sin conectar',
                message:
                    'En modo real, el alta y la edición se conectarán a la API en la etapa B4.',
              );
            }

            ClienteModel? client;
            if (clienteId != null) {
              final matches = clients.where((item) => item.id == clienteId);
              if (matches.isEmpty) {
                return const AppStatePanel(
                  icon: Icons.person_search_outlined,
                  title: 'Cliente no disponible',
                  message: '',
                );
              }
              client = matches.first;
            }

            final canCreate =
                clienteId == null && session.role == UserRole.asesor;
            final canEdit = client != null &&
                (session.role == UserRole.administrador ||
                    (session.role == UserRole.asesor &&
                        (client.demoMetadata?.assignedToCurrentAdvisor ??
                            false)));
            if (!canCreate && !canEdit) {
              return const AppStatePanel(
                icon: Icons.lock_outline,
                title: 'No tienes permiso para esta acción',
                message:
                    'El API permite registrar clientes al asesor y editar al administrador o al asesor asignado.',
              );
            }

            return _form(context, ref, session.role, client);
          },
        );
      },
    );
  }

  Widget _form(
    BuildContext context,
    WidgetRef ref,
    UserRole role,
    ClienteModel? client,
  ) {
    final formKey = GlobalKey<FormState>();
    var nombre = client?.nombre ?? '';
    var apellidoPaterno = client?.apellidoPaterno ?? '';
    var apellidoMaterno = client?.apellidoMaterno ?? '';
    var telefono = client?.telefono ?? '';
    var correoElectronico = client?.correoElectronico ?? '';
    var curp = client?.curp ?? '';
    var rfc = client?.rfc ?? '';
    final editing = client != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = Responsive.of(context) == WindowSizeClass.compacto;
        final contentWidth = constraints.maxWidth.clamp(0, 880).toDouble();
        final fieldWidth =
            compact ? contentWidth : (contentWidth - AppTheme.space4) / 2;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.space6),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppPageHeader(
                      eyebrow: editing ? 'Directorio · edición' : 'Directorio',
                      title: editing ? 'Editar cliente' : 'Nuevo cliente',
                      description:
                          'Completa únicamente los campos definidos por el API de Clientes.',
                    ),
                    const AppNotice(
                      type: AppNoticeType.info,
                      text: '',
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.space5),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radius),
                        border: Border.all(color: AppTheme.line),
                        boxShadow: AppTheme.elevation,
                      ),
                      child: Wrap(
                        spacing: AppTheme.space4,
                        runSpacing: AppTheme.space3,
                        children: [
                          SizedBox(
                            width: fieldWidth,
                            child: TextFormField(
                              initialValue: nombre,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              decoration:
                                  const InputDecoration(labelText: 'Nombre *'),
                              validator: _requiredValidator,
                              onSaved: (value) => nombre = value!.trim(),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: TextFormField(
                              initialValue: apellidoPaterno,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Apellido paterno *',
                              ),
                              validator: _requiredValidator,
                              onSaved: (value) =>
                                  apellidoPaterno = value!.trim(),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: TextFormField(
                              initialValue: apellidoMaterno,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Apellido materno',
                              ),
                              onSaved: (value) =>
                                  apellidoMaterno = value?.trim() ?? '',
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: TextFormField(
                              initialValue: telefono,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Teléfono',
                              ),
                              onSaved: (value) =>
                                  telefono = value?.trim() ?? '',
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: TextFormField(
                              initialValue: correoElectronico,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Correo electrónico',
                              ),
                              validator: _emailValidator,
                              onSaved: (value) =>
                                  correoElectronico = value?.trim() ?? '',
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: TextFormField(
                              initialValue: curp,
                              textCapitalization: TextCapitalization.characters,
                              textInputAction: TextInputAction.next,
                              maxLength: 18,
                              decoration: const InputDecoration(
                                labelText: 'CURP',
                                helperText: '18 caracteres si se captura',
                              ),
                              validator: _curpValidator,
                              onSaved: (value) =>
                                  curp = value?.trim().toUpperCase() ?? '',
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: TextFormField(
                              initialValue: rfc,
                              textCapitalization: TextCapitalization.characters,
                              textInputAction: TextInputAction.done,
                              maxLength: 13,
                              decoration: const InputDecoration(
                                labelText: 'RFC',
                                helperText: 'Hasta 13 caracteres',
                              ),
                              validator: _rfcValidator,
                              onSaved: (value) =>
                                  rfc = value?.trim().toUpperCase() ?? '',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: AppTheme.space2,
                      runSpacing: AppTheme.space2,
                      children: [
                        OutlinedButton(
                          onPressed: () => context.go(
                            editing ? '/clientes/${client.id}' : '/clientes',
                          ),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton.icon(
                          onPressed: () {
                            if (!formKey.currentState!.validate()) return;
                            formKey.currentState!.save();
                            final controller = ref.read(
                              clientesControllerProvider(role).notifier,
                            );
                            if (editing) {
                              controller.updateDemo(
                                ClienteModel(
                                  id: client.id,
                                  nombre: nombre,
                                  apellidoPaterno: apellidoPaterno,
                                  apellidoMaterno: _nullable(apellidoMaterno),
                                  telefono: _nullable(telefono),
                                  correoElectronico:
                                      _nullable(correoElectronico),
                                  curp: _nullable(curp),
                                  rfc: _nullable(rfc),
                                  demoMetadata: client.demoMetadata,
                                ),
                              );
                              context.go('/clientes/${client.id}');
                            } else {
                              final created = controller.createDemo(
                                nombre: nombre,
                                apellidoPaterno: apellidoPaterno,
                                apellidoMaterno: _nullable(apellidoMaterno),
                                telefono: _nullable(telefono),
                                correoElectronico: _nullable(correoElectronico),
                                curp: _nullable(curp),
                                rfc: _nullable(rfc),
                              );
                              context.go('/clientes/${created.id}');
                            }
                          },
                          icon: const Icon(Icons.save_outlined),
                          label: Text(
                              editing ? 'Guardar cambios' : 'Crear cliente'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String? _requiredValidator(String? value) =>
      value == null || value.trim().isEmpty
          ? 'Este campo es obligatorio.'
          : null;

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())
        ? null
        : 'Escribe un correo electrónico válido.';
  }

  String? _curpValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value.trim().length == 18
        ? null
        : 'La CURP debe tener exactamente 18 caracteres.';
  }

  String? _rfcValidator(String? value) =>
      value != null && value.trim().length > 13
          ? 'El RFC admite hasta 13 caracteres.'
          : null;

  String? _nullable(String value) => value.trim().isEmpty ? null : value.trim();
}
