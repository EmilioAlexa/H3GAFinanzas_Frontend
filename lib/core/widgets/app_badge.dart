import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

enum AppBadgeTone { neutral, info, success, warning, danger, accent }

class AppBadge extends StatelessWidget {
  const AppBadge(
      {required this.label, this.tone = AppBadgeTone.neutral, super.key});

  final String label;
  final AppBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, icon) = switch (tone) {
      AppBadgeTone.neutral => (
          AppTheme.surfaceSecondary,
          AppTheme.muted,
          Icons.circle
        ),
      AppBadgeTone.info => (AppTheme.infoBackground, AppTheme.info, Icons.info),
      AppBadgeTone.success => (
          AppTheme.successBackground,
          AppTheme.success,
          Icons.check_circle
        ),
      AppBadgeTone.warning => (
          AppTheme.warningBackground,
          AppTheme.warning,
          Icons.warning_rounded
        ),
      AppBadgeTone.danger => (
          AppTheme.dangerBackground,
          AppTheme.danger,
          Icons.error
        ),
      AppBadgeTone.accent => (
          AppTheme.secondarySoft,
          AppTheme.secondaryDark,
          Icons.circle
        ),
    };

    return Semantics(
      label: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: 28),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: AppTheme.space2),
            Flexible(
              child: Text(
                label,
                softWrap: true,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
