import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../controller/training_program_controller.dart';
import '../dialog/reorder_dialog.dart';
import '../models/workout_model.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/bottom_menu.dart';

class TrainingProgramWorkoutListPage extends StatefulWidget {
  final TrainingProgramController controller;
  final int weekIndex;

  const TrainingProgramWorkoutListPage({
    required this.controller,
    required this.weekIndex,
    super.key,
  });

  @override
  State<TrainingProgramWorkoutListPage> createState() => _TrainingProgramWorkoutListPageState();
}

class _TrainingProgramWorkoutListPageState extends State<TrainingProgramWorkoutListPage> {
  @override
  Widget build(BuildContext context) {
    final week = widget.controller.program.weeks[widget.weekIndex];
    final workouts = week.workouts;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest.withOpacity(0.5),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Workouts List
              SliverPadding(
                padding: EdgeInsets.all(AppTheme.spacing.xl),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildWorkoutSlidable(
                      context,
                      workouts[index],
                      index,
                      theme,
                      colorScheme,
                    ),
                    childCount: workouts.length,
                  ),
                ),
              ),

              // Add Workout Button
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacing.xl),
                  child: _buildAddWorkoutButton(theme, colorScheme),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutSlidable(
    BuildContext context,
    Workout workout,
    int index,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              widget.controller.removeWorkout(widget.weekIndex, workout.order);
            },
            backgroundColor: colorScheme.errorContainer,
            foregroundColor: colorScheme.onErrorContainer,
            borderRadius: BorderRadius.horizontal(
              right: Radius.circular(AppTheme.radii.lg),
            ),
            icon: Icons.delete_outline,
            label: 'Delete',
          ),
        ],
      ),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              widget.controller.addWorkout(widget.weekIndex);
            },
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            borderRadius: BorderRadius.horizontal(
              left: Radius.circular(AppTheme.radii.lg),
            ),
            icon: Icons.add,
            label: 'Add',
          ),
        ],
      ),
      child: _buildWorkoutCard(context, workout, index, theme, colorScheme),
    );
  }

  Widget _buildWorkoutCard(
    BuildContext context,
    Workout workout,
    int index,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: AppTheme.spacing.xs,
        horizontal: AppTheme.spacing.md,
      ),
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
          onTap: () => context.go(
            '/user_programs/${widget.controller.program.athleteId}/training_program/${widget.controller.program.id}/week/${widget.weekIndex}/workout/$index',
          ),
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacing.lg),
            child: Row(
              children: [
                // Workout Number Badge
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${workout.order}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                SizedBox(width: AppTheme.spacing.lg),

                // Workout Title
                Expanded(
                  child: Text(
                    'Workout ${workout.order}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),

                IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: colorScheme.onSurfaceVariant,
                  ),
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
            color: colorScheme.primaryContainer.withOpacity(0.3),
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
    final workoutNames = widget.controller.program.weeks[widget.weekIndex]
        .workouts
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