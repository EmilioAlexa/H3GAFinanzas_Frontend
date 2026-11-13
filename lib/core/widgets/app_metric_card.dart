import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

class AppMetricCard extends StatelessWidget {
  const AppMetricCard({
    required this.label,
    required this.value,
    this.detail,
    this.icon,
    this.tone = AppMetricTone.secondary,
    super.key,
  });

  final String label;
  final String value;
  final String? detail;
  final IconData? icon;
  final AppMetricTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      AppMetricTone.secondary => AppTheme.secondary,
      AppMetricTone.info => AppTheme.infoBase,
      AppMetricTone.warning => AppTheme.gold,
      AppMetricTone.accent => AppTheme.primary,
    };
    return Container(
      foregroundDecoration: BoxDecoration(
          border: Border(top: BorderSide(color: color, width: 2))),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.line),
        boxShadow: AppTheme.elevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              if (icon != null)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusField),
                  ),
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: Icon(icon, color: AppTheme.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.space3),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 20,
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (detail != null) ...[
            const SizedBox(height: AppTheme.space1),
            Text(detail!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.muted)),
          ],
        ],
      ),
    );
  }
}

enum AppMetricTone { secondary, info, warning, accent }
