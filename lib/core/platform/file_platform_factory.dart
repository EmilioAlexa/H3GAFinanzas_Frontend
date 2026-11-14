import 'file_platform.dart';
import 'file_platform_native.dart'
    if (dart.library.html) 'file_platform_web.dart' as platform;

FilePlatform createFilePlatform() => platform.createFilePlatform();
