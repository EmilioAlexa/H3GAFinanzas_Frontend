import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/app/theme/app_theme.dart';
import 'package:h3ga_finanzas/core/widgets/app_dialog.dart';
import 'package:h3ga_finanzas/core/widgets/app_side_panel.dart';
import 'package:h3ga_finanzas/core/widgets/app_tab_strip.dart';

void main() {
  testWidgets('tab strip changes selection and keeps its count visible',
      (tester) async {
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: StatefulBuilder(
          builder: (context, setState) => AppTabStrip(
            labels: const ['Pendientes', 'Concluidos'],
            counts: const [8, 12],
            selectedIndex: selected,
            onSelected: (value) => setState(() => selected = value),
          ),
        ),
      ),
    );

    expect(find.text('8'), findsOneWidget);
    await tester.tap(find.text('Concluidos'));
    await tester.pump();
    expect(selected, 1);
  });

  testWidgets('dialog displays title, body and actions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: AppDialog(
            title: 'Confirmar aprobación',
            description: 'Revisa los datos antes de continuar.',
            icon: Icons.check_circle_outline,
            actions: [TextButton(onPressed: null, child: Text('Cancelar'))],
            child: Text('Resumen del pago'),
          ),
        ),
      ),
    );

    expect(find.text('Confirmar aprobación'), findsOneWidget);
    expect(find.text('Resumen del pago'), findsOneWidget);
    expect(find.byKey(const Key('app-dialog-content')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('side panel becomes full-width only on compact screens',
      (tester) async {
    for (final width in [390.0, 1280.0]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: AppSidePanel(
              title: Text('Ver usuario'),
              content: Text('Información del perfil'),
            ),
          ),
        ),
      );
      final panel = tester.getSize(
        find.byKey(const Key('app-side-panel-content')),
      );
      expect(panel.width, width < 600 ? width : 520);
      expect(tester.takeException(), isNull);
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
