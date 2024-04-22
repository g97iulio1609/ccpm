// exercise_list.dart
import 'package:alphanessone/trainingBuilder/set_progression.dart';
import 'package:alphanessone/trainingBuilder/utility_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'training_model.dart';
import 'controller/training_program_controller.dart';
import 'series_list.dart';
import '../users_services.dart';
import 'reorder_dialog.dart';

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
        return _buildExerciseCard(context, exercises[index], usersService,
            athleteId, dateFormat, isDarkMode, colorScheme);
      },
    );
  }

Widget _buildExerciseCard(
  BuildContext context,
  Exercise exercise,
  UsersService usersService,
  String athleteId,
  DateFormat dateFormat,
  bool isDarkMode,
  ColorScheme colorScheme,
) {
  final superSets = controller.program.weeks[weekIndex].workouts[workoutIndex]
      .superSets
      .where((ss) => ss.exerciseIds.contains(exercise.id))
      .toList();

  return FutureBuilder<num>(
    future: getLatestMaxWeight(usersService, athleteId, exercise.exerciseId ?? ''),
    builder: (context, snapshot) {
      final latestMaxWeight = snapshot.data ?? 0;
      return Slidable(
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (context) => controller.addExercise(weekIndex, workoutIndex, context),
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
              onPressed: (context) => controller.removeExercise(weekIndex, workoutIndex, exercise.order - 1),
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
              icon: Icons.delete,
              label: 'Elimina',
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? colorScheme.surface : colorScheme.background,
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
              _buildExerciseHeader(context, exercise, usersService, athleteId,
                  dateFormat, latestMaxWeight, isDarkMode, colorScheme),
              if (superSets.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: superSets
                        .map((ss) => Icon(Icons.group_work, color: colorScheme.primary))
                        .toList(),
                  ),
                ),
              const SizedBox(height: 16),
              _buildExerciseSeries(context, exercise, usersService),
              const SizedBox(height: 16),
              Center(
                child: _buildAddSeriesButton(context, exercise, isDarkMode,
                    colorScheme),
              ),
            ],
          ),
        ),
      );
    },
  );
}
Widget _buildExerciseHeader(
  BuildContext context,
  Exercise exercise,
  UsersService usersService,
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
      _buildExercisePopupMenu(context, exercise, usersService, athleteId,
          dateFormat, latestMaxWeight, isDarkMode, colorScheme),
    ],
  );
}

  Widget _buildExercisePopupMenu(
    BuildContext context,
    Exercise exercise,
    UsersService usersService,
    String athleteId,
    DateFormat dateFormat,
    num latestMaxWeight,
    bool isDarkMode,
    ColorScheme colorScheme,
  ) {
    return PopupMenuButton(
      color: isDarkMode ? colorScheme.surface : colorScheme.background,
      itemBuilder: (context) => [
        PopupMenuItem(
          child: Text(
            'Modifica',
            style: TextStyle(
              color:
                  isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
            ),
          ),
          onTap: () => controller.editExercise(
              weekIndex, workoutIndex, exercise.order - 1, context),
        ),
        PopupMenuItem(
          child: Text(
            'Aggiorna Max RM',
            style: TextStyle(
              color:
                  isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
            ),
          ),
          onTap: () => _addOrUpdateMaxRM(exercise, context, usersService,
              athleteId, dateFormat, isDarkMode, colorScheme),
        ),
        PopupMenuItem(
          child: Text(
            'Riordina Esercizi',
            style: TextStyle(
              color:
                  isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
            ),
          ),
          onTap: () =>
              _showReorderExercisesDialog(context, weekIndex, workoutIndex),
        ),
        PopupMenuItem(
          child: Text(
            'Aggiungi al Superset',
            style: TextStyle(
              color:
                  isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
            ),
          ),
          onTap: () => _showAddToSuperSetDialog(context, exercise, isDarkMode,
              colorScheme),
        ),
        if (exercise.superSetId != null)
          PopupMenuItem(
            child: Text(
              'Rimuovi dal Superset',
              style: TextStyle(
                color: isDarkMode
                    ? colorScheme.onSurface
                    : colorScheme.onBackground,
              ),
            ),
            onTap: () => controller.removeExerciseFromSuperSet(
                weekIndex, workoutIndex, exercise.superSetId!, exercise.id!),
          ),
        PopupMenuItem(
          child: Text(
            'Set Progression',
            style: TextStyle(
              color:
                  isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
            ),
          ),
          onTap: () => _showSetProgressionScreen(context, exercise,
              latestMaxWeight, isDarkMode, colorScheme),
        ),
      ],
    );
  }

  Widget _buildExerciseSeries(
    BuildContext context,
    Exercise exercise,
    UsersService usersService,
  ) {
    return TrainingProgramSeriesList(
      controller: controller,
      usersService: usersService,
      weekIndex: weekIndex,
      workoutIndex: workoutIndex,
      exerciseIndex: exercise.order - 1,
    );
  }

  Widget _buildAddSeriesButton(
    BuildContext context,
    Exercise exercise,
    bool isDarkMode,
    ColorScheme colorScheme,
  ) {
    return ElevatedButton(
      onPressed: () => controller.addSeries(
          weekIndex, workoutIndex, exercise.order - 1, context),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDarkMode ? colorScheme.primary : colorScheme.secondary,
        foregroundColor:
            isDarkMode ? colorScheme.onPrimary : colorScheme.onSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text('Aggiungi Nuova Serie'),
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
        onPressed: () => controller.addExercise(weekIndex, workoutIndex, context),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDarkMode ? colorScheme.primary : colorScheme.secondary,
          foregroundColor:
              isDarkMode ? colorScheme.onPrimary : colorScheme.onSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text('Aggiungi Esercizio'),
      ),
    );
  }

  Future<void> _addOrUpdateMaxRM(
    Exercise exercise,
    BuildContext context,
    UsersService usersService,
    String athleteId,
    DateFormat dateFormat,
    bool isDarkMode,
    ColorScheme colorScheme,
  ) async {
    final record = await usersService.getLatestExerciseRecord(
        userId: athleteId, exerciseId: exercise.exerciseId!);

    final maxWeightController =
        TextEditingController(text: record?.maxWeight.toString() ?? '');
    final repetitionsController =
        TextEditingController(text: record?.repetitions.toString() ?? '');

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? colorScheme.surface : colorScheme.background,
          title: Text(
            'Aggiorna Max RM',
            style: TextStyle(
              color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
            ),
          ),
          content: _buildMaxRMInputFields(maxWeightController, repetitionsController,
              isDarkMode, colorScheme),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Annulla',
                style: TextStyle(
                  color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await _saveMaxRM(
                  record,
                  athleteId,
                  exercise,
                  maxWeightController,
                  repetitionsController,
                  usersService,
                  dateFormat,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDarkMode ? colorScheme.primary : colorScheme.secondary,
                foregroundColor:
                    isDarkMode ? colorScheme.onPrimary : colorScheme.onSecondary,
              ),
              child: const Text('Salva'),
            ),
          ],
        );
      },
    );
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
            color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
          ),
          decoration: InputDecoration(
            labelText: 'Peso Massimo',
            labelStyle: TextStyle(
              color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
            ),
          ),
        ),
        TextField(
          controller: repetitionsController,
          keyboardType: TextInputType.number,
          style: TextStyle(
            color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
          ),
          decoration: InputDecoration(
            labelText: 'Ripetizioni',
            labelStyle: TextStyle(
              color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveMaxRM(
    ExerciseRecord? record,
    String athleteId,
    Exercise exercise,
    TextEditingController maxWeightController,
    TextEditingController repetitionsController,
    UsersService usersService,
    DateFormat dateFormat,
  ) async {
    final maxWeight = int.tryParse(maxWeightController.text) ?? 0;
    final repetitions = int.tryParse(repetitionsController.text) ?? 0;

    if (record != null) {
      await usersService.updateExerciseRecord(
        userId: athleteId,
        exerciseId: exercise.exerciseId!,
        recordId: record.id,
        maxWeight: maxWeight,
        repetitions: repetitions,
      );
    } else {
      await usersService.addExerciseRecord(
        userId: athleteId,
        exerciseId: exercise.exerciseId!,
        exerciseName: exercise.name,
        maxWeight: maxWeight,
        repetitions: repetitions,
        date: dateFormat.format(DateTime.now()),
      );
    }
  }

  void _showReorderExercisesDialog(
      BuildContext context, int weekIndex, int workoutIndex) {
    final exerciseNames =
        controller.program.weeks[weekIndex].workouts[workoutIndex].exercises
            .map((exercise) => exercise.name)
            .toList();
    showDialog(
      context: context,
      builder: (context) => ReorderDialog(
        items: exerciseNames,
        onReorder: (oldIndex, newIndex) =>
            controller.reorderExercises(weekIndex, workoutIndex, oldIndex, newIndex),
      ),
    );
  }

  Future<void> _createNewSuperSet(
      BuildContext context, bool isDarkMode, ColorScheme colorScheme) async {
    final superSetName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? colorScheme.surface : colorScheme.background,
        title: Text(
          'Nuovo Superset',
          style: TextStyle(
            color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
          ),
        ),
        content: TextField(
          autofocus: true,
          style: TextStyle(
            color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
          ),
          decoration: InputDecoration(
            labelText: 'Nome Superset',
            labelStyle: TextStyle(
              color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
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
                color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final textFieldController = TextEditingController();
              Navigator.of(context).pop(textFieldController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDarkMode ? colorScheme.primary : colorScheme.secondary,
              foregroundColor:
                  isDarkMode ? colorScheme.onPrimary : colorScheme.onSecondary,
            ),
            child: const Text('Crea'),
          ),
        ],
      ),
    );

    if (superSetName != null && superSetName.isNotEmpty) {
      controller.createSuperSet(weekIndex, workoutIndex);
    }
  }

  Future<void> _showAddToSuperSetDialog(
      BuildContext context, Exercise exercise, bool isDarkMode, ColorScheme colorScheme) async {
    String? selectedSuperSetId;
    final superSets =
        controller.program.weeks[weekIndex].workouts[workoutIndex].superSets;

    if (superSets.isEmpty) {
      // Crea un nuovo superset se non ce ne sono
      controller.createSuperSet(weekIndex, workoutIndex);
      selectedSuperSetId =
          controller.program.weeks[weekIndex].workouts[workoutIndex].superSets.first.id;
    } else {
      selectedSuperSetId = await showDialog<String>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                backgroundColor: isDarkMode ? colorScheme.surface : colorScheme.background,
                title: Text(
                  'Aggiungi al Superset',
                  style: TextStyle(
                    color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
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
                          color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
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
                      color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Annulla',
                      style: TextStyle(
                        color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
                      ),
                    ),
                  ),
                  if (superSets.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        controller.createSuperSet(weekIndex, workoutIndex);
                        setState(() {});
                        Navigator.of(context).pop(superSets.last.id);
                      },
                      child: Text(
                        'Crea Nuovo Superset',
                        style: TextStyle(
                          color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
                        ),
                      ),
                    ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(selectedSuperSetId),
                    child: Text(
                      'Aggiungi',
                      style: TextStyle(
                        color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    if (selectedSuperSetId != null) {
      controller.addExerciseToSuperSet(
          weekIndex, workoutIndex, selectedSuperSetId!, exercise.id!);
    }
  }

  Future<void> _showRemoveFromSuperSetDialog(
      BuildContext context, Exercise exercise, bool isDarkMode, ColorScheme colorScheme) async {
    final superSets = controller.program.weeks[weekIndex].workouts[workoutIndex].superSets
        .where((ss) => ss.exerciseIds.contains(exercise.id))
        .toList();

    if (superSets.isEmpty) {
      return;
    }

    final superSetId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? colorScheme.surface : colorScheme.background,
        title: Text(
          'Rimuovi dal Superset',
          style: TextStyle(
            color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
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
                  color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) => Navigator.of(context).pop(value),
          decoration: InputDecoration(
            hintText: 'Seleziona il Superset',
            hintStyle: TextStyle(
              color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annulla',
              style: TextStyle(
                color: isDarkMode ? colorScheme.onSurface : colorScheme.onBackground,
              ),
            ),
          ),
        ],
      ),
    );

    if (superSetId != null) {
      controller.removeExerciseFromSuperSet(
          weekIndex, workoutIndex, superSetId, exercise.id!);
    }
  }

  Future<void> _showSetProgressionScreen(
    BuildContext context,
    Exercise exercise,
    num latestMaxWeight,
    bool isDarkMode,
    ColorScheme colorScheme,
  ) async {
    final updatedExercise = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SetProgressionScreen(
          exerciseId: exercise.exerciseId!,
          exercise: exercise,
          latestMaxWeight: latestMaxWeight,
        ),
      ),
    );
    if (updatedExercise != null) {
      controller.updateExercise(updatedExercise.exerciseId!);
    }
  }
}
