import 'package:flutter/material.dart';
import '../exercise_model.dart';
import '../../UI/components/card.dart';
import 'package:alphanessone/Main/app_theme.dart';

class PendingApprovalBadge extends StatelessWidget {
  const PendingApprovalBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing.md,
        vertical: AppTheme.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppTheme.radii.xxl),
        border: Border.all(
          color: colorScheme.tertiary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.pending_outlined,
            size: 16,
            color: colorScheme.tertiary,
          ),
          SizedBox(width: AppTheme.spacing.xs),
          Text(
            'Pending Approval',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.tertiary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class ExerciseCardContent extends StatelessWidget {
  final ExerciseModel exercise;
  final List<Widget> actions;
  final VoidCallback onTap;

  const ExerciseCardContent({
    super.key,
    required this.exercise,
    required this.actions,
    required this.onTap,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exercise Type Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing.md,
                    vertical: AppTheme.spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(AppTheme.radii.xxl),
                  ),
                  child: Text(
                    exercise.type,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                SizedBox(height: AppTheme.spacing.md),

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

                SizedBox(height: AppTheme.spacing.sm),

                Text(
                  exercise.muscleGroups.join(", "),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: AppTheme.spacing.lg),

                // Actions Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions,
                ),

                if (exercise.status == 'pending') ...[
                  SizedBox(height: AppTheme.spacing.md),
                  const PendingApprovalBadge(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
} 