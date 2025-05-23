import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/bottom_menu.dart';
import 'package:alphanessone/trainingBuilder/models/exercise_model.dart';
import 'package:alphanessone/trainingBuilder/models/superseries_model.dart';
import 'package:alphanessone/trainingBuilder/controller/training_program_controller.dart';
import 'package:alphanessone/trainingBuilder/List/progressions_list.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

class ExerciseOptionsDialog extends ConsumerWidget {
  final Exercise exercise;
  final num latestMaxWeight;
  final TrainingProgramController controller;
  final int weekIndex;
  final int workoutIndex;
  final VoidCallback onBulkSeries;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const ExerciseOptionsDialog({
    super.key,
    required this.exercise,
    required this.latestMaxWeight,
    required this.controller,
    required this.weekIndex,
    required this.workoutIndex,
    required this.onBulkSeries,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final workout = controller.program.weeks[weekIndex].workouts[workoutIndex];
    final superSet = workout.superSets.firstWhere(
      (ss) => ss.exerciseIds.contains(exercise.id),
      orElse: () => SuperSet(id: '', exerciseIds: []),
    );
    final isInSuperSet = superSet.id.isNotEmpty;

    return BottomMenu(
      title: exercise.name,
      subtitle: exercise.variant,
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
          title: 'Modifica',
          icon: Icons.edit_outlined,
          onTap: () {
            Navigator.pop(context);
            onEdit();
          },
        ),
        BottomMenuItem(
          title: 'Gestione Serie in Bulk',
          icon: Icons.format_list_numbered,
          onTap: () {
            Navigator.pop(context);
            onBulkSeries();
          },
        ),
        BottomMenuItem(
          title: 'Sposta Esercizio',
          icon: Icons.move_up,
          onTap: () {
            Navigator.pop(context);
            _showMoveExerciseDialog(context);
          },
        ),
        BottomMenuItem(
          title: 'Duplica Esercizio',
          icon: Icons.content_copy_outlined,
          onTap: () {
            Navigator.pop(context);
            onDuplicate();
          },
        ),
        if (!isInSuperSet)
          BottomMenuItem(
            title: 'Aggiungi a Super Set',
            icon: Icons.group_add_outlined,
            onTap: () {
              Navigator.pop(context);
              _showAddToSuperSetDialog(context);
            },
          ),
        if (isInSuperSet)
          BottomMenuItem(
            title: 'Rimuovi da Super Set',
            icon: Icons.group_remove_outlined,
            onTap: () {
              Navigator.pop(context);
              controller.removeExerciseFromSuperSet(
                weekIndex,
                workoutIndex,
                superSet.id,
                exercise.id!,
              );
            },
          ),
        BottomMenuItem(
          title: 'Imposta Progressione',
          icon: Icons.trending_up,
          onTap: () {
            Navigator.pop(context);
            _showSetProgressionScreen(context);
          },
        ),
        BottomMenuItem(
          title: 'Aggiorna Max RM',
          icon: Icons.fitness_center,
          onTap: () {
            Navigator.pop(context);
            _showUpdateMaxRMDialog(context, ref);
          },
        ),
        BottomMenuItem(
          title: 'Elimina',
          icon: Icons.delete_outline,
          onTap: () {
            Navigator.pop(context);
            _showDeleteConfirmationDialog(context);
          },
          isDestructive: true,
        ),
      ],
    );
  }

  void _showMoveExerciseDialog(BuildContext context) {
    final week = controller.program.weeks[weekIndex];
    final sourceExerciseIndex = exercise.order - 1;

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
      if (destinationWorkoutIndex != null &&
          destinationWorkoutIndex != workoutIndex) {
        controller.moveExercise(
          weekIndex,
          workoutIndex,
          sourceExerciseIndex,
          weekIndex,
          destinationWorkoutIndex,
        );
      }
    });
  }

  void _showAddToSuperSetDialog(BuildContext context) {
    final superSets =
        controller.program.weeks[weekIndex].workouts[workoutIndex].superSets;
    String? selectedSuperSetId;

    if (superSets.isEmpty) {
      controller.createSuperSet(weekIndex, workoutIndex);
      selectedSuperSetId = controller
          .program.weeks[weekIndex].workouts[workoutIndex].superSets.first.id;
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
                title: const Text('Aggiungi al Superset'),
                content: DropdownButtonFormField<String>(
                  value: selectedSuperSetId,
                  items: superSets.map((ss) {
                    return DropdownMenuItem<String>(
                      value: ss.id,
                      child: Text(ss.name ?? 'Superset ${ss.id}'),
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
                    onPressed: () => Navigator.of(dialogContext).pop(null),
                    child: const Text('Annulla'),
                  ),
                  if (superSets.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        controller.createSuperSet(weekIndex, workoutIndex);
                        setState(() {});
                        Navigator.of(dialogContext).pop(superSets.last.id);
                      },
                      child: const Text('Crea Nuovo Superset'),
                    ),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(dialogContext).pop(selectedSuperSetId),
                    child: const Text('Aggiungi'),
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

  void _showSetProgressionScreen(BuildContext context) {
    // Naviga alla schermata delle progressioni
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

  void _showUpdateMaxRMDialog(BuildContext context, WidgetRef ref) {
    final maxWeightController =
        TextEditingController(text: latestMaxWeight.toString());
    final repetitionsController = TextEditingController(text: '1');

    showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Aggiorna Max RM'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: maxWeightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Peso Massimo (kg)',
                  hintText: 'Inserisci il peso massimo',
                ),
              ),
              SizedBox(height: AppTheme.spacing.md),
              TextField(
                controller: repetitionsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Ripetizioni',
                  hintText: 'Numero di ripetizioni eseguite',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Salva'),
            ),
          ],
        );
      },
    ).then((result) async {
      if (result == true && context.mounted) {
        await _saveMaxRM(
          context,
          ref,
          maxWeightController.text,
          repetitionsController.text,
        );
      }
    });
  }

  Future<void> _saveMaxRM(
    BuildContext context,
    WidgetRef ref,
    String maxWeightText,
    String repetitionsText,
  ) async {
    try {
      // Validazione input
      final maxWeight = double.tryParse(maxWeightText);
      final repetitions = int.tryParse(repetitionsText);

      if (maxWeight == null || maxWeight <= 0) {
        _showErrorSnackBar(context, 'Inserisci un peso valido');
        return;
      }

      if (repetitions == null || repetitions <= 0) {
        _showErrorSnackBar(
            context, 'Inserisci un numero di ripetizioni valido');
        return;
      }

      if (exercise.exerciseId == null || exercise.exerciseId!.isEmpty) {
        _showErrorSnackBar(context, 'ID esercizio non valido');
        return;
      }

      // Calcola il massimale 1RM se ripetizioni > 1
      double adjustedMaxWeight = maxWeight;
      int adjustedRepetitions = repetitions;

      if (repetitions > 1) {
        // Formula di Brzycki per calcolare 1RM
        adjustedMaxWeight = maxWeight / (1.0278 - (0.0278 * repetitions));
        adjustedRepetitions = 1;
      }

      // Ottieni il servizio per i record degli esercizi
      final exerciseRecordService = ref.read(exerciseRecordServiceProvider);
      final athleteId = controller.program.athleteId;

      // Salva il record
      await exerciseRecordService.addExerciseRecord(
        userId: athleteId,
        exerciseId: exercise.exerciseId!,
        exerciseName: exercise.name,
        maxWeight: adjustedMaxWeight.round(),
        repetitions: adjustedRepetitions,
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      );

      // Aggiorna i pesi nel programma
      await exerciseRecordService.updateWeightsForProgram(
        athleteId,
        exercise.exerciseId!,
        adjustedMaxWeight,
      );

      // Aggiorna l'esercizio nel controller
      await controller.updateExercise(exercise);

      // Mostra messaggio di successo
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              repetitions > 1
                  ? 'Max RM aggiornato: ${adjustedMaxWeight.round()}kg (calcolato da ${maxWeight}kg x $repetitions reps)'
                  : 'Max RM aggiornato: ${adjustedMaxWeight.round()}kg',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'Errore durante il salvataggio: $e');
      }
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Esercizio'),
        content: Text('Sei sicuro di voler eliminare "${exercise.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }
}
