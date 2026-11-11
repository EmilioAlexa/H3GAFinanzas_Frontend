import 'dart:typed_data';
import 'file_platform.dart';
import 'selected_file.dart';

class WebFilePlatform implements FilePlatform {
  @override
  Future<SelectedFile?> chooseFile() async => null;
  @override
  Future<void> downloadFile(String name, Uint8List bytes) async {}
}
