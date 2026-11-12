import 'package:flutter/material.dart';
import 'app_button.dart';
import 'app_state_panel.dart';

enum AppContentStatus { loading, empty, error, success }

class AppAsyncState extends StatelessWidget {
  const AppAsyncState({
    required this.status,
    required this.child,
    this.title,
    this.message,
    this.onRetry,
    super.key,
  });

  final AppContentStatus status;
  final Widget child;
  final String? title;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => switch (status) {
        AppContentStatus.success => child,
        AppContentStatus.loading => Center(
            child: Semantics(
              label: 'Cargando contenido',
              child: const CircularProgressIndicator(),
            ),
          ),
        AppContentStatus.empty => AppStatePanel(
            icon: Icons.inbox_outlined,
            title: title ?? 'Sin información',
            message: message ?? 'Cuando haya información aparecerá aquí.',
          ),
        AppContentStatus.error => AppStatePanel(
            icon: Icons.error_outline,
            title: title ?? 'No se pudo cargar la información',
            message: message ?? 'Revisa tu conexión e inténtalo de nuevo.',
            action: onRetry == null
                ? null
                : AppButton(
                    label: 'Reintentar',
                    variant: AppButtonVariant.secondary,
                    expand: false,
                    onPressed: onRetry,
                  ),
          ),
      };
}
