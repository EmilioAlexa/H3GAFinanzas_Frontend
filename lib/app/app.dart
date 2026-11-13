import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../modules/auth/auth.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class H3gaFinanzasApp extends ConsumerStatefulWidget {
  const H3gaFinanzasApp({super.key});

  @override
  ConsumerState<H3gaFinanzasApp> createState() => _H3gaFinanzasAppState();
}

class _H3gaFinanzasAppState extends ConsumerState<H3gaFinanzasApp> {
  @override
  void initState() {
    super.initState();
    unawaited(
      Future.microtask(
        () => ref.read(authControllerProvider.notifier).restoreSession(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'H3GA Finanzas',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: ref.watch(appRouterProvider),
      );
}
