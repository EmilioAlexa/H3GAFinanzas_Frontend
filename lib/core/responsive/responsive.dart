import 'package:flutter/widgets.dart';
import 'window_size_class.dart';

class Responsive {
  static const compactMaxWidth = 600.0;
  static const expandedMinWidth = 1024.0;
  static const contentMaxWidth = 1600.0;
  static const figmaNavigationCollapseWidth = 860.0;
  static const figmaDenseLayoutWidth = 1150.0;

  static bool isCompact(double width) => width < compactMaxWidth;

  static bool isMedium(double width) =>
      width >= compactMaxWidth && width < expandedMinWidth;

  static bool isExpanded(double width) => width >= expandedMinWidth;

  /// Figma collapses its sidebar at 860 px, inside the medium class.
  static bool usesCollapsedNavigation(double width) =>
      width <= figmaNavigationCollapseWidth;

  /// Figma reduces the number of dashboard/report columns below 1150 px.
  static bool usesDenseLayout(double width) => width <= figmaDenseLayoutWidth;

  static int dashboardMetricColumns(double width) => switch (width) {
        <= figmaNavigationCollapseWidth => 2,
        <= figmaDenseLayoutWidth => 3,
        _ => 5,
      };

  static WindowSizeClass classify(double width) => switch (width) {
        < compactMaxWidth => WindowSizeClass.compacto,
        < expandedMinWidth => WindowSizeClass.medio,
        _ => WindowSizeClass.expandido,
      };

  static WindowSizeClass of(BuildContext context) =>
      classify(MediaQuery.sizeOf(context).width);
}
