import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/shared/shared.dart';

class ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final List<SuperSet> superSets;
  final num latestMaxWeight;
  final VoidCallback onTap;
  final VoidCallback onOptions;
  final Widget? seriesWidget;
  final bool dense;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.superSets,
    required this.latestMaxWeight,
    required this.onTap,
    required this.onOptions,
    this.seriesWidget,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isInSuperSet = superSets.any((ss) => ss.exerciseIds.contains(exercise.id));

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          child: Padding(
            padding: EdgeInsets.all(dense ? AppTheme.spacing.md : AppTheme.spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, theme, colorScheme),
                SizedBox(height: dense ? AppTheme.spacing.sm : AppTheme.spacing.md),
                _buildExerciseInfo(context, theme, colorScheme),
                if (seriesWidget != null) ...[
                  SizedBox(height: dense ? AppTheme.spacing.sm : AppTheme.spacing.md),
                  // In lista (schermi stretti) lascia espandere il contenuto naturalmente;
                  // in griglia (schermi larghi) vincola un'altezza per evitare tagli.
                  Builder(
                    builder: (context) {
                      final isWide = MediaQuery.of(context).size.width >= 900;
                      final double? h = isWide ? (dense ? 220 : 280) : null;
                      return h != null ? SizedBox(height: h, child: seriesWidget!) : seriesWidget!;
                    },
                  ),
                ],
                if (isInSuperSet) ...[
                  SizedBox(height: dense ? AppTheme.spacing.sm : AppTheme.spacing.md),
                  _buildSuperSetBadge(context, theme, colorScheme),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacing.md,
            vertical: AppTheme.spacing.xs,
          ),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppTheme.radii.xxl),
          ),
          child: Text(
            exercise.type,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        IconButton(
          icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
          onPressed: onOptions,
          tooltip: 'Opzioni esercizio',
        ),
      ],
    );
  }

  Widget _buildExerciseInfo(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          exercise.name,
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (exercise.variant?.isNotEmpty ?? false) ...[
          SizedBox(height: AppTheme.spacing.xs),
          Text(
            exercise.variant!,
            style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildSuperSetBadge(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing.md, vertical: AppTheme.spacing.xs),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.group_work, size: 18, color: colorScheme.onSecondaryContainer),
          SizedBox(width: AppTheme.spacing.xs),
          Text(
            'Superset',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
