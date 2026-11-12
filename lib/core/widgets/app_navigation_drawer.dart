import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

class AppNavigationDrawer extends StatelessWidget {
  const AppNavigationDrawer({
    required this.destinations,
    this.header,
    this.footer,
    super.key,
  });

  final Widget? header;
  final List<Widget> destinations;
  final Widget? footer;

  @override
  Widget build(BuildContext context) => Drawer(
        backgroundColor: AppTheme.primary,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (header != null) ...[
                Padding(
                  padding: const EdgeInsets.all(AppTheme.space5),
                  child: header,
                ),
                const Divider(color: AppTheme.accentMid, height: 1),
              ],
              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppTheme.space3),
                  children: destinations,
                ),
              ),
              if (footer != null) ...[
                const Divider(color: AppTheme.accentMid, height: 1),
                Padding(
                  padding: const EdgeInsets.all(AppTheme.space4),
                  child: footer,
                ),
              ],
            ],
          ),
        ),
      );
}
