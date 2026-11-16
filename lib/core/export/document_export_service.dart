import 'dart:typed_data';

import 'package:excel_plus/excel_plus.dart';
import 'package:pdf/pdf.dart' as pdf_package;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

abstract final class DocumentExportService {
  static Future<void> pdf({
    required String filename,
    required String title,
    required String subtitle,
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: pdf_package.PdfPageFormat.a4.landscape,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text(title)),
          pw.Text(subtitle),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rows,
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
    await Printing.sharePdf(
      bytes: await document.save(),
      filename: filename,
    );
  }

  static Uint8List excel({
    required String title,
    required String subtitle,
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    final workbook = Excel.createExcel();
    final sheet = workbook['Reporte'];
    sheet.updateCell(
      CellIndex.indexByString('A1'),
      TextCellValue(title),
    );
    sheet.updateCell(
      CellIndex.indexByString('A2'),
      TextCellValue(subtitle),
    );
    for (var column = 0; column < headers.length; column++) {
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: column, rowIndex: 3),
        TextCellValue(headers[column]),
      );
      sheet.setColumnWidth(column, column == 0 ? 30 : 24);
    }
    for (var row = 0; row < rows.length; row++) {
      for (var column = 0; column < rows[row].length; column++) {
        sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row + 4),
          TextCellValue(rows[row][column]),
        );
      }
    }
    return Uint8List.fromList(workbook.encode() ?? const <int>[]);
  }
}
