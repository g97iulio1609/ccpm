import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphanessone/Main/app_theme.dart';

import 'package:alphanessone/Viewer/UI/workout_provider.dart'
    as workout_provider;
import 'package:alphanessone/Viewer/UI/exercise_timer_bottom_sheet.dart';
import 'package:alphanessone/Viewer/UI/widgets/exercise_card.dart';
import 'package:alphanessone/Viewer/UI/widgets/superset_card.dart';


class WorkoutDetailsRefactored extends ConsumerStatefulWidget {
  final String programId;
  final String userId;
  final String weekId;
  final String workoutId;

  const WorkoutDetailsRefactored({
    super.key,
    required this.userId,
    required this.programId,
    required this.weekId,
    required this.workoutId,
  });

  @override
  ConsumerState<WorkoutDetailsRefactored> createState() =>
      _WorkoutDetailsRefactoredState();
}

class _WorkoutDetailsRefactoredState
    extends ConsumerState<WorkoutDetailsRefactored> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      ref.read(workout_provider.targetUserIdProvider.notifier).state =
          widget.userId;
      await ref
          .read(workout_provider.workoutServiceProvider)
          .initializeWorkout(widget.workoutId);
    });
  }

  @override
  void didUpdateWidget(WorkoutDetailsRefactored oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.workoutId != oldWidget.workoutId) {
      // Reset exercises immediately
      ref.read(workout_provider.exercisesProvider.notifier).state = [];
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        ref.read(workout_provider.targetUserIdProvider.notifier).state =
            widget.userId;
        await ref
            .read(workout_provider.workoutServiceProvider)
            .initializeWorkout(widget.workoutId);
      });
    }
  }

  @override
  void dispose() {
    // Clear the exercises state when disposing
    if (mounted) {
      ref.read(workout_provider.exercisesProvider.notifier).state = [];
      ref.read(workout_provider.workoutServiceProvider).dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(workout_provider.loadingProvider);
    final exercises = ref.watch(workout_provider.exercisesProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isListMode = screenWidth < 600;

    // Determina il numero di colonne in base alla larghezza dello schermo
    final crossAxisCount = isListMode ? 1 : 2;
    final padding = AppTheme.spacing.md;
    final spacing = AppTheme.spacing.md;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: loading
          ? _buildLoadingState(colorScheme, context)
          : ref.watch(workout_provider.loadingProvider)
              ? _buildProgressIndicator(colorScheme)
              : exercises.isEmpty
                  ? _buildEmptyState(colorScheme, context)
                  : _buildExercisesList(exercises, isListMode, padding, spacing,
                      crossAxisCount, context),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme, BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: colorScheme.primary,
            semanticsLabel: 'Caricamento esercizi in corso',
          ),
          SizedBox(height: AppTheme.spacing.md),
          Text(
            'Caricamento esercizi...',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(ColorScheme colorScheme) {
    return Center(
      child: CircularProgressIndicator(
        color: colorScheme.primary,
        semanticsLabel: 'Aggiornamento in corso',
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            size: 48,
            semanticLabel: 'Nessun esercizio',
          ),
          SizedBox(height: AppTheme.spacing.md),
          Text(
            'Nessun esercizio trovato',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesList(
      List<dynamic> exercises,
      bool isListMode,
      double padding,
      double spacing,
      int crossAxisCount,
      BuildContext context) {
    return isListMode
        ? ListView.builder(
            padding: EdgeInsets.all(padding),
            itemCount: exercises.length,
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(bottom: spacing),
              child: _buildExerciseCard(exercises[index], context),
            ),
          )
        : GridView.builder(
            padding: EdgeInsets.all(padding),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: 1.2,
            ),
            itemCount: exercises.length,
            key: PageStorageKey('workout_exercises_${widget.workoutId}'),
            itemBuilder: (context, index) =>
                _buildExerciseCard(exercises[index], context),
          );
  }

  Widget _buildExerciseCard(
      Map<String, dynamic> exercise, BuildContext context) {
    final superSetId = exercise['superSetId'];
    final exercises = ref.read(workout_provider.exercisesProvider);
    final grouped = ref
        .read(workout_provider.workoutServiceProvider)
        .groupExercisesBySuperSet(exercises);

    if (superSetId != null) {
      final superSetExercises = grouped[superSetId];
      if (superSetExercises != null && superSetExercises.first == exercise) {
        return SupersetCard(
          superSetExercises: superSetExercises,
          onNavigateToDetails: _navigateToExerciseDetails,
        );
      } else {
        return Container();
      }
    } else {
      return ExerciseCard(
        exercise: exercise,
        userId: widget.userId,
        workoutId: widget.workoutId,
        onNavigateToDetails: _navigateToExerciseDetails,
      );
    }
  }

  void _navigateToExerciseDetails(
      Map<String, dynamic> exercise, List<Map<String, dynamic>> exercises,
      [int startIndex = 0]) {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width,
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      builder: (context) {
        return SizedBox(
          width: MediaQuery.of(context).size.width,
          child: ExerciseTimer(
            programId: widget.programId,
            weekId: widget.weekId,
            workoutId: widget.workoutId,
            exerciseId: exercise['id'],
            userId: widget.userId,
            superSetExercises: exercises,
            superSetExerciseIndex:
                exercises.indexWhere((e) => e['id'] == exercise['id']),
            seriesList: exercise['series'],
            startIndex: startIndex,
          ),
        );
      },
    ).then((_) {});
  }
}
