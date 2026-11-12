import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';
import '../responsive/responsive.dart';

class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    required this.title,
    this.eyebrow,
    this.description,
    this.actions = const [],
    super.key,
  });

  final String title;
  final String? eyebrow;
  final String? description;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.space6),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = Responsive.isCompact(constraints.maxWidth);
            final heading = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[
                  Text(
                    eyebrow!.toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.secondaryDark,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppTheme.space2),
                ],
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (description != null) ...[
                  const SizedBox(height: AppTheme.space2),
                  Text(
                    description!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.muted,
                        ),
                  ),
                ],
              ],
            );
            if (actions.isEmpty) return heading;
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  heading,
                  const SizedBox(height: AppTheme.space4),
                  Wrap(
                      spacing: AppTheme.space2,
                      runSpacing: AppTheme.space2,
                      children: actions),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: heading),
                const SizedBox(width: AppTheme.space4),
                Flexible(
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: AppTheme.space2,
                    runSpacing: AppTheme.space2,
                    children: actions,
                  ),
                ),
              ],
            );
          },
        ),
      );
}
