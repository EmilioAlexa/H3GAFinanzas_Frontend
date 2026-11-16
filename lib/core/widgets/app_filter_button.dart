import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

class AppFilterButton extends StatelessWidget {
  const AppFilterButton(
      {required this.expanded, required this.onPressed, super.key});

  final bool expanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: expanded ? 'Ocultar filtros' : 'Mostrar filtros',
        child: SizedBox(
          width: 96,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.filter_list_rounded, size: 19),
            label: const Text('Filtros'),
            style: OutlinedButton.styleFrom(
              fixedSize: const Size(96, 48),
              minimumSize: const Size(96, 48),
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space2),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      );
}
