import 'dart:math';
import '../../../core/platform/selected_file.dart';

class ContractDocument {
  ContractDocument.fromJson(Map<String, dynamic> row)
      : id = row['id'] as String,
        name = row['nombre_original'] as String,
        mime = row['mime_type'] as String,
        size = row['tamano_bytes'] as int,
        date = DateTime.parse(row['creado_en'] as String);
  final String id, name, mime;
  final int size;
  final DateTime date;
}

class PendingContractDocument {
  PendingContractDocument(this.file) : requestId = _uuid();
  final SelectedFile file;
  final String requestId;
  static String _uuid() {
    final r = Random.secure();
    final b = List.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 15) | 64;
    b[8] = (b[8] & 63) | 128;
    final s = b.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
    return '${s.substring(0, 8)}-${s.substring(8, 12)}-${s.substring(12, 16)}-${s.substring(16, 20)}-${s.substring(20)}';
  }
}

String contractFileMime(SelectedFile file) {
  final b = file.bytes;
  if (b.isEmpty || b.length > 10485760) {
    throw const FormatException(
        'El archivo debe contener datos y no superar 10 MiB');
  }
  final ext = file.name.split('.').last.toLowerCase();
  bool starts(List<int> magic) =>
      b.length >= magic.length &&
      List.generate(magic.length, (i) => b[i] == magic[i]).every((v) => v);
  if (ext == 'pdf' &&
      starts([37, 80, 68, 70, 45]) &&
      String.fromCharCodes(b.skip(b.length > 1024 ? b.length - 1024 : 0))
          .contains('%%EOF')) {
    return 'application/pdf';
  }
  if (['jpg', 'jpeg'].contains(ext) &&
      starts([255, 216, 255]) &&
      b.length >= 4 &&
      b[b.length - 2] == 255 &&
      b.last == 217) {
    return 'image/jpeg';
  }
  if (ext == 'png' &&
      b.length >= 45 &&
      starts([137, 80, 78, 71, 13, 10, 26, 10]) &&
      b[8] == 0 &&
      b[9] == 0 &&
      b[10] == 0 &&
      b[11] == 13 &&
      b.sublist(16, 20).any((v) => v != 0) &&
      b.sublist(20, 24).any((v) => v != 0) &&
      String.fromCharCodes(b.sublist(12, 16)) == 'IHDR' &&
      String.fromCharCodes(b.sublist(b.length - 8, b.length - 4)) == 'IEND') {
    return 'image/png';
  }
  throw const FormatException('El contenido no coincide con PDF, JPEG o PNG');
}
