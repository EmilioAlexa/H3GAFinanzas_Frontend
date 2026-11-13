import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';
import '../responsive/responsive.dart';
import '../responsive/window_size_class.dart';

class AppSidePanel extends StatelessWidget {
  const AppSidePanel(
      {required this.title,
      required this.content,
      this.actions = const [],
      super.key});
  final Widget title;
  final Widget content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final compact = Responsive.of(context) == WindowSizeClass.compacto;
    return Dialog(
      alignment: Alignment.centerRight,
      insetPadding: EdgeInsets.zero,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(),
      child: SizedBox(
        key: const Key('app-side-panel-content'),
        width: compact ? MediaQuery.sizeOf(context).width : 520,
        height: MediaQuery.sizeOf(context).height,
        child: SafeArea(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              Padding(
                  padding: const EdgeInsets.all(AppTheme.space5),
                  child: Row(children: [
                    Expanded(
                        child: DefaultTextStyle(
                            style: Theme.of(context).textTheme.titleLarge!,
                            child: title)),
                    IconButton(
                        tooltip: 'Cerrar',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.close)),
                  ])),
              const Divider(height: 1),
              Expanded(
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.space5),
                      child: content)),
              const Divider(height: 1),
              Padding(
                  padding: const EdgeInsets.all(AppTheme.space4),
                  child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: actions)),
            ])),
      ),
    );
  }
}
