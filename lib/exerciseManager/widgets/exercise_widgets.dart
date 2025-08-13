// lib/exerciseManager/widgets/exercise_widgets.dart

import 'package:flutter/material.dart';
import '../exercise_model.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/bottom_menu.dart';
import 'package:alphanessone/UI/components/icon_button_with_background.dart';
import 'package:alphanessone/UI/components/app_card.dart';

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
        color: colorScheme.tertiaryContainer.withAlpha(76),
        borderRadius: BorderRadius.circular(AppTheme.radii.xxl),
        border: Border.all(color: colorScheme.tertiary.withAlpha(76)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pending_outlined, size: 16, color: colorScheme.tertiary),
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

    return AppCard(
      onTap: () => _showExerciseOptions(context),
      padding: EdgeInsets.all(AppTheme.spacing.lg),
      glass: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tipo di esercizio e menu
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing.md,
                    vertical: AppTheme.spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withAlpha(76),
                    borderRadius: BorderRadius.circular(AppTheme.radii.xxl),
                  ),
                  child: Text(
                    exercise.type,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.more_vert,
                  color: colorScheme.onSurfaceVariant,
                ),
                onPressed: () => _showExerciseOptions(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacing.md),

          // Nome dell'esercizio
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

          // Gruppi muscolari
          Text(
            exercise.muscleGroups.join(", "),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Badge di approvazione pendente
          if (exercise.status == 'pending') ...[
            SizedBox(height: AppTheme.spacing.md),
            const PendingApprovalBadge(),
          ],
        ],
      ),
    );
  }

  void _showExerciseOptions(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BottomMenu(
        title: exercise.name,
        subtitle: exercise.muscleGroups.join(", "),
        leading: Container(
          padding: EdgeInsets.all(AppTheme.spacing.sm),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withAlpha(76),
            borderRadius: BorderRadius.circular(AppTheme.radii.md),
          ),
          child: Icon(
            Icons.fitness_center,
            color: colorScheme.primary,
            size: 24,
          ),
        ),
        items: [
          BottomMenuItem(
            title: 'Visualizza Dettagli',
            icon: Icons.visibility_outlined,
            onTap: () {
              onTap();
            },
          ),
          ...actions.whereType<IconButtonWithBackground>().map((action) {
            final iconButton = action;
            return BottomMenuItem(
              title: _getActionTitle(iconButton.icon),
              icon: iconButton.icon,
              onTap: () {
                iconButton.onPressed();
              },
              isDestructive: iconButton.icon == Icons.delete_outline,
            );
          }),
        ],
      ),
    );
  }

  String _getActionTitle(IconData icon) {
    switch (icon) {
      case Icons.edit_outlined:
        return 'Modifica Esercizio';
      case Icons.delete_outline:
        return 'Elimina Esercizio';
      case Icons.check_circle_outline:
        return 'Approva Esercizio';
      default:
        return 'Azione';
    }
  }
}
