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
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.accent,
            side: const BorderSide(color: AppTheme.lineStrong),
            minimumSize: const Size(48, 48),
          ),
          child: _content(context),
        ),
      AppButtonVariant.primary ||
      AppButtonVariant.danger ||
      AppButtonVariant.gold =>
        ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: switch (variant) {
              AppButtonVariant.danger => AppTheme.danger,
              AppButtonVariant.gold => AppTheme.gold,
              _ => AppTheme.secondaryDark,
            },
            foregroundColor: variant == AppButtonVariant.gold
                ? AppTheme.black
                : AppTheme.white,
            minimumSize: const Size(48, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                variant == AppButtonVariant.gold ? 6 : 9,
              ),
            ),
            elevation: variant == AppButtonVariant.gold ? 3 : 1,
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
