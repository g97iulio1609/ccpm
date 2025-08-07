import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/trainingBuilder/dialogs/exercise_dialogs.dart';
import 'package:alphanessone/trainingBuilder/dialogs/bulk_series_dialogs.dart';
import 'package:alphanessone/shared/shared.dart';
import 'package:alphanessone/trainingBuilder/List/progressions_list.dart';
import 'package:alphanessone/trainingBuilder/widgets/exercise_list_widgets.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../controller/training_program_controller.dart';
import 'series_list.dart';
import '../dialog/reorder_dialog.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/bottom_menu.dart';
import 'package:go_router/go_router.dart';
import 'package:alphanessone/trainingBuilder/shared/mixins/training_list_mixin.dart';
import 'package:alphanessone/trainingBuilder/services/exercise_service.dart';
import 'package:alphanessone/trainingBuilder/shared/utils/exercise_utils.dart'
    as training_exercise_utils;
import 'package:alphanessone/UI/components/section_header.dart';

/// Widget principale per la gestione degli esercizi in un allenamento
class TrainingProgramExerciseList extends HookConsumerWidget {
  final TrainingProgramController controller;
  final int weekIndex;
  final int workoutIndex;

  const TrainingProgramExerciseList({
    required this.controller,
    required this.weekIndex,
    required this.workoutIndex,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = controller.program.weeks[weekIndex].workouts[workoutIndex];
    final exercises = workout.exercises;
    final usersService = ref.watch(usersServiceProvider);
    final exerciseRecordService = usersService.exerciseRecordService;
    final athleteId = controller.athleteIdController.text;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ExerciseListView(
      controller: controller,
      weekIndex: weekIndex,
      workoutIndex: workoutIndex,
      exercises: exercises,
      exerciseRecordService: exerciseRecordService,
      athleteId: athleteId,
      theme: theme,
      colorScheme: colorScheme,
    );
  }
}

/// Widget principale per la visualizzazione della lista esercizi
class ExerciseListView extends StatefulWidget {
  final TrainingProgramController controller;
  final int weekIndex;
  final int workoutIndex;
  final List<Exercise> exercises;
  final dynamic exerciseRecordService;
  final String athleteId;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const ExerciseListView({
    required this.controller,
    required this.weekIndex,
    required this.workoutIndex,
    required this.exercises,
    required this.exerciseRecordService,
    required this.athleteId,
    required this.theme,
    required this.colorScheme,
    super.key,
  });

