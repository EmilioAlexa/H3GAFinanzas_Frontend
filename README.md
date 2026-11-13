# H3GA Finanzas

Aplicación multiplataforma (Web y Android) construida con **Flutter** para el sistema de gestión financiera **H3GA Finanzas**. Implementa una arquitectura modular **MVC (Model-View-Controller)** para garantizar mantenibilidad, escalabilidad y separación clara de responsabilidades.


##  Características Principales

- **Multiplataforma Nativa:** Soporte prioritario para **Flutter Web** y **Android** (iOS planificado a futuro).
- **Arquitectura Modular MVC:** Organización clara de capas (modelos, controladores, vistas, servicios y adaptadores).
- **Gestión de Sesión y Autenticación:** Cliente HTTP centralizado, manejo global de errores, persistencia de sesión y perfil de usuario.
- **Seguridad y Accesos:** Guards de navegación según el rol del usuario autenticado.
- **Shell Adaptable:** Layout responsive adaptable a pantallas de escritorio (Web) y dispositivos móviles (Android).

##  Tecnologías Utilizadas

- **Framework:** [Flutter](https://flutter.dev/) (SDK >= 3.0.0)
- **Lenguaje:** [Dart](https://dart.dev/)
- **Estilo Arquitectónico:** MVC Modular
- **Generación de Código:** `build_runner`
- **Pruebas y Análisis:** `flutter analyze`, `flutter test`

## Estructura del proyecto

```text
lib/
  main.dart
  app/          # App, router, theme y configuracion del entorno
  core/         # Network, storage, platform, responsive, widgets y shell
  modules/      # auth, dashboard, clientes, contratos, pagos, validacion,
                # comisiones, cortes, prenomina, reportes y usuarios
    <modulo>/models/
    <modulo>/repositories/
    <modulo>/controllers/
    <modulo>/views/pages/
    <modulo>/views/widgets/
    <modulo>/<modulo>.dart
```

`README.md` y el codigo del proyecto son independientes de `docs/`, que permanece local e ignorado por Git.

## Requisitos

- Flutter estable y Dart incluidos en Flutter.
- Android SDK Platform API 36 para compilar el APK debug/release.
- Backend accesible desde el dispositivo o navegador.
- Archivos locales `env/dev.json`, `env/staging.json` y `env/prod.json` con `API_BASE_URL`.

## Ejecutar en desarrollo

Para revisar el maquetado sin API activa el modo visual local. Solo funciona en debug. El rol no se elige desde la interfaz: se define con `DEMO_ROLE`.

```powershell
flutter run -d chrome --dart-define=DEMO_MODE=true --dart-define=DEMO_ROLE=administrador_financiero --dart-define-from-file=env/dev.json
flutter run -d <id-del-emulador> --dart-define=DEMO_MODE=true --dart-define=DEMO_ROLE=administrador --dart-define-from-file=env/dev.json
```

Valores admitidos: `administrador`, `administrador_financiero` y `asesor`. El OTP local de recuperación para pruebas es `482916`; no se muestra en la interfaz ni modifica cuentas.

Para probar el login real contra la API de desarrollo, ejecuta sin `DEMO_MODE`:

```powershell
flutter pub get
flutter run -d chrome --dart-define-from-file=env/dev.json
flutter run -d android --dart-define-from-file=env/dev.json
```

Para Android Emulator, configura el URL dev como `http://10.0.2.2:3000/api`.

## Staging y producción

```powershell
flutter run -d chrome --dart-define-from-file=env/staging.json
flutter run -d android --dart-define-from-file=env/staging.json
flutter build web --release --dart-define-from-file=env/prod.json
flutter build apk --release --dart-define-from-file=env/prod.json
```

Publica el contenido de `build/web/` en el hosting estático de DigitalOcean. El APK queda en `build/app/outputs/flutter-apk/app-release.apk`.

Para ejecutar en iOS después de habilitar esa plataforma, primero genera el target con `flutter create --platforms=ios .` y usa `flutter run -d ios --dart-define-from-file=env/<entorno>.json`.

Los valores `env/*.json` son locales y están ignorados por Git. Los archivos `env/*.json.example` sirven como plantilla y no contienen credenciales.
