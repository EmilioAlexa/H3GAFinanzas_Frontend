import 'package:flutter/material.dart';

abstract final class AppTheme {
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

  static const shadow = BoxShadow(
    color: Color(0x190F3B45),
    blurRadius: 14,
    offset: Offset(0, 4),
  );
  static const shadowMedium = BoxShadow(
    color: Color(0x1A0F3B45),
    blurRadius: 26,
    offset: Offset(0, 10),
  );
  static const shadowLarge = BoxShadow(
    color: Color(0x2E0F3B45),
    blurRadius: 56,
    offset: Offset(0, 24),
  );

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
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      dividerColor: line,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
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
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryDark,
          foregroundColor: white,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusField),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: secondaryDark,
          minimumSize: const Size(48, 48),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: secondaryDark,
      ),
    );
  }
}
