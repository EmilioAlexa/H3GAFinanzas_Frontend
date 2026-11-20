import '../../../core/platform/selected_file.dart';

String? validatePaymentEvidence(SelectedFile file) {
  final extension = file.name.split('.').last.toLowerCase();
  final bytes = file.bytes;
  if (!{'pdf', 'jpg', 'jpeg'}.contains(extension)) {
    return 'Solo se permiten PDF y JPG/JPEG.';
  }
  if (bytes.isEmpty) return 'El archivo está vacío.';
  if (bytes.lengthInBytes > 10 * 1024 * 1024) {
    return 'El archivo supera el límite de 10 MB.';
  }
  final pdf =
      bytes.length >= 5 && String.fromCharCodes(bytes.take(5)) == '%PDF-';
  final jpeg = bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff;
  if ((extension == 'pdf' && !pdf) || (extension != 'pdf' && !jpeg)) {
    return 'El contenido no coincide con un PDF o JPEG válido.';
  }
  return null;
}
