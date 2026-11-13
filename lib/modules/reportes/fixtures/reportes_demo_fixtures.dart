import 'package:decimal/decimal.dart';

import '../../../core/demo/demo_dataset.dart';
import '../../../core/demo/demo_metric.dart';
import '../../../core/demo/demo_record.dart';
import '../models/report_data_model.dart';
import '../models/report_point_model.dart';
import '../models/report_row_model.dart';
import '../models/report_type_model.dart';

abstract final class ReportesDemoFixtures {
  static Decimal _amount(String value) => Decimal.parse(value);

  static const dataset = DemoDataset(
    module: 'reportes',
    metrics: [
      DemoMetric(label: 'Ingresos validados', value: '\$1,284,500'),
      DemoMetric(label: 'Comisiones', value: '\$164,820'),
      DemoMetric(label: 'Pagos', value: '124'),
    ],
    records: [
      DemoRecord(
          id: 'demo-report-1',
          title: 'Modalidad 40',
          subtitle: '38% del ingreso · 24 pagos',
          amount: '\$486,300'),
      DemoRecord(
          id: 'demo-report-2',
          title: 'APD',
          subtitle: '31% del ingreso · 18 pagos',
          amount: '\$398,250'),
      DemoRecord(
          id: 'demo-report-3',
          title: 'Modalidad 10',
          subtitle: '21% del ingreso · 32 pagos',
          amount: '\$274,650'),
      DemoRecord(
          id: 'demo-report-4',
          title: 'M40 Retroactiva',
          subtitle: '10% del ingreso · 8 pagos',
          amount: '\$125,300'),
    ],
    notes: [
      'No usar como base de cifras oficiales ni como datos personales reales.'
    ],
  );

  static final reports = <ReportType, ReportDataModel>{
    ReportType.ingresos: ReportDataModel(
      type: ReportType.ingresos,
      total: _amount('2460000'),
      comparisonTotal: _amount('2183000'),
      points: [
        ReportPointModel(label: '04 abr', amount: _amount('260000')),
        ReportPointModel(label: '11 abr', amount: _amount('280000')),
        ReportPointModel(label: '18 abr', amount: _amount('295000')),
        ReportPointModel(label: '25 abr', amount: _amount('310000')),
        ReportPointModel(label: '02 may', amount: _amount('325000')),
        ReportPointModel(label: '09 may', amount: _amount('310000')),
        ReportPointModel(label: '16 may', amount: _amount('330000')),
        ReportPointModel(label: '23 may', amount: _amount('350000')),
      ],
      serviceBreakdown: [
        ReportRowModel(
            title: 'Modalidad 40',
            amount: _amount('1081556'),
            percentage: _amount('38')),
        ReportRowModel(
            title: 'APD', amount: _amount('882322'), percentage: _amount('31')),
        ReportRowModel(
            title: 'Modalidad 10',
            amount: _amount('597702'),
            percentage: _amount('21')),
        ReportRowModel(
            title: 'M40 Retroactiva',
            amount: _amount('284620'),
            percentage: _amount('10')),
      ],
      rows: [
        ReportRowModel(title: '04 abr', amount: _amount('260000')),
        ReportRowModel(title: '11 abr', amount: _amount('280000')),
        ReportRowModel(title: '18 abr', amount: _amount('295000')),
        ReportRowModel(title: '25 abr', amount: _amount('310000')),
        ReportRowModel(title: '02 may', amount: _amount('325000')),
        ReportRowModel(title: '09 may', amount: _amount('310000')),
        ReportRowModel(title: '16 may', amount: _amount('330000')),
        ReportRowModel(title: '23 may', amount: _amount('350000')),
      ],
    ),
    ReportType.comisionesDestino: ReportDataModel(
      type: ReportType.comisionesDestino,
      total: _amount('40000'),
      rows: [
        ReportRowModel(
          title: 'Asesor',
          subtitle: 'Laura Méndez · Asesora',
          count: 4,
          amount: _amount('4500'),
          percentage: _amount('11.25'),
          status: 'Pendiente de dispersión',
        ),
        ReportRowModel(
          title: 'Director',
          subtitle: 'Roberto Luna',
          count: 2,
          amount: _amount('2000'),
          percentage: _amount('5'),
          status: 'Dispersada',
        ),
        ReportRowModel(
          title: 'Gerente',
          subtitle: 'Sofía Vega',
          count: 2,
          amount: _amount('2000'),
          percentage: _amount('5'),
          status: 'Pendiente de dispersión',
        ),
        ReportRowModel(
          title: 'IMSS',
          subtitle: 'M10 / M40 / M40 Retroactiva',
          count: 3,
          amount: _amount('15000'),
          percentage: _amount('37.5'),
          status: 'Pendiente de dispersión',
        ),
        ReportRowModel(
          title: 'Empresa',
          subtitle: 'Remanente',
          count: 4,
          amount: _amount('16500'),
          percentage: _amount('41.25'),
          status: 'Referencial',
        ),
      ],
    ),
    ReportType.comisionesTipoVenta: ReportDataModel(
      type: ReportType.comisionesTipoVenta,
      total: _amount('8500'),
      rows: [
        ReportRowModel(
            title: 'Cambaceo',
            count: 2,
            average: _amount('15'),
            amount: _amount('4000')),
        ReportRowModel(
            title: 'Marketing',
            count: 1,
            average: _amount('12'),
            amount: _amount('1500')),
        ReportRowModel(
            title: 'Referidor',
            count: 1,
            average: _amount('10'),
            amount: _amount('1200')),
        ReportRowModel(
            title: 'Bróker',
            count: 1,
            average: _amount('12'),
            amount: _amount('1800')),
        ReportRowModel(
            title: 'Sin tipo de venta registrado',
            count: 2,
            average: null,
            amount: _amount('0')),
      ],
    ),
    ReportType.imss: ReportDataModel(
      type: ReportType.imss,
      total: _amount('15000'),
      rows: [
        ReportRowModel(
          title: 'M40202500001',
          subtitle: 'PG-2025-0428 · Elena Robles Vargas',
          service: 'Modalidad 40',
          percentage: _amount('50'),
          amount: _amount('5000'),
          status: 'Dispersada',
        ),
        ReportRowModel(
          title: 'H3-M40-0317',
          subtitle: 'PG-2025-0501 · Natalia Vázquez Soto',
          service: 'Modalidad 40',
          percentage: _amount('50'),
          amount: _amount('5000'),
          status: 'Dispersada',
        ),
        ReportRowModel(
          title: 'H3-M10-0426',
          subtitle: 'PG-2025-0502 · Arturo Medina Flores',
          service: 'Modalidad 10',
          percentage: _amount('50'),
          amount: _amount('5000'),
          status: 'Pendiente de dispersión',
        ),
      ],
    ),
    ReportType.pagosMetodo: ReportDataModel(
      type: ReportType.pagosMetodo,
      total: _amount('40000'),
      rows: [
        ReportRowModel(
            title: 'Transferencia',
            count: 2,
            amount: _amount('20000'),
            percentage: _amount('50')),
        ReportRowModel(
            title: 'Depósito',
            count: 1,
            amount: _amount('10000'),
            percentage: _amount('25')),
        ReportRowModel(
            title: 'Efectivo',
            subtitle: 'Requiere validación de caja',
            count: 1,
            amount: _amount('10000'),
            percentage: _amount('25')),
      ],
    ),
  };
}
