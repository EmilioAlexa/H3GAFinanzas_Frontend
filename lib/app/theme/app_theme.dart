import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const fontFamily = 'Inter';

  static const primary = Color(0xFF0F3B45);
  static const black = Color(0xFF011818);
  static const white = Color(0xFFFCFCFC);
  static const ink = Color(0xFF011818);
  static const inkSecondary = Color(0xFF1D3A40);
  static const muted = Color(0xFF566E73);
  static const faint = Color(0xFF7B9094);
  static const line = Color(0xFFE0E9EA);
  static const lineStrong = Color(0xFFCFDCDE);
  static const canvas = Color(0xFFF3F7F7);
  static const surface = Color(0xFFFCFCFC);
  static const surfaceSecondary = Color(0xFFF6F9F9);

  static const accent = Color(0xFF0F3B45);
  static const accentDark = Color(0xFF0A2A31);
  static const accentMid = Color(0xFF2C5761);
  static const accentSoft = Color(0xFFEAF1F2);

  static const secondary = Color(0xFF4ECAD4);
  static const secondaryDark = Color(0xFF1A7C85);
  static const secondaryHover = Color(0xFF13646C);
  static const secondarySoft = Color(0xFFEAF8F9);
  static const secondaryTint = Color(0xFFCDEFF2);

  static const gold = Color(0xFFFFCC00);
  static const goldHover = Color(0xFFF0BE00);
  static const goldDark = Color(0xFF7A5C00);
  static const goldSoft = Color(0xFFFFF8DB);

  static const successBase = Color(0xFF14A44D);
  static const success = Color(0xFF0C7034);
  static const successBackground = Color(0xFFE7F6EC);
  static const infoBase = Color(0xFF54B4D3);
  static const info = Color(0xFF1F6F8B);
  static const infoBackground = Color(0xFFEAF5FA);
  static const warningBase = Color(0xFFE4A11B);
  static const warning = Color(0xFF8A5A00);
  static const warningBackground = Color(0xFFFDF4E2);
  static const dangerBase = Color(0xFFDC4C64);
  static const danger = Color(0xFFB42A44);
  static const dangerBackground = Color(0xFFFCECEF);

  static const radius = 14.0;
  static const radiusSmall = 6.0;
  static const radiusField = 9.0;
  static const radiusDialog = 11.0;
  static const radiusLoginCard = 32.0;
  static const radiusPill = 999.0;

  static const space1 = 4.0;
  static const space2 = 8.0;
  static const space3 = 12.0;
  static const space4 = 16.0;
  static const space5 = 20.0;
  static const space6 = 24.0;
  static const space7 = 28.0;
  static const space8 = 32.0;
  static const space9 = 40.0;
  static const space10 = 48.0;

  static const shadowXs = BoxShadow(
    color: Color(0x0F0F3B45),
    blurRadius: 2,
    offset: Offset(0, 1),
  );
  static const shadow = BoxShadow(
    color: Color(0x0F0F3B45),
    blurRadius: 14,
    offset: Offset(0, 4),
  );
  static const shadowTight = BoxShadow(
    color: Color(0x0A011818),
    blurRadius: 2,
    offset: Offset(0, 1),
  );
  static const shadowMediumTint = BoxShadow(
    color: Color(0x0D011818),
    blurRadius: 4,
    offset: Offset(0, 2),
  );
  static const shadowMedium = BoxShadow(
    color: Color(0x1A0F3B45),
    blurRadius: 26,
    offset: Offset(0, 10),
  );
  static const shadowLargeTint = BoxShadow(
    color: Color(0x14011818),
    blurRadius: 16,
    offset: Offset(0, 8),
  );
  static const shadowLarge = BoxShadow(
    color: Color(0x2E0F3B45),
    blurRadius: 56,
    offset: Offset(0, 24),
  );
  static const focusRing = BoxShadow(
    color: Color(0x594ECAD4),
    spreadRadius: 3,
  );

  static List<BoxShadow> get elevation => const [shadowTight, shadow];
  static List<BoxShadow> get elevationMedium =>
      const [shadowMediumTint, shadowMedium];
  static List<BoxShadow> get elevationLarge =>
      const [shadowLargeTint, shadowLarge];

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      onPrimary: white,
      secondary: secondaryDark,
      onSecondary: white,
      surface: surface,
      onSurface: ink,
      error: danger,
      onError: white,
    );

    return ThemeData(
      useMaterial3: false,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      dividerColor: line,
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: ink,
        elevation: 0,
        iconTheme: IconThemeData(color: muted),
        titleTextStyle: TextStyle(
          color: ink,
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: muted,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle:
            TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 10),
        elevation: 8,
      ),
      textTheme: const TextTheme(
        displayLarge:
            TextStyle(fontSize: 32, height: 1.1, letterSpacing: -0.64),
        displayMedium:
            TextStyle(fontSize: 29, height: 1.12, letterSpacing: -0.58),
        displaySmall:
            TextStyle(fontSize: 26, height: 1.15, letterSpacing: -0.52),
        headlineLarge:
            TextStyle(fontSize: 27, height: 1.15, letterSpacing: -0.6),
        headlineMedium:
            TextStyle(fontSize: 24, height: 1.2, letterSpacing: -0.48),
        headlineSmall:
            TextStyle(fontSize: 20, height: 1.25, letterSpacing: -0.3),
        titleLarge: TextStyle(fontSize: 16, height: 1.3),
        titleMedium: TextStyle(fontSize: 14, height: 1.35),
        titleSmall: TextStyle(fontSize: 13, height: 1.4),
        bodyLarge: TextStyle(fontSize: 14, height: 1.45),
        bodyMedium: TextStyle(fontSize: 13, height: 1.45),
        bodySmall: TextStyle(fontSize: 12, height: 1.4),
        labelLarge: TextStyle(fontSize: 13, height: 1.4),
        labelMedium: TextStyle(fontSize: 12, height: 1.4),
        labelSmall: TextStyle(fontSize: 10, height: 1.35),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        labelStyle: const TextStyle(color: muted),
        hintStyle: const TextStyle(color: faint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusField),
          borderSide: const BorderSide(color: lineStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusField),
          borderSide: const BorderSide(color: lineStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusField),
          borderSide: const BorderSide(color: secondaryDark, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusField),
          borderSide: const BorderSide(color: danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusField),
          borderSide: const BorderSide(color: danger, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
        backgroundColor: secondaryDark,
        foregroundColor: white,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusField)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.disabled)
                      ? lineStrong
                      : states.contains(WidgetState.hovered)
                          ? secondaryHover
                          : secondaryDark),
              foregroundColor: WidgetStateProperty.resolveWith((states) =>
                  states.contains(WidgetState.disabled) ? muted : white))),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return surfaceSecondary;
            }
            if (states.contains(WidgetState.pressed)) return secondaryDark;
            if (states.contains(WidgetState.hovered)) return secondaryHover;
            return secondaryDark;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.disabled) ? muted : white),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return secondary.withValues(alpha: .22);
            }
            return Colors.transparent;
          }),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return 1;
            if (states.contains(WidgetState.hovered)) return 5;
            return 2;
          }),
          shadowColor: const WidgetStatePropertyAll(Color(0x382C5761)),
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusField),
            ),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          animationDuration: const Duration(milliseconds: 150),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.hovered) ? secondarySoft : surface),
          foregroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.hovered) ? secondaryHover : accent),
          side: WidgetStateProperty.resolveWith((states) => BorderSide(
                color: states.contains(WidgetState.hovered)
                    ? secondaryDark
                    : lineStrong,
              )),
          overlayColor: const WidgetStatePropertyAll(Color(0x0A4ECAD4)),
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusField),
            ),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          animationDuration: const Duration(milliseconds: 150),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.hovered)
                  ? secondaryHover
                  : secondaryDark),
          backgroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.hovered)
                  ? accentSoft
                  : Colors.transparent),
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          animationDuration: const Duration(milliseconds: 150),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: secondaryDark,
      ),
    );
  }
}
