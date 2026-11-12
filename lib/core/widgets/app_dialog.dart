import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

class AppDialog extends StatelessWidget {
  const AppDialog({
    required this.title,
    required this.child,
    this.description,
    this.actions = const [],
    this.maxWidth = 560,
    super.key,
  });

  final String title;
  final String? description;
  final Widget child;
  final List<Widget> actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: AppTheme.surface,
        insetPadding: const EdgeInsets.all(AppTheme.space4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusDialog),
          side: const BorderSide(color: AppTheme.line),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: MediaQuery.sizeOf(context).height * .9),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.space6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                if (description != null) ...[
                  const SizedBox(height: AppTheme.space2),
                  Text(description!,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppTheme.muted)),
                ],
                const SizedBox(height: AppTheme.space5),
                child,
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.space5),
                  Wrap(
                      alignment: WrapAlignment.end,
                      spacing: AppTheme.space2,
                      runSpacing: AppTheme.space2,
                      children: actions),
                ],
              ],
            ),
          ),
        ),
      );
}
