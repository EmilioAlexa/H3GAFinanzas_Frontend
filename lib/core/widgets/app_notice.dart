import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

enum AppNoticeType { info, success, warning, error }

class AppNotice extends StatelessWidget {
  const AppNotice({
    required this.text,
    this.type = AppNoticeType.info,
    super.key,
  });

  final String text;
  final AppNoticeType type;

  @override
  Widget build(BuildContext context) {
    final (foreground, background, icon) = switch (type) {
      AppNoticeType.info => (
          AppTheme.secondaryDark,
          AppTheme.secondarySoft,
          Icons.info_outline,
        ),
      AppNoticeType.success => (
          AppTheme.success,
          AppTheme.successBackground,
          Icons.check_circle_outline,
        ),
      AppNoticeType.warning => (
          AppTheme.warning,
          AppTheme.warningBackground,
          Icons.warning_amber_outlined,
        ),
      AppNoticeType.error => (
          AppTheme.danger,
          AppTheme.dangerBackground,
          Icons.error_outline,
        ),
    };

    return Semantics(
      liveRegion: type == AppNoticeType.error || type == AppNoticeType.success,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space3,
          vertical: AppTheme.space2,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppTheme.radiusField),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: AppTheme.space2),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
