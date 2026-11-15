import 'package:flutter/material.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({required this.label, required this.onPressed, super.key});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.arrow_back),
          label: Text(label),
          style: TextButton.styleFrom(alignment: Alignment.centerLeft),
        ),
      );
}
