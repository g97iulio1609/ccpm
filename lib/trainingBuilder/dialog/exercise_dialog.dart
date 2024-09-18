// exercise_dialog.dart

import 'package:alphanessone/ExerciseRecords/exercise_autocomplete.dart';
import 'package:alphanessone/ExerciseRecords/exercise_record_services.dart';

import 'package:alphanessone/trainingBuilder/models/exercise_model.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../controller/training_program_controller.dart';

import 'package:flutter_hooks/flutter_hooks.dart'; // Importa flutter_hooks

class ExerciseDialog extends HookConsumerWidget {
  final ExerciseRecordService exerciseRecordService;
  final String athleteId;
  final Exercise? exercise;

  const ExerciseDialog({
    required this.exerciseRecordService,
    required this.athleteId,
    this.exercise,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(trainingProgramControllerProvider);

    // Usa useTextEditingController per gestire i controller
    final exerciseNameController =
        useTextEditingController(text: exercise?.name ?? '');
    final variantController =
        useTextEditingController(text: exercise?.variant ?? '');

    // Usa useState per gestire lo stato di selectedExerciseId e selectedExerciseType
    final selectedExerciseId = useState<String>(exercise?.exerciseId ?? '');
    final selectedExerciseType = useState<String>(exercise?.type ?? '');

    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      titleTextStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
      contentTextStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
      title:
          Text(exercise == null ? 'Aggiungi Esercizio' : 'Modifica Esercizio'),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            ExerciseAutocompleteBox(
              controller: exerciseNameController,
              exerciseRecordService: exerciseRecordService,
              athleteId: athleteId,
              onSelected: (selectedExercise) {
                if (selectedExercise.id.isNotEmpty) {
                  selectedExerciseId.value = selectedExercise.id;
                  selectedExerciseType.value = selectedExercise.type;
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: variantController,
              decoration: InputDecoration(
                labelText: 'Variante',
                labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Colors.white,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurface,
          ),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: () {
            final newExercise = Exercise(
              id: exercise?.id ?? '',
              exerciseId: selectedExerciseId.value,
              name: exerciseNameController.text,
              type: selectedExerciseType.value,
              variant: variantController.text,
              order: exercise?.order ?? 0,
              series: exercise?.series ?? [],
              weekProgressions: exercise?.weekProgressions ?? [],
            );

            Navigator.pop(context, newExercise);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(exercise == null ? 'Aggiungi' : 'Aggiorna'),
        ),
      ],
    );
  }
}
