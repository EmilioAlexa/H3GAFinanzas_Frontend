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

##  Estructura del Proyecto

```text
lib/
├── main.dart                   # Punto de entrada de la aplicación
├── config/                     # Configuración global (rutas, temas, entornos)
├── controllers/                # Lógica de negocio y gestión de estado (Controllers)
├── models/                     # Modelos de datos y mapeo DTO (Models)
├── views/                      # Pantallas, módulos y componentes UI (Views)
│   ├── auth/                   # Módulo de Login y Recuperación
│   ├── dashboard/              # Tablero principal adaptable
│   └── shared/                 # Widgets reutilizables, Shell y Layouts
├── services/                   # Cliente HTTP, API REST, almacenamiento local
├── guards/                     # Protecciones y filtros de navegación por rol
└── utils/                      # Formateadores, constantes y helpers generales

## Requisitos

- Flutter estable y Dart incluidos en Flutter.
- Backend accesible desde el dispositivo o navegador.
- Archivos locales `env/dev.json`, `env/staging.json` y `env/prod.json` con `API_BASE_URL`.

## Ejecutar en desarrollo

Para maquetar sin API puedes activar el modo de demostración. Solo funciona en compilaciones debug y permite elegir un rol de prueba; las acciones de recuperación de contraseña son simuladas y no modifican cuentas:

```powershell
flutter run -d chrome --dart-define=DEMO_MODE=true --dart-define-from-file=env/dev.json
flutter run -d <id-del-emulador> --dart-define=DEMO_MODE=true --dart-define-from-file=env/dev.json
```

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
