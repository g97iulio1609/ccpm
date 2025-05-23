import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../controller/training_program_controller.dart';
import '../dialog/reorder_dialog.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/bottom_menu.dart';
import 'package:alphanessone/trainingBuilder/shared/mixins/training_list_mixin.dart';

/// Widget for displaying and managing workout list
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
    extends State<TrainingProgramWorkoutListPage> with TrainingListMixin {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final workouts = widget.controller.program.weeks[widget.weekIndex].workouts;
    final screenSize = MediaQuery.of(context).size;
    final isCompact = screenSize.width < 600;

    // Use SafeArea to prevent UI blocking on mobile devices
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all(
                isCompact ? AppTheme.spacing.md : AppTheme.spacing.lg),
            sliver: workouts.isEmpty
                ? _buildEmptyState(theme, colorScheme, isCompact)
                : _buildWorkoutsList(workouts, theme, colorScheme, isCompact),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
      ThemeData theme, ColorScheme colorScheme, bool isCompact) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(AppTheme.spacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(76),
                borderRadius: BorderRadius.circular(AppTheme.radii.xl),
              ),
              child: Icon(
                Icons.fitness_center_outlined,
                size: isCompact ? 48 : 64,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: AppTheme.spacing.lg),
            Text(
              'Nessun allenamento disponibile',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppTheme.spacing.sm),
            Text(
              'Aggiungi il primo allenamento per iniziare',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutsList(List<dynamic> workouts, ThemeData theme,
      ColorScheme colorScheme, bool isCompact) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: isCompact ? AppTheme.spacing.sm : AppTheme.spacing.md,
            ),
            child: _buildWorkoutCard(
                context, index, theme, colorScheme, isCompact),
          );
        },
        childCount: workouts.length,
      ),
    );
  }

  Widget _buildWorkoutCard(
    BuildContext context,
    int index,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isCompact,
  ) {
    return buildCard(
      colorScheme: colorScheme,
      onTap: () => _navigateToWorkout(index),
      child: Padding(
        padding: EdgeInsets.all(
            isCompact ? AppTheme.spacing.md : AppTheme.spacing.lg),
        child: _WorkoutCardContent(
          index: index,
          theme: theme,
          colorScheme: colorScheme,
          isCompact: isCompact,
          onOptionsPressed: () => _showWorkoutOptions(context, index),
        ),
      ),
    );
  }

  void _navigateToWorkout(int index) {
    context.go('/user_programs/training_program/week/workout', extra: {
      'userId': widget.controller.program.athleteId,
      'programId': widget.controller.program.id,
      'weekIndex': widget.weekIndex,
      'workoutIndex': index
    });
  }

  void _showWorkoutOptions(BuildContext context, int index) {
    showOptionsBottomSheet(
      context,
      title: 'Allenamento ${index + 1}',
      subtitle: 'Gestisci allenamento',
      leadingIcon: Icons.fitness_center,
      items: _buildWorkoutMenuItems(index),
    );
  }

  List<BottomMenuItem> _buildWorkoutMenuItems(int index) {
    return [
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
        onTap: () => _showReorderDialog(),
      ),
      BottomMenuItem(
        title: 'Aggiungi Allenamento',
        icon: Icons.add,
        onTap: () => widget.controller.addWorkout(widget.weekIndex),
      ),
      BottomMenuItem(
        title: 'Elimina Allenamento',
        icon: Icons.delete_outline,
        onTap: () => _handleDeleteWorkout(index),
        isDestructive: true,
      ),
    ];
  }

  void _showReorderDialog() {
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

  void _handleDeleteWorkout(int index) async {
    final confirmed = await showDeleteConfirmation(
      context,
      title: 'Elimina Allenamento',
      content: 'Sei sicuro di voler eliminare questo allenamento?',
    );

    if (confirmed && mounted) {
      widget.controller.removeWorkout(widget.weekIndex, index + 1);
    }
  }
}

/// Content widget for workout card to improve separation of concerns
class _WorkoutCardContent extends StatelessWidget {
  final int index;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final bool isCompact;
  final VoidCallback onOptionsPressed;

  const _WorkoutCardContent({
    required this.index,
    required this.theme,
    required this.colorScheme,
    required this.isCompact,
    required this.onOptionsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use LayoutBuilder to ensure proper constraints handling
        return Row(
          children: [
            _buildWorkoutIcon(),
            SizedBox(
                width: isCompact ? AppTheme.spacing.md : AppTheme.spacing.lg),
            Expanded(
              child: _buildWorkoutTitle(),
            ),
            _buildOptionsButton(),
          ],
        );
      },
    );
  }

  Widget _buildWorkoutIcon() {
    final iconSize = isCompact ? 40.0 : 48.0;

    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withAlpha(76),
        borderRadius: BorderRadius.circular(
            isCompact ? AppTheme.radii.sm : AppTheme.radii.md),
      ),
      child: Center(
        child: FittedBox(
          child: Text(
            '${index + 1}',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: isCompact ? 16 : 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutTitle() {
    return Text(
      'Workout ${index + 1}',
      style: theme.textTheme.titleMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
        fontSize: isCompact ? 16 : 18,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  Widget _buildOptionsButton() {
    return Container(
      constraints: BoxConstraints(
        minWidth: isCompact ? 40 : 48,
        minHeight: isCompact ? 40 : 48,
      ),
      child: IconButton(
        icon: Icon(
          Icons.more_vert,
          color: colorScheme.primary,
          size: isCompact ? 20 : 24,
        ),
        onPressed: onOptionsPressed,
        padding: EdgeInsets.all(
            isCompact ? AppTheme.spacing.xs : AppTheme.spacing.sm),
        splashRadius: isCompact ? 20 : 24,
      ),
    );
  }
}
