import 'package:alphanessone/models/exercise_record.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/ExerciseRecords/exercise_record_services.dart';
import 'package:alphanessone/trainingBuilder/models/exercise_model.dart';
import 'package:alphanessone/trainingBuilder/List/progressions_list.dart';
import 'package:alphanessone/trainingBuilder/utility_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../controller/training_program_controller.dart';
import 'series_list.dart';
import '../dialog/reorder_dialog.dart';
import '../../UI/components/card.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/trainingBuilder/models/superseries_model.dart';
import 'package:alphanessone/UI/components/bottom_menu.dart';

class TrainingProgramExerciseList extends ConsumerWidget {
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
    final dateFormat = DateFormat('yyyy-MM-dd');
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
              // Exercises List
              SliverPadding(
                padding: EdgeInsets.all(AppTheme.spacing.xl),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == exercises.length) {
                        return _buildAddExerciseButton(context, colorScheme, theme);
                      }
                      return _buildExerciseCard(
                        context,
                        exercises[index],
                        exerciseRecordService,
                        athleteId,
                        dateFormat,
                        theme,
                        colorScheme,
                      );
                    },
                    childCount: exercises.length + 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    Exercise exercise,
    ExerciseRecordService exerciseRecordService,
    String athleteId,
    DateFormat dateFormat,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final superSets = controller
        .program.weeks[weekIndex].workouts[workoutIndex].superSets
        .where((ss) => ss.exerciseIds.contains(exercise.id))
        .toList();

    return FutureBuilder<num>(
      future: getLatestMaxWeight(
        exerciseRecordService,
        athleteId,
        exercise.exerciseId ?? '',
      ),
      builder: (context, snapshot) {
        final latestMaxWeight = snapshot.data ?? 0;

        return Container(
          margin: EdgeInsets.only(bottom: AppTheme.spacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radii.lg),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.1),
            ),
            boxShadow: AppTheme.elevations.small,
          ),
          child: Slidable(
            startActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (context) => controller.addExercise(weekIndex, workoutIndex, context),
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
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (context) => controller.removeExercise(
                    weekIndex,
                    workoutIndex,
                    exercise.order - 1,
                  ),
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
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => controller.editExercise(
                  weekIndex,
                  workoutIndex,
                  exercise.order - 1,
                  context,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                              Icons.more_vert,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () => _showExerciseOptions(
                              context,
                              exercise,
                              exerciseRecordService,
                              athleteId,
                              dateFormat,
                              latestMaxWeight,
                              colorScheme,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: AppTheme.spacing.md),

                      // Exercise Name and Variant
                      Text(
                        exercise.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),

                      if (exercise.variant.isNotEmpty && exercise.variant != '') ...[
                        SizedBox(height: AppTheme.spacing.xs),
                        Text(
                          exercise.variant,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],

                      SizedBox(height: AppTheme.spacing.lg),

                      // Series List
                      TrainingProgramSeriesList(
                        controller: controller,
                        exerciseRecordService: exerciseRecordService,
                        weekIndex: weekIndex,
                        workoutIndex: workoutIndex,
                        exerciseIndex: exercise.order - 1,
                        exerciseType: exercise.type,
                      ),

                      // Superset Badge
                      if (superSets.isNotEmpty) ...[
                        SizedBox(height: AppTheme.spacing.md),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing.md,
                            vertical: AppTheme.spacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.group_work,
                                size: 18,
                                color: colorScheme.secondary,
                              ),
                              SizedBox(width: AppTheme.spacing.xs),
                              Text(
                                'Superset',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colorScheme.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddExerciseButton(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
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
          onTap: () => controller.addExercise(weekIndex, workoutIndex, context),
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
                  'Add Exercise',
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

  void _showExerciseOptions(
    BuildContext context,
    Exercise exercise,
    ExerciseRecordService exerciseRecordService,
    String athleteId,
    DateFormat dateFormat,
    num latestMaxWeight,
    ColorScheme colorScheme,
  ) {
    final workout = controller.program.weeks[weekIndex].workouts[workoutIndex];
    final superSet = workout.superSets.firstWhere(
      (ss) => ss.exerciseIds.contains(exercise.id),
      orElse: () => SuperSet(id: '', exerciseIds: []),
    );
    final isInSuperSet = superSet.id.isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BottomMenu(
        title: exercise.name,
        subtitle: exercise.variant,
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
            title: 'Modifica',
            icon: Icons.edit_outlined,
            onTap: () => controller.editExercise(
              weekIndex,
              workoutIndex,
              exercise.order - 1,
              context,
            ),
          ),
          BottomMenuItem(
            title: 'Sposta Esercizio',
            icon: Icons.move_up,
            onTap: () => _showMoveExerciseDialog(
              context,
              weekIndex,
              workoutIndex,
              exercise,
            ),
          ),
          BottomMenuItem(
            title: 'Duplica Esercizio',
            icon: Icons.content_copy_outlined,
            onTap: () => controller.duplicateExercise(
              weekIndex,
              workoutIndex,
              exercise.order - 1,
            ),
          ),
          if (!isInSuperSet)
            BottomMenuItem(
              title: 'Aggiungi a Super Set',
              icon: Icons.group_add_outlined,
              onTap: () => _showAddToSuperSetDialog(
                context,
                exercise,
                colorScheme,
              ),
            ),
          if (isInSuperSet)
            BottomMenuItem(
              title: 'Rimuovi da Super Set',
              icon: Icons.group_remove_outlined,
              onTap: () => controller.removeExerciseFromSuperSet(
                weekIndex,
                workoutIndex,
                superSet.id,
                exercise.id!,
              ),
            ),
          BottomMenuItem(
            title: 'Imposta Progressione',
            icon: Icons.trending_up,
            onTap: () => _showSetProgressionScreen(
              context,
              exercise,
              latestMaxWeight,
              colorScheme,
            ),
          ),
          BottomMenuItem(
            title: 'Aggiorna Max RM',
            icon: Icons.fitness_center,
            onTap: () => _addOrUpdateMaxRM(
              exercise,
              context,
              exerciseRecordService,
              athleteId,
              dateFormat,
              colorScheme,
            ),
          ),
          BottomMenuItem(
            title: 'Elimina',
            icon: Icons.delete_outline,
            onTap: () => controller.removeExercise(
              weekIndex,
              workoutIndex,
              exercise.order - 1,
            ),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  void _showMoveExerciseDialog(
    BuildContext context,
    int weekIndex,
    int sourceWorkoutIndex,
    Exercise exercise,
  ) {
    final sourceExerciseIndex = exercise.order - 1;
    final week = controller.program.weeks[weekIndex];

    showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Seleziona l\'Allenamento di Destinazione'),
          content: DropdownButtonFormField<int>(
            value: null,
            items: List.generate(
              week.workouts.length,
              (index) => DropdownMenuItem(
                value: index,
                child: Text('Allenamento ${week.workouts[index].order}'),
              ),
            ),
            onChanged: (value) {
              Navigator.pop(dialogContext, value);
            },
            decoration: const InputDecoration(
              labelText: 'Allenamento di Destinazione',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annulla'),
            ),
          ],
        );
      },
    ).then((destinationWorkoutIndex) {
      if (destinationWorkoutIndex != null && destinationWorkoutIndex != sourceWorkoutIndex) {
        controller.moveExercise(
          weekIndex,
          sourceWorkoutIndex,
          sourceExerciseIndex,
          weekIndex,
          destinationWorkoutIndex,
        );
      }
    });
  }

  void _addOrUpdateMaxRM(
    Exercise exercise,
    BuildContext context,
    ExerciseRecordService exerciseRecordService,
    String athleteId,
    DateFormat dateFormat,
    ColorScheme colorScheme,
  ) {
    exerciseRecordService.getLatestExerciseRecord(
      userId: athleteId,
      exerciseId: exercise.exerciseId!,
    ).then((record) {
      final maxWeightController = TextEditingController(text: record?.maxWeight.toString() ?? '');
      final repetitionsController = TextEditingController(text: record?.repetitions.toString() ?? '');

      repetitionsController.addListener(() {
        var repetitions = int.tryParse(repetitionsController.text) ?? 0;
        if (repetitions > 1) {
          final maxWeight = double.tryParse(maxWeightController.text) ?? 0;
          final calculatedMaxWeight = roundWeight(maxWeight / (1.0278 - (0.0278 * repetitions)), exercise.type);
          maxWeightController.text = calculatedMaxWeight.toString();
          repetitionsController.text = '1';
        }
      });

      showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            backgroundColor: colorScheme.surface,
            title: Text(
              'Aggiorna Max RM',
              style: TextStyle(
                color: colorScheme.onSurface,
              ),
            ),
            content: _buildMaxRMInputFields(maxWeightController, repetitionsController, colorScheme),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(
                  'Annulla',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: const Text('Salva'),
              ),
            ],
          );
        },
      ).then((result) {
        if (result == true) {
          _saveMaxRM(
            record,
            athleteId,
            exercise,
            maxWeightController,
            repetitionsController,
            exerciseRecordService,dateFormat,
            exercise.type,
          );
        }
      });
    });
  }

  Widget _buildMaxRMInputFields(
    TextEditingController maxWeightController,
    TextEditingController repetitionsController,
    ColorScheme colorScheme,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: maxWeightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+[\.,]?\d*')),
            TextInputFormatter.withFunction((oldValue, newValue) {
              final text = newValue.text.replaceAll(',', '.');
              return newValue.copyWith(
                text: text,
                selection: TextSelection.collapsed(offset: text.length),
              );
            }),
          ],
          style: TextStyle(
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            labelText: 'Peso Massimo',
            labelStyle: TextStyle(
              color: colorScheme.onSurface,
            ),
          ),
        ),
        TextField(
          controller: repetitionsController,
          keyboardType: TextInputType.number,
          style: TextStyle(
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            labelText: 'Ripetizioni',
            labelStyle: TextStyle(
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  void _saveMaxRM(
    ExerciseRecord? record,
    String athleteId,
    Exercise exercise,
    TextEditingController maxWeightController,
    TextEditingController repetitionsController,
    ExerciseRecordService exerciseRecordService,
    DateFormat dateFormat,
    String exerciseType,
  ) {
    final maxWeight = double.tryParse(maxWeightController.text) ?? 0;
    final roundedMaxWeight = roundWeight(maxWeight, exercise.type);

    if (record != null) {
      exerciseRecordService.updateExerciseRecord(
        userId: athleteId,
        exerciseId: exercise.exerciseId!,
        recordId: record.id,
        maxWeight: roundedMaxWeight.round(),
        repetitions: 1,
      );
    } else {
      exerciseRecordService.addExerciseRecord(
        userId: athleteId,
        exerciseId: exercise.exerciseId!,
        exerciseName: exercise.name,
        maxWeight: roundedMaxWeight.round(),
        repetitions: 1,
        date: dateFormat.format(DateTime.now()),
      );
    }

    controller.updateExercise(exercise);
  }

  void _showReorderExercisesDialog(
    BuildContext context,
    int weekIndex,
    int workoutIndex
  ) {
    final exerciseNames = controller
        .program.weeks[weekIndex].workouts[workoutIndex].exercises
        .map((exercise) => exercise.name)
        .toList();
    showDialog(
      context: context,
      builder: (context) => ReorderDialog(
        items: exerciseNames,
        onReorder: (oldIndex, newIndex) => controller.reorderExercises(
            weekIndex, workoutIndex, oldIndex, newIndex),
      ),
    );
  }

  void _showAddToSuperSetDialog(
    BuildContext context,
    Exercise exercise,
    ColorScheme colorScheme,
  ) {
    String? selectedSuperSetId;
    final superSets = controller.program.weeks[weekIndex].workouts[workoutIndex].superSets;

    if (superSets.isEmpty) {
      controller.createSuperSet(weekIndex, workoutIndex);
      selectedSuperSetId = controller.program.weeks[weekIndex].workouts[workoutIndex].superSets.first.id;
      controller.addExerciseToSuperSet(
        weekIndex,
        workoutIndex,
        selectedSuperSetId,
        exercise.id!,
      );
    } else {
      showDialog<String>(
        context: context,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(
            builder: (BuildContext builderContext, setState) {
              return AlertDialog(
                backgroundColor: colorScheme.surface,
                title: Text(
                  'Aggiungi al Superset',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                  ),
                ),
                content: DropdownButtonFormField<String>(
                  value: selectedSuperSetId,
                  items: superSets.map((ss) {
                    return DropdownMenuItem<String>(
                      value: ss.id,
                      child: Text(
                        ss.name ?? '',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedSuperSetId = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Seleziona il Superset',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(null),
                    child: Text(
                      'Annulla',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (superSets.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        controller.createSuperSet(weekIndex, workoutIndex);
                        setState(() {});
                        Navigator.of(dialogContext).pop(superSets.last.id);
                      },
                      child: Text(
                        'Crea Nuovo Superset',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(selectedSuperSetId),
                    child: Text(
                      'Aggiungi',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ).then((result) {
        if (result != null) {
          controller.addExerciseToSuperSet(
            weekIndex,
            workoutIndex,
            result,
            exercise.id!,
          );
        }
      });
    }
  }

  void _showSetProgressionScreen(
    BuildContext context,
    Exercise exercise,
    num latestMaxWeight,
    ColorScheme colorScheme,
  ) {
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
        controller.updateExercise(updatedExercise);
      }
    });
  }
}