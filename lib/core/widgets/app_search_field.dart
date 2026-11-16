import 'package:flutter/material.dart';

class AppSearchField extends StatelessWidget {
  const AppSearchField({
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.width,
    this.fieldKey,
    super.key,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final double? width;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: TextField(
          key: fieldKey,
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: hintText,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      );
}
