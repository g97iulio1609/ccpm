import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/shared/shared.dart';
import 'package:alphanessone/trainingBuilder/shared/utils/format_utils.dart'
    as tb_format;
import 'package:alphanessone/UI/components/kpi_badge.dart';

/// Component for displaying series group information
class SeriesGroupHeader extends StatelessWidget {
  final List<Series> seriesGroup;
  final bool isExpanded;
  final VoidCallback onOptionsPressed;

  const SeriesGroupHeader({
    super.key,
    required this.seriesGroup,
    required this.isExpanded,
    required this.onOptionsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final series = seriesGroup.first;

    return Row(
      children: [
        _buildSeriesCountBadge(theme, colorScheme),
        SizedBox(width: AppTheme.spacing.sm),
        Expanded(child: _buildSeriesInfo(series, theme, colorScheme)),
      ],
    );
  }

  Widget _buildSeriesCountBadge(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing.sm,
        vertical: AppTheme.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withAlpha(77),
        borderRadius: BorderRadius.circular(AppTheme.radii.full),
      ),
      child: Text(
        '${seriesGroup.length} serie',
        style: theme.textTheme.labelMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSeriesInfo(
    Series series,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Text(
      tb_format.FormatUtils.formatSeriesInfo(
        reps: series.reps,
        maxReps: series.maxReps,
        weight: series.weight,
        maxWeight: series.maxWeight,
      ),
      style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
      softWrap: true,
      maxLines: 2,
    );
  }
}

/// Component for displaying individual series information
class SeriesInfoCard extends StatelessWidget {
  final Series series;
  final VoidCallback? onRemove;

  const SeriesInfoCard({super.key, required this.series, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing.md,
        vertical: AppTheme.spacing.xs,
      ),
      padding: EdgeInsets.all(AppTheme.spacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(76),
        borderRadius: BorderRadius.circular(AppTheme.radii.md),
      ),
      child: Row(
        children: [
          Expanded(child: _buildSeriesDetails(theme, colorScheme)),
          if (onRemove != null) _buildRemoveButton(colorScheme),
        ],
      ),
    );
  }

  Widget _buildSeriesDetails(ThemeData theme, ColorScheme colorScheme) {
    final repsLabel = series.maxReps != null
        ? '${series.reps}-${series.maxReps} reps'
        : '${series.reps} reps';
    final weightLabel = series.maxWeight != null
        ? '${series.weight.toStringAsFixed(1)}-${series.maxWeight!.toStringAsFixed(1)} kg'
        : '${series.weight.toStringAsFixed(1)} kg';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Serie ${series.order}',
          style: theme.textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: AppTheme.spacing.xs),
        Row(
          children: [
            KpiBadge(
              text: repsLabel,
              icon: Icons.repeat,
              color: colorScheme.primary,
            ),
            SizedBox(width: AppTheme.spacing.xs),
            KpiBadge(
              text: weightLabel,
              icon: Icons.monitor_weight,
              color: colorScheme.secondary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRemoveButton(ColorScheme colorScheme) {
    return IconButton(
      icon: Icon(Icons.remove_circle_outline, color: colorScheme.error),
      onPressed: onRemove,
    );
  }
}

/// Component for expandable series group card
class SeriesGroupCard extends StatelessWidget {
  final List<Series> seriesGroup;
  final bool isExpanded;
  final VoidCallback onExpansionChanged;
  final VoidCallback onOptionsPressed;
  final Widget Function(Series series, int index) seriesBuilder;

  const SeriesGroupCard({
    super.key,
    required this.seriesGroup,
    required this.isExpanded,
    required this.onExpansionChanged,
    required this.onOptionsPressed,
    required this.seriesBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacing.sm),
      decoration: _buildCardDecoration(colorScheme),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          onExpansionChanged: (_) => onExpansionChanged(),
          title: SeriesGroupHeader(
            seriesGroup: seriesGroup,
            isExpanded: isExpanded,
            onOptionsPressed: onOptionsPressed,
          ),
          trailing: _buildTrailingButton(colorScheme),
          children: _buildSeriesChildren(),
        ),
      ),
    );
  }

  BoxDecoration _buildCardDecoration(ColorScheme colorScheme) {
    return BoxDecoration(
      color: colorScheme.surfaceContainerHighest.withAlpha(38),
      borderRadius: BorderRadius.circular(AppTheme.radii.lg),
      border: Border.all(color: colorScheme.outline.withAlpha(26)),
      boxShadow: AppTheme.elevations.small,
    );
  }

  Widget _buildTrailingButton(ColorScheme colorScheme) {
    return IconButton(
      icon: Icon(
        Icons.more_vert,
        color: colorScheme.onSurfaceVariant.withAlpha(128),
      ),
      onPressed: onOptionsPressed,
    );
  }

  List<Widget> _buildSeriesChildren() {
    return seriesGroup.asMap().entries.map((entry) {
      return seriesBuilder(entry.value, entry.key);
    }).toList();
  }
}

/// Component for series action buttons
class SeriesActionButtons extends StatelessWidget {
  final VoidCallback onReorder;
  final VoidCallback onAdd;
  final bool isSmallScreen;

  const SeriesActionButtons({
    super.key,
    required this.onReorder,
    required this.onAdd,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(child: _buildReorderButton(colorScheme)),
        SizedBox(width: AppTheme.spacing.md),
        Expanded(child: _buildAddButton(colorScheme)),
      ],
    );
  }

  Widget _buildReorderButton(ColorScheme colorScheme) {
    return ElevatedButton.icon(
      onPressed: onReorder,
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.surfaceContainerHighest,
        foregroundColor: colorScheme.onSurface,
        padding: EdgeInsets.symmetric(vertical: AppTheme.spacing.md),
      ),
      icon: Icon(Icons.reorder, size: 20),
      label: Text(isSmallScreen ? 'Reorder' : 'Reorder Series'),
    );
  }

  Widget _buildAddButton(ColorScheme colorScheme) {
    return ElevatedButton.icon(
      onPressed: onAdd,
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: EdgeInsets.symmetric(vertical: AppTheme.spacing.md),
      ),
      icon: Icon(Icons.add, size: 20),
      label: Text(isSmallScreen ? 'Add' : 'Add Series'),
    );
  }
}
