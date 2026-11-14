import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h3ga_finanzas/core/widgets/app_data_column.dart';
import 'package:h3ga_finanzas/core/widgets/app_responsive_collection.dart';

void main() {
  const rows = ['Cliente A'];
  const columns = [
    AppDataColumn<String>(label: 'Nombre', value: Text.new),
    AppDataColumn<String>(
      label: 'Dato extendido',
      value: Text.new,
      showOnMedium: false,
    ),
  ];

  Widget harness(double width) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, 900)),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: AppResponsiveCollection<String>(
                  rows: rows,
                  columns: columns,
                  compactCardBuilder: (context, row) => Text('Tarjeta $row'),
                ),
              ),
            ),
          ),
        ),
      );

  testWidgets('shows cards in compact and a reduced table in medium',
      (tester) async {
    await tester.pumpWidget(harness(390));
    expect(find.text('Tarjeta Cliente A'), findsOneWidget);
    expect(find.text('DATO EXTENDIDO'), findsNothing);

    await tester.pumpWidget(harness(768));
    expect(find.text('NOMBRE'), findsOneWidget);
    expect(find.text('DATO EXTENDIDO'), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('app-responsive-table'))).width,
      equals(768),
    );
  });

  testWidgets('shows every column in expanded layouts', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 900);
    await tester.pumpWidget(harness(1280));
    expect(find.text('NOMBRE'), findsOneWidget);
    expect(find.text('DATO EXTENDIDO'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('app-responsive-table'))).width,
      equals(1280),
    );
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
