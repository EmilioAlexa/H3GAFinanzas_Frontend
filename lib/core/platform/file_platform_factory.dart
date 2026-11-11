import 'package:flutter/foundation.dart';
import 'file_platform.dart';
import 'file_platform_native.dart';
import 'file_platform_web.dart';

FilePlatform createFilePlatform() =>
    kIsWeb ? WebFilePlatform() : NativeFilePlatform();
