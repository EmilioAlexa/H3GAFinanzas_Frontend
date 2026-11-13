import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'file_platform.dart';
import 'selected_file.dart';

class NativeFilePlatform implements FilePlatform {
  @override
  Future<SelectedFile?> chooseFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return null;
    return SelectedFile(name: file.name, bytes: bytes);
  }

  @override
  Future<void> downloadFile(String name, Uint8List bytes) async {
    await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar archivo',
      fileName: name,
      type: FileType.custom,
      allowedExtensions: [
        if (name.toLowerCase().endsWith('.csv')) 'csv',
        if (name.toLowerCase().endsWith('.pdf')) 'pdf',
      ],
      bytes: bytes,
    );
  }
}

FilePlatform createFilePlatform() => NativeFilePlatform();
