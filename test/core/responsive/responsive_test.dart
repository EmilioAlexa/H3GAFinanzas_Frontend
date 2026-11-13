import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/core/responsive/responsive.dart';
import 'package:h3ga_finanzas/core/responsive/window_size_class.dart';

void main() {
  group('Responsive', () {
    test('maps widths to the three window classes', () {
      expect(Responsive.classify(599), WindowSizeClass.compacto);
      expect(Responsive.classify(600), WindowSizeClass.medio);
      expect(Responsive.classify(1023), WindowSizeClass.medio);
      expect(Responsive.classify(1024), WindowSizeClass.expandido);
    });

    test('keeps Figma navigation and density breakpoints centralized', () {
      expect(Responsive.usesCollapsedNavigation(860), isTrue);
      expect(Responsive.usesCollapsedNavigation(861), isFalse);
      expect(Responsive.usesDenseLayout(1150), isTrue);
      expect(Responsive.usesDenseLayout(1151), isFalse);
    });

    test('dashboard metrics follow the Figma window breakpoints', () {
      expect(Responsive.dashboardMetricColumns(860), 2);
      expect(Responsive.dashboardMetricColumns(861), 3);
      expect(Responsive.dashboardMetricColumns(1150), 3);
      expect(Responsive.dashboardMetricColumns(1151), 5);
    });
  });
}
