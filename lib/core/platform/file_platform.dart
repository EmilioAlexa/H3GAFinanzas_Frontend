import 'package:flutter/foundation.dart';
import 'selected_file.dart';

abstract interface class FilePlatform {
  Future<SelectedFile?> chooseFile();
  Future<void> downloadFile(String name, Uint8List bytes);
}
