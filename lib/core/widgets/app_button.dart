import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, danger, gold }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.expand = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final Widget button = switch (variant) {
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: loading ? null : onPressed,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.hovered)
                    ? AppTheme.secondarySoft
                    : AppTheme.surface),
            foregroundColor: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.hovered)
                    ? AppTheme.secondaryHover
                    : AppTheme.accent),
            side: WidgetStateProperty.resolveWith((states) => BorderSide(
                  color: states.contains(WidgetState.hovered)
                      ? AppTheme.secondaryDark
                      : AppTheme.lineStrong,
                )),
            minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusField),
              ),
            ),
            animationDuration: const Duration(milliseconds: 150),
          ),
          child: _content(context),
        ),
      AppButtonVariant.primary ||
      AppButtonVariant.danger ||
      AppButtonVariant.gold =>
        ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return switch (variant) {
                  AppButtonVariant.danger => AppTheme.danger,
                  AppButtonVariant.gold => AppTheme.gold,
                  _ => AppTheme.secondaryDark,
                }
                    .withValues(alpha: .48);
              }
              if (states.contains(WidgetState.hovered)) {
                return switch (variant) {
                  AppButtonVariant.danger => const Color(0xFF96223A),
                  AppButtonVariant.gold => AppTheme.goldHover,
                  _ => AppTheme.secondaryHover,
                };
              }
              return switch (variant) {
                AppButtonVariant.danger => AppTheme.danger,
                AppButtonVariant.gold => AppTheme.gold,
                _ => AppTheme.secondaryDark,
              };
            }),
            foregroundColor: WidgetStatePropertyAll(
              variant == AppButtonVariant.gold
                  ? AppTheme.black
                  : AppTheme.white,
            ),
            minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  variant == AppButtonVariant.gold ? 6 : 9,
                ),
              ),
            ),
            elevation: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) return 1;
              if (states.contains(WidgetState.hovered)) return 5;
              return variant == AppButtonVariant.gold ? 3 : 2;
            }),
            shadowColor: const WidgetStatePropertyAll(Color(0x382C5761)),
            overlayColor: const WidgetStatePropertyAll(Color(0x0A4ECAD4)),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            animationDuration: const Duration(milliseconds: 150),
          ),
          child: _content(context),
        ),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _content(BuildContext context) => loading
      ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: variant == AppButtonVariant.gold
                ? AppTheme.black
                : AppTheme.white,
          ),
        )
      : Text(label, textAlign: TextAlign.center);
}
