import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

class AppMetricCard extends StatefulWidget {
  const AppMetricCard({
    required this.label,
    required this.value,
    this.detail,
    this.icon,
    this.tone = AppMetricTone.secondary,
    this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final String? detail;
  final IconData? icon;
  final AppMetricTone tone;
  final VoidCallback? onTap;

  @override
  State<AppMetricCard> createState() => _AppMetricCardState();
}

class _AppMetricCardState extends State<AppMetricCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = switch (widget.tone) {
      AppMetricTone.secondary => AppTheme.secondary,
      AppMetricTone.info => AppTheme.infoBase,
      AppMetricTone.warning => AppTheme.gold,
      AppMetricTone.accent => AppTheme.primary,
    };

    return Semantics(
      button: widget.onTap != null,
      label: '${widget.label}: ${widget.value}',
      child: MouseRegion(
        cursor: widget.onTap == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _hovered ? -1 : 0, 0),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(color: AppTheme.line),
            boxShadow:
                _hovered ? AppTheme.elevation : const [AppTheme.shadowXs],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(AppTheme.radius),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radius),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.label,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: AppTheme.muted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                              if (widget.icon != null)
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: .12),
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusField),
                                  ),
                                  child: SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: Icon(
                                      widget.icon,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.space3),
                          Text(
                            widget.value,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontSize: 20,
                                  color: AppTheme.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          if (widget.detail != null) ...[
                            const SizedBox(height: AppTheme.space1),
                            Text(
                              widget.detail!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppTheme.muted),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        height: _hovered ? 3 : 2,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum AppMetricTone { secondary, info, warning, accent }
