import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Compact dropdown styling for list and report filters.
class AppFilterDropdown<T> extends StatelessWidget {
  const AppFilterDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
    super.key,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) => Semantics(
        label: label,
        child: DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 21),
          dropdownColor: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusField),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.inkSecondary,
                fontSize: 13,
              ),
          decoration: InputDecoration(
            hintText: label,
            isDense: true,
            filled: true,
            fillColor: AppTheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space3,
              vertical: AppTheme.space3,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusField),
              borderSide: const BorderSide(color: AppTheme.lineStrong),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusField),
              borderSide: const BorderSide(color: AppTheme.lineStrong),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusField),
              borderSide:
                  const BorderSide(color: AppTheme.secondaryDark, width: 1.5),
            ),
          ),
          items: items,
          onChanged: onChanged,
        ),
      );
}
