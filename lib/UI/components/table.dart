import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';

class AppTable<T> extends StatelessWidget {
  final List<String> columns;
  final List<T> rows;
  final List<DataCell> Function(T) buildCells;
  final String? title;
  final String? subtitle;
  final Widget? leading;
  final bool isLoading;
  final String? emptyMessage;
  final Widget? Function(T)? buildExpansion;
  final bool showDividers;
  final bool zebra;
  final double? maxHeight;
  final bool stickyHeader;
  final void Function(T)? onRowTap;
  final void Function(T)? onRowLongPress;

  const AppTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.buildCells,
    this.title,
    this.subtitle,
    this.leading,
    this.isLoading = false,
    this.emptyMessage,
    this.buildExpansion,
    this.showDividers = true,
    this.zebra = false,
    this.maxHeight,
    this.stickyHeader = false,
    this.onRowTap,
    this.onRowLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: AppTheme.elevations.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            // Header
            Container(
              padding: EdgeInsets.all(AppTheme.spacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radii.lg),
                ),
              ),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    SizedBox(width: AppTheme.spacing.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title!,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle != null) ...[
                          SizedBox(height: AppTheme.spacing.xs),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Table Content
          if (isLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacing.xl),
                child: CircularProgressIndicator(
                  color: colorScheme.primary,
                ),
              ),
            )
          else if (rows.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.table_rows_outlined,
                      size: 64,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                    SizedBox(height: AppTheme.spacing.md),
                    Text(
                      emptyMessage ?? 'Nessun dato disponibile',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              constraints: maxHeight != null ? BoxConstraints(maxHeight: maxHeight!) : null,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (stickyHeader)
                        Container(
                          color: colorScheme.surface,
                          child: _buildHeader(colorScheme, theme),
                        )
                      else
                        _buildHeader(colorScheme, theme),
                      for (int i = 0; i < rows.length; i++) ...[
                        _buildRow(
                          rows[i],
                          i,
                          colorScheme,
                          theme,
                          isLastRow: i == rows.length - 1,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: showDividers ? Border(
          bottom: BorderSide(
            color: colorScheme.outline.withOpacity(0.1),
          ),
        ) : null,
      ),
      child: Row(
        children: columns.map((column) {
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spacing.lg,
              vertical: AppTheme.spacing.md,
            ),
            child: Text(
              column,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRow(T row, int index, ColorScheme colorScheme, ThemeData theme, {bool isLastRow = false}) {
    final cells = buildCells(row);
    final expansion = buildExpansion?.call(row);
    final backgroundColor = zebra && index % 2 == 1
        ? colorScheme.surfaceContainerHighest.withOpacity(0.1)
        : Colors.transparent;

    return Column(
      children: [
        Material(
          color: backgroundColor,
          child: InkWell(
            onTap: onRowTap != null ? () => onRowTap!(row) : null,
            onLongPress: onRowLongPress != null ? () => onRowLongPress!(row) : null,
            child: Container(
              decoration: BoxDecoration(
                border: showDividers && !isLastRow ? Border(
                  bottom: BorderSide(
                    color: colorScheme.outline.withOpacity(0.1),
                  ),
                ) : null,
              ),
              child: Row(
                children: cells.map((cell) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing.lg,
                      vertical: AppTheme.spacing.md,
                    ),
                    child: DefaultTextStyle(
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      child: cell.child,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        if (expansion != null)
          Container(
            width: double.infinity,
            color: backgroundColor,
            padding: EdgeInsets.all(AppTheme.spacing.lg),
            child: expansion,
          ),
      ],
    );
  }

  // Factory constructor per tabelle semplici
  static AppTable<Map<String, dynamic>> simple({
    required List<String> columns,
    required List<Map<String, dynamic>> data,
    String? title,
    String? subtitle,
    Widget? leading,
    bool isLoading = false,
    String? emptyMessage,
    bool showDividers = true,
    bool zebra = false,
    double? maxHeight,
    bool stickyHeader = false,
    void Function(Map<String, dynamic>)? onRowTap,
  }) {
    return AppTable<Map<String, dynamic>>(
      columns: columns,
      rows: data,
      buildCells: (row) => columns
          .map((column) => DataCell(Text(row[column]?.toString() ?? '')))
          .toList(),
      title: title,
      subtitle: subtitle,
      leading: leading,
      isLoading: isLoading,
      emptyMessage: emptyMessage,
      showDividers: showDividers,
      zebra: zebra,
      maxHeight: maxHeight,
      stickyHeader: stickyHeader,
      onRowTap: onRowTap,
    );
  }
}

// Helper widget per celle con badge
class BadgeCell extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  const BadgeCell({
    super.key,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing.sm,
        vertical: AppTheme.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppTheme.radii.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: textColor ?? colorScheme.primary,
            ),
            SizedBox(width: AppTheme.spacing.xs),
          ],
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor ?? colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
} 