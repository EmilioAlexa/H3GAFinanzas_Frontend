import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/app.dart';
import 'core/network/api_client.dart';
import 'modules/auth/auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_MX');
  runApp(
    ProviderScope(
      overrides: [
        unauthorizedCallbackProvider.overrideWith(
          (ref) => () => ref.read(authControllerProvider.notifier).logout(),
        ),
      ],
      child: const H3gaFinanzasApp(),
    ),
  );
}
