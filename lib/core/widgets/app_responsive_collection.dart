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
          final viewportWidth =
              constraints.maxWidth.isFinite ? constraints.maxWidth : 0.0;
          final tableWidth = viewportWidth < 850 ? 850.0 : viewportWidth;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 850),
                  child: DataTable(
                    headingRowColor:
                        const WidgetStatePropertyAll(AppTheme.surfaceSecondary),
                    headingRowHeight: 40,
                    dataRowMinHeight: 52,
                    dataRowMaxHeight: 64,
                    horizontalMargin: 12,
                    columnSpacing: 13,
                    headingTextStyle:
                        Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.accentMid,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .25,
                            ),
                    dataTextStyle:
                        Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.inkSecondary,
                              fontSize: 13,
                            ),
                    columns: [
                      for (final column in visibleColumns)
                        DataColumn(
                            label: Text(
                              column.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            numeric: column.numeric),
                    ],
                    rows: [
                      for (final row in rows)
                        DataRow(
                          color: WidgetStateProperty.resolveWith((states) =>
                              states.contains(WidgetState.hovered)
                                  ? const Color(0xFFF4F9FA)
                                  : null),
                          cells: [
                            for (final column in visibleColumns)
                              DataCell(
                                InkWell(
                                  onTap: onRowTap == null
                                      ? null
                                      : () => onRowTap!(row),
                                  child: column.value(row),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );

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
