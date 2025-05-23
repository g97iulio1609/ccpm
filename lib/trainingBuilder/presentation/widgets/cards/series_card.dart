import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/trainingBuilder/models/series_model.dart';
import '../forms/series_form_fields.dart';

class SeriesCard extends StatelessWidget {
  final Series series;
  final num maxWeight;
  final String exerciseName;
  final bool isExpanded;
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
        border: Border.all(
          color: colorScheme.outline.withAlpha(26),
        ),
        boxShadow: AppTheme.elevations.small,
      ),
      child: Column(
        children: [
          _buildHeader(context, theme, colorScheme),
          if (isExpanded) _buildExpandedContent(context, theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onEdit != null)
                    IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        color: colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: onEdit,
                      tooltip: 'Modifica serie',
                    ),
                  if (onDuplicate != null)
                    IconButton(
                      icon: Icon(
                        Icons.content_copy_outlined,
                        color: colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: onDuplicate,
                      tooltip: 'Duplica serie',
                    ),
                  if (onDelete != null)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: colorScheme.error,
                        size: 20,
                      ),
                      onPressed: onDelete,
                      tooltip: 'Elimina serie',
                    ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
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
    final reps =
        _formatRange(series.reps.toString(), series.maxReps?.toString());
    final weight =
        _formatRange(series.weight.toString(), series.maxWeight?.toString());
    final intensity =
        series.intensity.isNotEmpty ? ' (${series.intensity}%)' : '';
    final rpe = series.rpe.isNotEmpty ? ' RPE ${series.rpe}' : '';

    return '$reps reps × $weight kg$intensity$rpe';
  }

  String _formatRange(String minValue, String? maxValue) {
    if (maxValue != null && maxValue != minValue && maxValue.isNotEmpty) {
      return '$minValue-$maxValue';
    }
    return minValue;
  }
}