  @override
  State<ExerciseListView> createState() => _ExerciseListViewState();
}

/// Stato principale della lista esercizi con logica di business
class _ExerciseListViewState extends State<ExerciseListView>
    with TrainingListMixin {
  @override
  Widget build(BuildContext context) {
    final isCompact = ResponsiveLayoutHelper.isCompact(context);
    final spacing = ResponsiveLayoutHelper.getSpacing(context);
    final padding = ResponsiveLayoutHelper.getPadding(context);

    return Scaffold(
      backgroundColor: widget.colorScheme.surface,
      body: ExerciseListBackground(
        colorScheme: widget.colorScheme,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header di sezione
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    padding.left,
                    padding.top,
                    padding.right,
                    AppTheme.spacing.sm,
                  ),
                  child: SectionHeader(
                    title: 'Esercizi',
                    subtitle: 'Gestisci serie, superset e progressioni',
                    trailing: IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: 'Aggiungi esercizio',
                      onPressed: _addExercise,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: padding,
                sliver: widget.exercises.isEmpty
                    ? _buildEmptyState(isCompact)
                    : _buildExerciseLayout(isCompact, spacing),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(isCompact),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  /// Costruisce lo stato vuoto
  Widget _buildEmptyState(bool isCompact) {
    return EmptyExerciseState(
      onAddExercise: _addExercise,
      isCompact: isCompact,
      colorScheme: widget.colorScheme,
    );
  }

  /// Costruisce il layout degli esercizi
  Widget _buildExerciseLayout(bool isCompact, double spacing) {
    return ExerciseLayoutBuilder(
      exercises: widget.exercises,
      isCompact: isCompact,
      spacing: spacing,
      exerciseBuilder: _buildExerciseCard,
      addExerciseButton: AddExerciseButton(
        onPressed: _addExercise,
        isCompact: isCompact,
      ),
    );
  }

  /// Costruisce la card di un esercizio
  Widget _buildExerciseCard(Exercise exercise) {
    final superSets = _getSuperSets(exercise);

    return FutureBuilder<num>(
      future: ExerciseService.getLatestMaxWeight(
        widget.exerciseRecordService,
        widget.athleteId,
        exercise.exerciseId ?? '',
      ),
      builder: (context, snapshot) {
        return ExerciseCardWithActions(
          exercise: exercise,
          superSets: superSets,
          seriesSection: _buildSeriesSection(exercise),
          onTap: () => _navigateToExerciseDetails(exercise, superSets),
          onOptionsPressed: () =>
              _showExerciseOptions(exercise, snapshot.data ?? 0),
          onAddExercise: _addExercise,
          onDeleteExercise: () => _deleteExercise(exercise),
          colorScheme: widget.colorScheme,
        );
      },
    );
  }

  /// Costruisce la sezione delle serie
  Widget _buildSeriesSection(Exercise exercise) {
    return TrainingProgramSeriesList(
      controller: widget.controller,
      exerciseRecordService: widget.exerciseRecordService,
      weekIndex: widget.weekIndex,
      workoutIndex: widget.workoutIndex,
      exerciseIndex: exercise.order - 1,
      exerciseType: exercise.type,
    );
  }

  /// Costruisce il FAB se necessario
  Widget? _buildFloatingActionButton(bool isCompact) {
    if (widget.exercises.length < 2) return null;

    return ReorderExercisesFAB(
      onPressed: _showReorderExercisesDialog,
      isCompact: isCompact,
      colorScheme: widget.colorScheme,
    );
  }

  // ========== METODI DI BUSINESS LOGIC ==========

  /// Ottiene i SuperSet associati a un esercizio
  List<SuperSet> _getSuperSets(Exercise exercise) {
    final workout = widget
        .controller
        .program
        .weeks[widget.weekIndex]
        .workouts[widget.workoutIndex];

    // Converte i superSets da Map a SuperSet
    final superSets =
        workout.superSets?.map((superSetMap) {
          return SuperSet(
            id: superSetMap['id'] ?? '',
            name: superSetMap['name'],
            exerciseIds: List<String>.from(superSetMap['exerciseIds'] ?? []),
          );
        }).toList() ??
        [];

    return training_exercise_utils.ExerciseUtils.getSuperSets(
      exercise,
      superSets,
    );
  }

  /// Aggiunge un nuovo esercizio
  void _addExercise() {
    widget.controller.addExercise(
      widget.weekIndex,
      widget.workoutIndex,
      context,
    );
  }

  /// Elimina un esercizio
  void _deleteExercise(Exercise exercise) {
    widget.controller.removeExercise(
      widget.weekIndex,
      widget.workoutIndex,
      exercise.order - 1,
    );
  }

  /// Mostra le opzioni dell'esercizio
  void _showExerciseOptions(Exercise exercise, num latestMaxWeight) {
    final superSets = _getSuperSets(exercise);
    final isInSuperSet = training_exercise_utils.ExerciseUtils.isInSuperSet(
      exercise,
      superSets,
    );
    final superSet = training_exercise_utils.ExerciseUtils.getFirstSuperSet(
      exercise,
      superSets,
    );

    showOptionsBottomSheet(
      context,
      title: exercise.name,
      subtitle: exercise.variant,
      leadingIcon: Icons.fitness_center,
      items: _buildExerciseMenuItems(
        exercise,
        latestMaxWeight,
        isInSuperSet,
        superSet,
      ),
    );
  }

  /// Costruisce gli elementi del menu dell'esercizio
  List<BottomMenuItem> _buildExerciseMenuItems(
    Exercise exercise,
    num latestMaxWeight,
    bool isInSuperSet,
    SuperSet? superSet,
  ) {
    return [
      BottomMenuItem(
        title: 'Modifica',
        icon: Icons.edit_outlined,
        onTap: () => _editExercise(exercise),
      ),
      BottomMenuItem(
        title: 'Gestione Serie in Bulk',
        icon: Icons.format_list_numbered,
        onTap: () => _showBulkSeriesDialog(exercise),
      ),
      BottomMenuItem(
        title: 'Sposta Esercizio',
        icon: Icons.move_up,
        onTap: () => _showMoveExerciseDialog(exercise),
      ),
      BottomMenuItem(
        title: 'Duplica Esercizio',
        icon: Icons.content_copy_outlined,
        onTap: () => _duplicateExercise(exercise),
      ),
      if (!isInSuperSet)
        BottomMenuItem(
          title: 'Aggiungi a Super Set',
          icon: Icons.group_add_outlined,
          onTap: () => _showAddToSuperSetDialog(exercise),
        ),
      if (isInSuperSet && superSet != null)
        BottomMenuItem(
          title: 'Rimuovi da Super Set',
          icon: Icons.group_remove_outlined,
          onTap: () => _removeFromSuperSet(exercise, superSet),
        ),
      BottomMenuItem(
        title: 'Imposta Progressione',
        icon: Icons.trending_up,
        onTap: () => _navigateToProgressions(exercise, latestMaxWeight),
      ),
      BottomMenuItem(
        title: 'Aggiorna Max RM',
        icon: Icons.fitness_center,
        onTap: () => _showUpdateMaxRMDialog(exercise),
      ),
      BottomMenuItem(
        title: 'Elimina',
        icon: Icons.delete_outline,
        onTap: () => _deleteExercise(exercise),
        isDestructive: true,
      ),
    ];
  }

  // ========== METODI DI AZIONE ==========

  void _editExercise(Exercise exercise) {
    widget.controller.editExercise(
      widget.weekIndex,
      widget.workoutIndex,
      exercise.order - 1,
      context,
    );
  }

  void _duplicateExercise(Exercise exercise) {
    widget.controller.duplicateExercise(
      widget.weekIndex,
      widget.workoutIndex,
      exercise.order - 1,
    );
  }

  void _removeFromSuperSet(Exercise exercise, SuperSet superSet) {
    widget.controller.removeExerciseFromSuperSet(
      widget.weekIndex,
      widget.workoutIndex,
      superSet.id,
      exercise.id!,
    );
  }

  // ========== METODI PER I DIALOG ==========

  void _showBulkSeriesDialog(Exercise exercise) {
    final workout = widget
        .controller
        .program
        .weeks[widget.weekIndex]
        .workouts[widget.workoutIndex];

    showDialog(
      context: context,
      builder: (context) => BulkSeriesSelectionDialog(
        initialExercise: exercise,
        workoutExercises: workout.exercises,
        colorScheme: widget.colorScheme,
        onNext: _showBulkConfigurationDialog,
      ),
    );
  }

  void _showBulkConfigurationDialog(List<Exercise> exercises) {
    showDialog(
      context: context,
      builder: (context) => BulkSeriesConfigurationDialog(
        exercises: exercises,
        colorScheme: widget.colorScheme,
        controller: widget.controller,
        weekIndex: widget.weekIndex,
        workoutIndex: widget.workoutIndex,
      ),
    );
  }

  void _showMoveExerciseDialog(Exercise exercise) {
    final week = widget.controller.program.weeks[widget.weekIndex];

    showDialog(
      context: context,
      builder: (context) => MoveExerciseDialog(
        workouts: week.workouts,
        currentWorkoutIndex: widget.workoutIndex,
        colorScheme: widget.colorScheme,
        onWorkoutSelected: (destinationIndex) =>
            _moveExercise(exercise, destinationIndex),
      ),
    );
  }

  void _showAddToSuperSetDialog(Exercise exercise) {
    final superSetsData = widget
        .controller
        .program
        .weeks[widget.weekIndex]
        .workouts[widget.workoutIndex]
        .superSets;

    if (superSetsData?.isEmpty ?? true) {
      _createNewSuperSetAndAdd(exercise);
    } else {
      // Converte i superSets da Map a SuperSet
      final superSets = superSetsData!.map((superSetMap) {
        return SuperSet(
          id: superSetMap['id'] ?? '',
          name: superSetMap['name'],
          exerciseIds: List<String>.from(superSetMap['exerciseIds'] ?? []),
        );
      }).toList();

      showDialog(
        context: context,
        builder: (context) => SuperSetSelectionDialog(
          exercise: exercise,
          superSets: superSets,
          colorScheme: widget.colorScheme,
          onSuperSetSelected: (superSetId) =>
              _addToSuperSet(exercise, superSetId),
          onCreateNewSuperSet: () => _createNewSuperSetAndAdd(exercise),
        ),
      );
    }
  }

  void _showUpdateMaxRMDialog(Exercise exercise) {
    showDialog(
      context: context,
      builder: (context) => UpdateMaxRMDialog(
        exercise: exercise,
        colorScheme: widget.colorScheme,
        onSave: (maxWeight, repetitions) =>
            _saveMaxRM(exercise, maxWeight, repetitions),
      ),
    );
  }

  void _showReorderExercisesDialog() {
    final exerciseNames = training_exercise_utils
        .ExerciseUtils.formatExerciseNames(widget.exercises);

    showDialog(
      context: context,
      builder: (context) =>
          ReorderDialog(items: exerciseNames, onReorder: _reorderExercises),
    );
  }

  // ========== METODI DI SUPPORTO ==========

  void _moveExercise(Exercise exercise, int destinationWorkoutIndex) {
    try {
      widget.controller.moveExercise(
        widget.weekIndex,
        widget.workoutIndex,
        destinationWorkoutIndex,
        exercise.order - 1,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: widget.colorScheme.onPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text('Esercizio spostato con successo'),
            ],
          ),
          backgroundColor: widget.colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: widget.colorScheme.onError,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text('Errore nello spostamento: $e'),
            ],
          ),
          backgroundColor: widget.colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _createNewSuperSetAndAdd(Exercise exercise) {
    widget.controller.createSuperSet(widget.weekIndex, widget.workoutIndex);
    final superSetsData = widget
        .controller
        .program
        .weeks[widget.weekIndex]
        .workouts[widget.workoutIndex]
        .superSets;
    final newSuperSetId = superSetsData?.first['id'] ?? '';
    _addToSuperSet(exercise, newSuperSetId);
  }

  void _addToSuperSet(Exercise exercise, String superSetId) {
    widget.controller.addExerciseToSuperSet(
      widget.weekIndex,
      widget.workoutIndex,
      superSetId,
      exercise.id!,
    );
  }

  Future<void> _saveMaxRM(
    Exercise exercise,
    double maxWeight,
    int repetitions,
  ) async {
    try {
      await ExerciseService.updateMaxRM(
        exerciseRecordService: widget.exerciseRecordService,
        athleteId: widget.athleteId,
        exercise: exercise,
        maxWeight: maxWeight,
        repetitions: repetitions,
        exerciseType: exercise.type,
      );

      widget.controller.updateExercise(exercise);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Max RM aggiornato con successo'),
            backgroundColor: widget.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nell\'aggiornamento: $e'),
            backgroundColor: widget.colorScheme.error,
          ),
        );
      }
    }
  }

  void _reorderExercises(int oldIndex, int newIndex) {
    widget.controller.reorderExercises(
      widget.weekIndex,
      widget.workoutIndex,
      oldIndex,
      newIndex,
    );

    // Mostra notifica di successo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: widget.colorScheme.onPrimary,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text('Esercizi riordinati con successo'),
          ],
        ),
        backgroundColor: widget.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ========== METODI DI NAVIGAZIONE ==========

  void _navigateToProgressions(Exercise exercise, num latestMaxWeight) {
    Navigator.push<Exercise>(
      context,
      MaterialPageRoute(
        builder: (context) => ProgressionsList(
          exerciseId: exercise.exerciseId!,
          exercise: exercise,
          latestMaxWeight: latestMaxWeight,
        ),
      ),
    ).then((updatedExercise) {
      if (updatedExercise != null) {
        widget.controller.updateExercise(updatedExercise);
      }
    });
  }

  void _navigateToExerciseDetails(Exercise exercise, List<SuperSet> superSets) {
    final superSetExerciseIndex = superSets.isNotEmpty
        ? superSets.indexWhere((ss) => ss.exerciseIds.contains(exercise.id))
        : 0;

    context.go(
      '/user_programs/training_viewer/week_details/workout_details/exercise_details',
      extra: {
        'programId': widget.controller.program.id,
        'weekId': widget.controller.program.weeks[widget.weekIndex].id,
        'workoutId': widget
            .controller
            .program
            .weeks[widget.weekIndex]
            .workouts[widget.workoutIndex]
            .id,
        'exerciseId': exercise.id,
        'userId': widget.controller.program.athleteId,
        'superSetExercises': superSets.map((s) => s.toMap()).toList(),
        'superSetExerciseIndex': superSetExerciseIndex,
        'seriesList': exercise.series.map((s) => s.toMap()).toList(),
        'startIndex': 0,
      },
    );
  }
}
