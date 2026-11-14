import 'package:flutter/foundation.dart';

abstract final class AppEnv {
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _demoModeRequested = bool.fromEnvironment(
    'DEMO_MODE',
    defaultValue: false,
  );

  static const demoMode = kDebugMode && _demoModeRequested;

  /// Perfil con el que inicia el recorrido visual local.
  ///
  /// Ejemplos: administrador, administrador_financiero, asesor.
  static const demoRole = String.fromEnvironment(
    'DEMO_ROLE',
    defaultValue: 'administrador',
  );
}
