import 'package:flutter/widgets.dart';
import 'window_size_class.dart';

class Responsive {
  static WindowSizeClass classify(double width) => switch (width) {
        < 600 => WindowSizeClass.compacto,
        < 1024 => WindowSizeClass.medio,
        _ => WindowSizeClass.expandido,
      };

  static WindowSizeClass of(BuildContext context) =>
      classify(MediaQuery.sizeOf(context).width);
}
