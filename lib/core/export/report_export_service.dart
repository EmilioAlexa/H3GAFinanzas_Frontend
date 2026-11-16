import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:excel_plus/excel_plus.dart';
import 'package:pdf/pdf.dart' as pdf_package;
import 'package:pdf/widgets.dart' as pw;

import '../../modules/reportes/models/report_data_model.dart';
import '../../modules/reportes/models/report_row_model.dart';
import '../../modules/reportes/models/report_type_model.dart';

abstract final class ReportExportService {
  static Future<Uint8List> pdf({
    required ReportDataModel report,
    required List<ReportRowModel> rows,
    required String period,
  }) async {
    final document = pw.Document();
    final headers = _headers(report.type);
    document.addPage(
      pw.MultiPage(
        pageFormat: pdf_package.PdfPageFormat.a4.landscape,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('H3GA Finanzas · ${report.type.title}'),
          ),
          pw.Text('Periodo: $period'),
          pw.SizedBox(height: 12),
          pw.Text('Total: ${_money(report.total)}'),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: [for (final row in rows) _values(row)],
            headerStyle: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(
              color: pdf_package.PdfColor.fromInt(0xffe5f2f2),
            ),
            cellPadding: const pw.EdgeInsets.all(6),
            cellStyle: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );
    return document.save();
  }

  static Uint8List excel({
    required ReportDataModel report,
    required List<ReportRowModel> rows,
    required String period,
  }) {
    final workbook = Excel.createExcel();
    final sheet = workbook['Reporte'];
    final headers = _headers(report.type);
    sheet.updateCell(CellIndex.indexByString('A1'),
        TextCellValue('H3GA Finanzas · ${report.type.title}'));
    sheet.updateCell(
        CellIndex.indexByString('A2'), TextCellValue('Periodo: $period'));
    sheet.updateCell(CellIndex.indexByString('A3'),
        TextCellValue('Total: ${_money(report.total)}'));
    for (var column = 0; column < headers.length; column++) {
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: column, rowIndex: 4),
        TextCellValue(headers[column]),
      );
      sheet.setColumnWidth(column, column == 0 ? 28 : 24);
    }
    for (var index = 0; index < rows.length; index++) {
      final values = _values(rows[index]);
      for (var column = 0; column < values.length; column++) {
        sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: column, rowIndex: index + 5),
          TextCellValue(values[column]),
        );
      }
    }
    return Uint8List.fromList(workbook.save() ?? const <int>[]);
  }

  static List<String> _headers(ReportType type) => const [
        'Concepto',
        'Detalle',
        'Servicio',
        'Movimientos',
        'Importe',
        'Porcentaje',
        'Estado',
      ];

  static List<String> _values(ReportRowModel row) => [
        row.title,
        row.subtitle ?? '',
        row.service ?? '',
        row.count?.toString() ?? '',
        _money(row.amount),
        row.percentage?.toString() ?? '',
        row.status ?? '',
      ];

  static String _money(Decimal amount) => amount.toString();
}
