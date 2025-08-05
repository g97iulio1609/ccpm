import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/shared/shared.dart';

import 'package:alphanessone/trainingBuilder/controller/training_program_controller.dart';
import 'package:alphanessone/trainingBuilder/presentation/widgets/cards/exercise_card.dart';
import 'package:alphanessone/trainingBuilder/presentation/widgets/dialogs/bulk_series_dialog.dart';
import 'package:alphanessone/trainingBuilder/presentation/widgets/lists/series_list_widget.dart';
import 'package:alphanessone/trainingBuilder/presentation/widgets/dialogs/exercise_options_dialog.dart';
import 'package:alphanessone/UI/components/button.dart';
import 'package:alphanessone/providers/providers.dart';

class ExercisesPage extends ConsumerWidget {
  final TrainingProgramController controller;
  final int weekIndex;
  final int workoutIndex;

  const ExercisesPage({
    super.key,
    required this.controller,
    required this.weekIndex,
    required this.workoutIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = controller.program.weeks[weekIndex].workouts[workoutIndex];
    final exercises = workout.exercises;
    final usersService = ref.watch(usersServiceProvider);
    final exerciseRecordService = usersService.exerciseRecordService;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isListMode = screenWidth < 600;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest.withAlpha(128),
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.all(AppTheme.spacing.md),
                sliver: isListMode
                    ? _buildListView(context, exercises, exerciseRecordService)
                    : _buildGridView(context, exercises, exerciseRecordService),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListView(
    BuildContext context,
    List<Exercise> exercises,
    dynamic exerciseRecordService,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index == exercises.length) {
          return Padding(
            padding: EdgeInsets.only(top: AppTheme.spacing.md),
            child: _buildAddExerciseButton(context),
          );
        }
        return Padding(
          padding: EdgeInsets.only(bottom: AppTheme.spacing.md),
          child: _buildExerciseCard(
            context,
            exercises[index],
            exerciseRecordService,
          ),
        );
      }, childCount: exercises.length + 1),
    );
  }

  Widget _buildGridView(
    BuildContext context,
    List<Exercise> exercises,
    dynamic exerciseRecordService,
  ) {
    return SliverGrid(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index == exercises.length) {
          return _buildAddExerciseButton(context);
        }
        return _buildExerciseCard(
          context,
          exercises[index],
          exerciseRecordService,
        );
      }, childCount: exercises.length + 1),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 600,
        mainAxisSpacing: AppTheme.spacing.md,
        crossAxisSpacing: AppTheme.spacing.md,
        mainAxisExtent: 400,
      ),
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    Exercise exercise,
    dynamic exerciseRecordService,
  ) {
    final workout = controller.program.weeks[weekIndex].workouts[workoutIndex];
    final superSets = (workout.superSets as List<dynamic>? ?? [])
        .where(
          (ss) =>
              (ss['exerciseIds'] as List<dynamic>? ?? []).contains(exercise.id),
        )
        .map((ss) => SuperSet.fromMap(ss as Map<String, dynamic>))
        .toList();

    return FutureBuilder<num>(
      future: _getLatestMaxWeight(
        exerciseRecordService,
        exercise.exerciseId ?? '',
      ),
      builder: (context, snapshot) {
        final latestMaxWeight = snapshot.data ?? 0;

        return ExerciseCard(
          exercise: exercise,
          superSets: superSets,
          latestMaxWeight: latestMaxWeight,
          onTap: () => _navigateToExerciseDetails(context, exercise, superSets),
          onOptions: () =>
              _showExerciseOptions(context, exercise, latestMaxWeight),
          seriesWidget: SeriesListWidget(
            exercise: exercise,
            controller: controller,
            weekIndex: weekIndex,
            workoutIndex: workoutIndex,
            exerciseIndex: exercise.order - 1,
            latestMaxWeight: latestMaxWeight,
          ),
        );
      },
    );
  }

  Widget _buildAddExerciseButton(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isSmallScreen ? double.infinity : 300,
        ),
        child: AppButton(
          label: 'Aggiungi Esercizio',
          icon: Icons.add_circle_outline,
          variant: AppButtonVariant.primary,
          size: isSmallScreen ? AppButtonSize.sm : AppButtonSize.md,
          block: true,
          onPressed: () =>
              controller.addExercise(weekIndex, workoutIndex, context),
        ),
      ),
    );
  }

  Future<num> _getLatestMaxWeight(
    dynamic exerciseRecordService,
    String exerciseId,
  ) async {
    if (exerciseId.isEmpty) return 0;

    try {
      final record = await exerciseRecordService.getLatestExerciseRecord(
        userId: controller.program.athleteId,
        exerciseId: exerciseId,
      );
      return record?.maxWeight ?? 0;
    } catch (e) {
      return 0;
    }
  }

  void _navigateToExerciseDetails(
    BuildContext context,
    Exercise exercise,
    List<SuperSet> superSets,
  ) {
    final superSetExerciseIndex = superSets.isNotEmpty
        ? superSets.indexOf(
            superSets.firstWhere(
              (ss) => ss.exerciseIds.contains(exercise.id),
              orElse: () => SuperSet(id: '', exerciseIds: []),
            ),
          )
        : 0;

    context.go(
      '/user_programs/training_viewer/week_details/workout_details/exercise_details',
      extra: {
        'programId': controller.program.id,
        'weekId': controller.program.weeks[weekIndex].id,
        'workoutId':
            controller.program.weeks[weekIndex].workouts[workoutIndex].id,
        'exerciseId': exercise.id,
        'userId': controller.program.athleteId,
        'superSetExercises': superSets.map((s) => s.toMap()).toList(),
        'superSetExerciseIndex': superSetExerciseIndex,
        'seriesList': exercise.series.map((s) => s.toMap()).toList(),
        'startIndex': 0,
      },
    );
  }

  void _showExerciseOptions(
    BuildContext context,
    Exercise exercise,
    num latestMaxWeight,
  ) {
    showDialog(
      context: context,
      builder: (context) => ExerciseOptionsDialog(
        exercise: exercise,
        latestMaxWeight: latestMaxWeight,
        controller: controller,
        weekIndex: weekIndex,
        workoutIndex: workoutIndex,
        onBulkSeries: () => _showBulkSeriesDialog(context, exercise),
        onEdit: () => controller.editExercise(
          weekIndex,
          workoutIndex,
          exercise.order - 1,
          context,
        ),
        onDuplicate: () => controller.duplicateExercise(
          weekIndex,
          workoutIndex,
          exercise.order - 1,
        ),
        onDelete: () => controller.removeExercise(
          weekIndex,
          workoutIndex,
          exercise.order - 1,
        ),
      ),
    );
  }

  void _showBulkSeriesDialog(BuildContext context, Exercise exercise) {
    final workout = controller.program.weeks[weekIndex].workouts[workoutIndex];

    showDialog(
      context: context,
      builder: (context) => BulkSeriesSelectionDialog(
        initialExercise: exercise,
        workoutExercises: workout.exercises,
        onNext: (selectedExercises) {
          _showBulkSeriesConfigurationDialog(context, selectedExercises);
        },
      ),
    );
  }

  void _showBulkSeriesConfigurationDialog(
    BuildContext context,
    List<Exercise> exercises,
  ) {
    showDialog(
      context: context,
      builder: (context) => BulkSeriesConfigurationDialog(
        exercises: exercises,
        onApply: (updatedExercises) {
          // Aggiorna gli esercizi nel controller
          for (var exercise in updatedExercises) {
            controller.updateExercise(exercise);
          }
        },
      ),
    );
  }
}
