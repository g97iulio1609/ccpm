import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/shared/shared.dart';
import '../forms/series_form_fields.dart';

class SeriesCard extends StatelessWidget {
  final Series series;
  final num maxWeight;
  final String exerciseName;
  final bool isExpanded;
  // When false, the card will not render its internal expanded content block.
  final bool showExpandedContent;
  final VoidCallback? onExpansionChanged;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;
  final Function(Series)? onSeriesUpdated;

  const SeriesCard({
    super.key,
    required this.series,
    required this.maxWeight,
    required this.exerciseName,
    this.isExpanded = false,
    this.showExpandedContent = true,
    this.onExpansionChanged,
    this.onEdit,
    this.onDelete,
    this.onDuplicate,
    this.onSeriesUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(color: colorScheme.outline.withAlpha(26)),
        boxShadow: AppTheme.elevations.small,
      ),
      child: Column(
        children: [
          _buildHeader(context, theme, colorScheme),
          if (isExpanded && showExpandedContent)
            _buildExpandedContent(context, theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onExpansionChanged,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacing.md),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing.sm,
                  vertical: AppTheme.spacing.xs,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withAlpha(77),
                  borderRadius: BorderRadius.circular(AppTheme.radii.full),
                ),
                child: Text(
                  'Serie ${series.order}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: AppTheme.spacing.sm),
              _buildStatusBadge(theme, colorScheme),
              SizedBox(width: AppTheme.spacing.sm),
              Expanded(
                child: Text(
                  _formatSeriesInfo(),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              MenuAnchor(
                builder: (context, controller, child) {
                  return IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                  );
                },
                menuChildren: [
                  if (onEdit != null)
                    MenuItemButton(
                      leadingIcon: const Icon(Icons.edit_outlined),
                      onPressed: onEdit,
                      child: const Text('Modifica'),
                    ),
                  if (onDuplicate != null)
                    MenuItemButton(
                      leadingIcon: const Icon(Icons.content_copy_outlined),
                      onPressed: onDuplicate,
                      child: const Text('Duplica'),
                    ),
                  if (onDelete != null)
                    MenuItemButton(
                      leadingIcon: const Icon(Icons.delete_outline),
                      onPressed: onDelete,
                      child: const Text('Elimina'),
                    ),
                ],
              ),
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme, ColorScheme colorScheme) {
    String label;
    Color? bg;
    if (series.done == true) {
      label = 'Completata';
      bg = colorScheme.secondaryContainer;
    } else if ((series.repsDone) > 0 || (series.weightDone) > 0) {
      label = 'In corso';
      bg = colorScheme.tertiaryContainer;
    } else {
      label = 'Non svolta';
      bg = colorScheme.surfaceContainerHighest;
    }

    return Badge(
      label: Text(label, style: theme.textTheme.labelSmall),
      backgroundColor: bg,
    );
  }

  Widget _buildExpandedContent(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(76),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppTheme.radii.lg),
        ),
      ),
      child: SeriesFormFields(
        series: series,
        maxWeight: maxWeight,
        exerciseName: exerciseName,
        onSeriesUpdated: onSeriesUpdated,
      ),
    );
  }

  String _formatSeriesInfo() {
    final reps = _formatRange(
      series.reps.toString(),
      series.maxReps?.toString(),
    );
    final weight = _formatRange(
      series.weight.toString(),
      series.maxWeight?.toString(),
    );
    final intensity = (series.intensity?.isNotEmpty ?? false)
        ? ' (${series.intensity}%)'
        : '';
    final rpe = (series.rpe?.isNotEmpty ?? false) ? ' RPE ${series.rpe}' : '';

    return '$reps reps × $weight kg$intensity$rpe';
  }

  String _formatRange(String minValue, String? maxValue) {
    if (maxValue != null && maxValue != minValue && maxValue.isNotEmpty) {
      return '$minValue~$maxValue';
    }
    return minValue;
  }
}
