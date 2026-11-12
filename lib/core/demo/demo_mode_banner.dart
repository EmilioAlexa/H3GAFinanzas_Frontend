import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

class DemoModeBanner extends StatelessWidget {
  const DemoModeBanner({super.key});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space4,
          vertical: AppTheme.space2,
        ),
        color: AppTheme.warningBackground,
        child: Semantics(
          liveRegion: true,
          child: Row(
            children: [
              const Icon(Icons.science_outlined, color: AppTheme.warning),
              const SizedBox(width: AppTheme.space2),
              Expanded(
                child: Text(
                  'Modo demostración · datos y acciones son ficticios',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.warning,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
}
