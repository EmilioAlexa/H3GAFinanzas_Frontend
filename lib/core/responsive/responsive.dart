import 'package:flutter/widgets.dart';
import 'window_size_class.dart';

class Responsive {
  static const compactMaxWidth = 600.0;
  static const expandedMinWidth = 1024.0;
  static const figmaSidebarCollapseWidth = 860.0;
  static const figmaDenseLayoutWidth = 1150.0;

  static WindowSizeClass classify(double width) => switch (width) {
        < compactMaxWidth => WindowSizeClass.compacto,
        < expandedMinWidth => WindowSizeClass.medio,
        _ => WindowSizeClass.expandido,
      };

  static WindowSizeClass of(BuildContext context) =>
      classify(MediaQuery.sizeOf(context).width);
}
