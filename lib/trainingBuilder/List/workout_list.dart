import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../controller/training_program_controller.dart';
import '../dialog/reorder_dialog.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/bottom_menu.dart';

class TrainingProgramWorkoutListPage extends StatefulWidget {
  final TrainingProgramController controller;
  final int weekIndex;

  const TrainingProgramWorkoutListPage({
    super.key,
    required this.controller,
    required this.weekIndex,
  });

  @override
  State<TrainingProgramWorkoutListPage> createState() =>
      _TrainingProgramWorkoutListPageState();
}

class _TrainingProgramWorkoutListPageState
    extends State<TrainingProgramWorkoutListPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView.builder(
      padding: EdgeInsets.all(AppTheme.spacing.xl),
      itemCount:
          widget.controller.program.weeks[widget.weekIndex].workouts.length,
      itemBuilder: (context, index) => Container(
        margin: EdgeInsets.only(bottom: AppTheme.spacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          border: Border.all(
            color: colorScheme.outline.withAlpha(26),
          ),
          boxShadow: AppTheme.elevations.small,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context
                .go('/user_programs/training_program/week/workout', extra: {
              'userId': widget.controller.program.athleteId,
              'programId': widget.controller.program.id,
              'weekIndex': widget.weekIndex,
              'workoutIndex': index
            }),
            borderRadius: BorderRadius.circular(AppTheme.radii.lg),
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withAlpha(76),
                      borderRadius: BorderRadius.circular(AppTheme.radii.md),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppTheme.spacing.lg),
                  Expanded(
                    child: Text(
                      'Workout ${index + 1}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.more_vert, color: colorScheme.primary),
                    onPressed: () => _showWorkoutOptions(
                      context,
                      index,
                      theme,
                      colorScheme,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showWorkoutOptions(
    BuildContext context,
    int index,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BottomMenu(
        title: 'Allenamento ${index + 1}',
        subtitle: 'Gestisci allenamento',
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
            title: 'Copia Allenamento',
            icon: Icons.content_copy_outlined,
            onTap: () => widget.controller.copyWorkout(
              widget.weekIndex,
              index,
              context,
            ),
          ),
          BottomMenuItem(
            title: 'Riordina Allenamenti',
            icon: Icons.reorder,
            onTap: () => _showReorderWorkoutsDialog(context),
          ),
          BottomMenuItem(
            title: 'Aggiungi Allenamento',
            icon: Icons.add,
            onTap: () => widget.controller.addWorkout(widget.weekIndex),
          ),
          BottomMenuItem(
            title: 'Elimina Allenamento',
            icon: Icons.delete_outline,
            onTap: () => widget.controller.removeWorkout(
              widget.weekIndex,
              index + 1,
            ),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAddWorkoutButton(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.controller.addWorkout(widget.weekIndex),
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: AppTheme.spacing.lg,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: colorScheme.onPrimary,
                  size: 24,
                ),
                SizedBox(width: AppTheme.spacing.sm),
                Text(
                  'Add New Workout',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReorderWorkoutsDialog(BuildContext context) {
    final workoutNames = widget
        .controller.program.weeks[widget.weekIndex].workouts
        .map((workout) => 'Workout ${workout.order}')
        .toList();

    showDialog(
      context: context,
      builder: (context) => ReorderDialog(
        items: workoutNames,
        onReorder: (oldIndex, newIndex) => widget.controller
            .reorderWorkouts(widget.weekIndex, oldIndex, newIndex),
      ),
    );
  }
}
