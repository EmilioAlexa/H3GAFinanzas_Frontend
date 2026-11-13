import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

class AppTabStrip extends StatelessWidget {
  const AppTabStrip({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.counts,
    super.key,
  });

  final List<String> labels;
  final List<int?>? counts;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Material(
        type: MaterialType.transparency,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
          children: [
            for (var index = 0; index < labels.length; index++)
              Semantics(
                selected: index == selectedIndex,
                button: true,
                child: InkWell(
                  onTap: () => onSelected(index),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space4,
                      vertical: AppTheme.space3,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: index == selectedIndex
                              ? AppTheme.secondaryDark
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          labels[index],
                          style: TextStyle(
                            color: index == selectedIndex
                                ? AppTheme.ink
                                : AppTheme.muted,
                            fontWeight: index == selectedIndex
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        if (counts != null &&
                            index < counts!.length &&
                            counts![index] != null) ...[
                          const SizedBox(width: AppTheme.space2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: index == selectedIndex
                                  ? AppTheme.secondarySoft
                                  : AppTheme.surfaceSecondary,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusPill),
                            ),
                            child: Text(
                              '${counts![index]}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
          ),
        ),
      );
}
