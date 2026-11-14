import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';
import '../responsive/responsive.dart';
import '../responsive/window_size_class.dart';
import 'app_data_column.dart';
import 'app_state_panel.dart';

class AppResponsiveCollection<T> extends StatelessWidget {
  const AppResponsiveCollection({
    required this.rows,
    required this.columns,
    required this.compactCardBuilder,
    this.emptyTitle = 'Sin resultados',
    this.emptyMessage = 'Ajusta los filtros o vuelve a intentarlo más tarde.',
    this.onRowTap,
    super.key,
  });

  final List<T> rows;
  final List<AppDataColumn<T>> columns;
  final Widget Function(BuildContext context, T row) compactCardBuilder;
  final String emptyTitle;
  final String emptyMessage;
  final ValueChanged<T>? onRowTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          if (rows.isEmpty) {
            return AppStatePanel(
              icon: Icons.search_off_outlined,
              title: emptyTitle,
              message: emptyMessage,
            );
          }
          final size = Responsive.of(context);
          if (size == WindowSizeClass.compacto) {
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rows.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppTheme.space3),
              itemBuilder: (context, index) => _row(
                context,
                rows[index],
                compactCardBuilder(context, rows[index]),
              ),
            );
          }
          final visibleColumns = size == WindowSizeClass.medio
              ? columns.where((column) => column.showOnMedium).toList()
              : columns;
          return ClipRRect(
            key: const Key('app-responsive-table'),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            child: Column(
              children: [
                _desktopLine(context, visibleColumns, header: true),
                for (var index = 0; index < rows.length; index++)
                  _desktopLine(
                    context,
                    visibleColumns,
                    row: rows[index],
                    isLast: index == rows.length - 1,
                  ),
              ],
            ),
          );
        },
      );

  Widget _desktopLine(
    BuildContext context,
    List<AppDataColumn<T>> visibleColumns, {
    T? row,
    bool header = false,
    bool isLast = false,
  }) {
    final line = Container(
      key: header ? const Key('app-responsive-table-header') : null,
      constraints: BoxConstraints(minHeight: header ? 44 : 58),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space3),
      decoration: BoxDecoration(
        color: header ? AppTheme.surfaceSecondary : AppTheme.surface,
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppTheme.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final column in visibleColumns)
            Expanded(
              flex: column.flex,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space2,
                  vertical: AppTheme.space2,
                ),
                child: Align(
                  alignment: column.numeric
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: header
                      ? Text(
                          column.label.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppTheme.accentMid,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: .35,
                                  ),
                        )
                      : DefaultTextStyle.merge(
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.inkSecondary,
                                    fontSize: 12,
                                  ),
                          child: column.value(row as T),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
    if (header || onRowTap == null) return line;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        hoverColor: const Color(0xFFF0F7F8),
        onTap: () => onRowTap!(row as T),
        child: line,
      ),
    );
  }

  Widget _row(BuildContext context, T row, Widget card) {
    if (onRowTap == null) return card;
    return Semantics(
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: () => onRowTap!(row),
        child: card,
      ),
    );
  }
}
