import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'training_model.dart';
import 'training_program_controller.dart';
import 'training_program_series_list.dart';
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

    return ListView.builder(
      shrinkWrap: true,
      itemCount: exercises.length + 1,
      itemBuilder: (context, index) {
        if (index == exercises.length) {
          return _buildAddExerciseButton(context);
        }
        return _buildExerciseCard(context, exercises[index], usersService, athleteId, dateFormat);
      },
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    Exercise exercise,
    UsersService usersService,
    String athleteId,
    DateFormat dateFormat,
  ) {
    final superSets = controller.program.weeks[weekIndex].workouts[workoutIndex].superSets
        .where((ss) => ss.exerciseIds.contains(exercise.id))
        .toList();

    return Slidable(
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => controller.addExercise(weekIndex, workoutIndex, context),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
            icon: Icons.delete,
            label: 'Elimina',
          ),
        ],
      ),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildExerciseHeader(context, exercise, usersService, athleteId, dateFormat),
              if (superSets.isNotEmpty)
                Row(
                  children: superSets.map((ss) => Icon(Icons.group_work, color: Colors.blue)).toList(),
                ),
              const SizedBox(height: 16),
              _buildExerciseSeries(context, exercise, usersService),
              const SizedBox(height: 16),
              Center(
                child: _buildAddSeriesButton(context, exercise),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseHeader(
    BuildContext context,
    Exercise exercise,
    UsersService usersService,
    String athleteId,
    DateFormat dateFormat,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => controller.editExercise(weekIndex, workoutIndex, exercise.order - 1, context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    exercise.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  if (exercise.variant.isNotEmpty)
                    Text(
                      exercise.variant,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
          _buildExercisePopupMenu(context, exercise, usersService, athleteId, dateFormat),
        ],
      ),
    );
  }

  PopupMenuButton _buildExercisePopupMenu(
    BuildContext context,
    Exercise exercise,
    UsersService usersService,
    String athleteId,
    DateFormat dateFormat,
  ) {
    return PopupMenuButton(
      itemBuilder: (context) => [
        PopupMenuItem(
          child: const Text('Modifica'),
          onTap: () => controller.editExercise(weekIndex, workoutIndex, exercise.order - 1, context),
        ),
        PopupMenuItem(
          child: const Text('Aggiorna Max RM'),
          onTap: () => _addOrUpdateMaxRM(exercise, context, usersService, athleteId, dateFormat),
        ),
        PopupMenuItem(
          child: const Text('Riordina Esercizi'),
          onTap: () => _showReorderExercisesDialog(context, weekIndex, workoutIndex),
        ),
        PopupMenuItem(
          child: const Text('Crea Nuovo Superset'),
          onTap: () => _createNewSuperSet(context),
        ),
        PopupMenuItem(
          child: const Text('Aggiungi al Superset'),
          onTap: () => _showAddToSuperSetDialog(context, exercise),
        ),
        PopupMenuItem(
          child: const Text('Rimuovi dal Superset'),
          onTap: () => _showRemoveFromSuperSetDialog(context, exercise),
        ),
      ],
    );
  }

  Widget _buildExerciseSeries(BuildContext context, Exercise exercise, UsersService usersService) {
    return TrainingProgramSeriesList(
      controller: controller,
      usersService: usersService,
      weekIndex: weekIndex,
      workoutIndex: workoutIndex,
      exerciseIndex: exercise.order - 1,
    );
  }

  Widget _buildAddSeriesButton(BuildContext context, Exercise exercise) {
    return ElevatedButton(
      onPressed: () => controller.addSeries(weekIndex, workoutIndex, exercise.order - 1, context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text('Aggiungi Nuova Serie'),
    );
  }

  Widget _buildAddExerciseButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () => controller.addExercise(weekIndex, workoutIndex, context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
  ) async {
    final record = await usersService.getLatestExerciseRecord(userId: athleteId, exerciseId: exercise.exerciseId!);
    final maxWeightController = TextEditingController(text: record?.maxWeight.toString() ?? '');
    final repetitionsController = TextEditingController(text: record?.repetitions.toString() ?? '');

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Aggiorna Max RM'),
          content: _buildMaxRMInputFields(maxWeightController, repetitionsController),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
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
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: maxWeightController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Peso Massimo'),
        ),
        TextField(
          controller: repetitionsController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Ripetizioni'),
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

  void _showReorderExercisesDialog(BuildContext context, int weekIndex, int workoutIndex) {
    final exerciseNames = controller.program.weeks[weekIndex].workouts[workoutIndex].exercises
        .map((exercise) => exercise.name)
        .toList();
    showDialog(
      context: context,
      builder: (context) => ReorderDialog(
        items: exerciseNames,
        onReorder: (oldIndex, newIndex) => controller.reorderExercises(weekIndex, workoutIndex, oldIndex, newIndex),
      ),
    );
  }
Future<void> _createNewSuperSet(BuildContext context) async {
  final superSetName = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Nuovo Superset'),
      content: TextField(
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Nome Superset',
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: () {
            final textFieldController = TextEditingController();
            Navigator.of(context).pop(textFieldController.text);
          },
          child: const Text('Crea'),
        ),
      ],
    ),
  );

  if (superSetName != null && superSetName.isNotEmpty) {
    controller.createSuperSet(weekIndex, workoutIndex);
  }
}

Future<void> _showAddToSuperSetDialog(BuildContext context, Exercise exercise) async {
  String? selectedSuperSetId;
  final superSets = controller.program.weeks[weekIndex].workouts[workoutIndex].superSets;

  if (superSets.isEmpty) {
    // Crea un nuovo superset se non ce ne sono
    controller.createSuperSet(weekIndex, workoutIndex);
    selectedSuperSetId = controller.program.weeks[weekIndex].workouts[workoutIndex].superSets.first.id;
  } else {
    selectedSuperSetId = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Aggiungi al Superset'),
              content: DropdownButtonFormField<String>(
                value: selectedSuperSetId,
                items: superSets.map((ss) {
                  return DropdownMenuItem<String>(
                    value: ss.id,
                    child: Text(ss.name ?? ''),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedSuperSetId = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Seleziona il Superset',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annulla'),
                ),
                if (superSets.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      controller.createSuperSet(weekIndex, workoutIndex);
                      setState(() {});
                      Navigator.of(context).pop(superSets.last.id);
                    },
                    child: const Text('Crea Nuovo Superset'),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(selectedSuperSetId),
                  child: const Text('Aggiungi'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  if (selectedSuperSetId != null) {
    controller.addExerciseToSuperSet(weekIndex, workoutIndex, selectedSuperSetId!, exercise.id!);
  }
}


  Future<void> _showRemoveFromSuperSetDialog(BuildContext context, Exercise exercise) async {
    final superSets = controller.program.weeks[weekIndex].workouts[workoutIndex].superSets
        .where((ss) => ss.exerciseIds.contains(exercise.id))
        .toList();

    if (superSets.isEmpty) {
      return;
    }

    final superSetId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rimuovi dal Superset'),
        content: DropdownButtonFormField<String>(
          value: null,
          items: superSets.map((ss) {
            return DropdownMenuItem<String>(
              value: ss.id,
              child: Text('Superset ${ss.id}'),
            );
          }).toList(),
          onChanged: (value) => Navigator.of(context).pop(value),
          decoration: const InputDecoration(
            hintText: 'Seleziona il Superset',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
        ],
      ),
    );

    if (superSetId != null) {
      controller.removeExerciseFromSuperSet(weekIndex, workoutIndex, superSetId, exercise.id!);
}
}
}