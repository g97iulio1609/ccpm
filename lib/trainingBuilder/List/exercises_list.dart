// exercise_list.dart
import 'package:alphanessone/models/exercise_record.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/services/exercise_record_services.dart';
import 'package:alphanessone/trainingBuilder/models/exercise_model.dart';
import 'package:alphanessone/trainingBuilder/List/progressions_list.dart';
import 'package:alphanessone/trainingBuilder/utility_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:alphanessone/trainingBuilder/models/training_model.dart';

import '../controller/training_program_controller.dart';
import 'series_list.dart';
import '../dialog/reorder_dialog.dart';

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
    final isDarkMode = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return ListView.builder(
      shrinkWrap: true,
      itemCount: exercises.length + 1,
      itemBuilder: (context, index) {
        if (index == exercises.length) {
          return _buildAddExerciseButton(context, isDarkMode, colorScheme);
        }
        return _buildExerciseCard(context, exercises[index], exerciseRecordService,
            athleteId, dateFormat, isDarkMode, colorScheme);
      },
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    Exercise exercise,
    ExerciseRecordService exerciseRecordService,
    String athleteId,
    DateFormat dateFormat,
    bool isDarkMode,
    ColorScheme colorScheme,
  ) {
    final superSets = controller
        .program.weeks[weekIndex].workouts[workoutIndex].superSets
        .where((ss) => ss.exerciseIds.contains(exercise.id))
        .toList();

    return FutureBuilder<num>(
      future: getLatestMaxWeight(
          exerciseRecordService, athleteId, exercise.exerciseId ?? ''),
      builder: (context, snapshot) {
        final latestMaxWeight = snapshot.data ?? 0;
        return Slidable(
          startActionPane: ActionPane(
            motion: const DrawerMotion(),
            children: [
              SlidableAction(
                onPressed: (context) =>
                    controller.addExercise(weekIndex, workoutIndex, context),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                icon: Icons.add,
                label: 'Aggiungi Esercizio',
              ),
            ],
          ),
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            children: [
              SlidableAction(
                onPressed: (context) => controller.removeExercise(
                    weekIndex, workoutIndex, exercise.order - 1),
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
                icon: Icons.delete,
                label: 'Elimina',
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? colorScheme.surface : colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildExerciseHeader(
                      context,
                      exercise,
                      exerciseRecordService,
                      athleteId,
                      dateFormat,
                      latestMaxWeight,
                      isDarkMode,
                      colorScheme),
                  if (superSets.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: superSets
                            .map((ss) => Icon(Icons.group_work,
                                color: colorScheme.primary))
                            .toList(),
                      ),
                    ),
                  const SizedBox(height: 16),
                  _buildExerciseSeries(context, exercise, exerciseRecordService),
                  const SizedBox(height: 16),
                  Center(
                    child: _buildAddSeriesButton(
                        context, exercise, isDarkMode, colorScheme),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExerciseHeader(
    BuildContext context,
    Exercise exercise,
    ExerciseRecordService exerciseRecordService,
    String athleteId,
    DateFormat dateFormat,
    num latestMaxWeight,
    bool isDarkMode,
    ColorScheme colorScheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => controller.editExercise(
                weekIndex, workoutIndex, exercise.order - 1, context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  exercise.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                  textAlign: TextAlign.center,
                ),
                if (exercise.variant.isNotEmpty)
                  Text(
                    exercise.variant,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
        
        _buildExercisePopupMenu(context, exercise, exerciseRecordService, athleteId,
            dateFormat, latestMaxWeight, isDarkMode, colorScheme),
      ],
    );
  }

  Widget _buildExercisePopupMenu(
    BuildContext context,
    Exercise exercise,
    ExerciseRecordService exerciseRecordService,
    String athleteId,
    DateFormat dateFormat,
    num latestMaxWeight,
    bool isDarkMode,
    ColorScheme colorScheme,
  ) {
    return PopupMenuButton(
      color: isDarkMode ? colorScheme.surface : colorScheme.surface,
      itemBuilder: (context) => [
        PopupMenuItem(
          child: Text(
            'Modifica',
            style: TextStyle(
              color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
            ),
          ),
          onTap: () => controller.editExercise(
              weekIndex, workoutIndex, exercise.order - 1, context),
        ),
        PopupMenuItem(
          child: Text(
            'Aggiorna Max RM',
            style: TextStyle(
              color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
            ),
          ),
          onTap: () => _addOrUpdateMaxRM(exercise, context, exerciseRecordService,
              athleteId, dateFormat, isDarkMode, colorScheme),
        ),
        PopupMenuItem(
          child: Text(
            'Riordina Esercizi',
            style: TextStyle(
              color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
            ),
          ),
          onTap: () => _showReorderExercisesDialog(context, weekIndex, workoutIndex),
        ),
        PopupMenuItem(
          child: Text(
            'Aggiungi al Superset',
            style: TextStyle(
              color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
            ),
          ),
          onTap: () => _showAddToSuperSetDialog(
              context, exercise, isDarkMode, colorScheme),
        ),
        if (exercise.superSetId != null)
          PopupMenuItem(
            child: Text(
              'Rimuovi dal Superset',
              style: TextStyle(
                color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
              ),
            ),
            onTap: () => controller.removeExerciseFromSuperSet(
                weekIndex, workoutIndex, exercise.superSetId!, exercise.id!),
          ),
        PopupMenuItem(
          child: Text(
            'Set Progression',
            style: TextStyle(
              color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
            ),
          ),
          onTap: () => _showSetProgressionScreen(
              context, exercise, latestMaxWeight, isDarkMode, colorScheme),
        ),
        PopupMenuItem(
          child: Text(
            'Duplica Esercizio',
            style: TextStyle(
              color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
            ),
          ),
          onTap: () => controller.duplicateExercise(
              weekIndex, workoutIndex, exercise.order - 1),
        ),
        PopupMenuItem(
          child: Text(
            'Sposta Esercizio',
            style: TextStyle(
              color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
            ),
          ),
          onTap: () => _showMoveExerciseDialog(context, weekIndex, workoutIndex, exercise),
        ),
        PopupMenuItem(
          child: Text(
            'Elimina',
            style: TextStyle(
              color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
            ),
          ),
          onTap: () => controller.removeExercise(
              weekIndex, workoutIndex, exercise.order - 1),
        ),
      ],
    );
  }

  Widget _buildExerciseSeries(
    BuildContext context,
    Exercise exercise,
    ExerciseRecordService exerciseRecordService,
  ) {
    return TrainingProgramSeriesList(
      controller: controller,
      exerciseRecordService: exerciseRecordService,
      weekIndex: weekIndex,
      workoutIndex: workoutIndex,
      exerciseIndex: exercise.order - 1,
      exerciseType: exercise.type,
    );
  }

  Widget _buildAddSeriesButton(
    BuildContext context,
    Exercise exercise,
    bool isDarkMode,
    ColorScheme colorScheme,
  ) {
    return ElevatedButton(
      onPressed: () => controller.addSeries(weekIndex, workoutIndex,
          exercise.order - 1, exercise.type ?? '', context),
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        'Aggiungi Nuova Serie',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
      ),
    );
  }

  Widget _buildAddExerciseButton(
    BuildContext context,
    bool isDarkMode,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () =>
            controller.addExercise(weekIndex, workoutIndex, context),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'Aggiungi Esercizio',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
        ),
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
    bool isDarkMode,
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
            backgroundColor: isDarkMode ? colorScheme.surface : colorScheme.surface,
            title: Text(
              'Aggiorna Max RM',
              style: TextStyle(
                color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
              ),
            ),
            content: _buildMaxRMInputFields(maxWeightController, repetitionsController, isDarkMode, colorScheme),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(
                  'Annulla',
                  style: TextStyle(
                    color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? colorScheme.primary : colorScheme.secondary,
                  foregroundColor: isDarkMode ? colorScheme.onPrimary : colorScheme.onSecondary,
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
            exerciseRecordService,
            dateFormat,
            exercise.type,
          );
        }
      });
    });
  }

  Widget _buildMaxRMInputFields(
    TextEditingController maxWeightController,
    TextEditingController repetitionsController,
    bool isDarkMode,
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
            color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            labelText: 'Peso Massimo',
            labelStyle: TextStyle(
              color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
            ),
          ),
        ),
        TextField(
          controller: repetitionsController,
          keyboardType: TextInputType.number,
          style: TextStyle(
            color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            labelText: 'Ripetizioni',
            labelStyle: TextStyle(
              color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
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

  void _createNewSuperSet(
    BuildContext context,
    bool isDarkMode,
    ColorScheme colorScheme
  ) {
    showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? colorScheme.surface : colorScheme.surface,
        title: Text(
          'Nuovo Superset',
          style: TextStyle(
            color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
          ),
        ),
        content: TextField(
          autofocus: true,
          style: TextStyle(
            color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            labelText: 'Nome Superset',
            labelStyle: TextStyle(
              color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
            ),
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Annulla',
              style: TextStyle(
                color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final textFieldController = TextEditingController();
              Navigator.of(context).pop(textFieldController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? colorScheme.primary : colorScheme.secondary,
              foregroundColor: isDarkMode ? colorScheme.onPrimary : colorScheme.onSecondary,
            ),
            child: const Text('Crea'),
          ),
        ],
      ),
    ).then((superSetName) {
      if (superSetName != null && superSetName.isNotEmpty) {
        controller.createSuperSet(weekIndex, workoutIndex);
      }
    });
  }

  void _showAddToSuperSetDialog(
    BuildContext context,
    Exercise exercise,
    bool isDarkMode,
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
                backgroundColor: isDarkMode ? colorScheme.surface : colorScheme.surface,
                title: Text(
                  'Aggiungi al Superset',
                  style: TextStyle(
                    color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
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
                          color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
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
                      color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(null),
                    child: Text(
                      'Annulla',
                      style: TextStyle(
                        color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
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
                          color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(selectedSuperSetId),
                    child: Text(
                      'Aggiungi',
                      style: TextStyle(
                        color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
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

  void _showRemoveFromSuperSetDialog(
    BuildContext context,
    Exercise exercise,
    bool isDarkMode,
    ColorScheme colorScheme
  ) {
    final superSets = controller
        .program.weeks[weekIndex].workouts[workoutIndex].superSets
        .where((ss) => ss.exerciseIds.contains(exercise.id))
        .toList();

    if (superSets.isEmpty) {
      return;
    }

    showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? colorScheme.surface : colorScheme.surface,
        title: Text(
          'Rimuovi dal Superset',
          style: TextStyle(
            color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
          ),
        ),
        content: DropdownButtonFormField<String>(
          value: null,
          items: superSets.map((ss) {
            return DropdownMenuItem<String>(
              value: ss.id,
              child: Text(
                'Superset ${ss.id}',
                style: TextStyle(
                  color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) => Navigator.of(context).pop(value),
          decoration: InputDecoration(
            hintText: 'Seleziona il Superset',
            hintStyle: TextStyle(
              color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annulla',
              style: TextStyle(
                color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    ).then((superSetId) {
      if (superSetId != null) {
        controller.removeExerciseFromSuperSet(
            weekIndex, workoutIndex, superSetId, exercise.id!);
      }
    });
  }

  void _showSetProgressionScreen(
    BuildContext context,
    Exercise exercise,
    num latestMaxWeight,
    bool isDarkMode,
    ColorScheme colorScheme,
  ) {
    Navigator.push<Exercise>(
      context,
      MaterialPageRoute(
        builder: (context) => SetProgressionScreen(
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