import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: unused_import
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/trainingBuilder/dialog/exercise_dialog.dart';
import 'package:alphanessone/trainingBuilder/presentation/widgets/dialogs/series_dialog.dart';
import 'package:alphanessone/shared/shared.dart';
import 'package:alphanessone/providers/providers.dart' as app_providers;
import 'package:alphanessone/Viewer/UI/workout_provider.dart'
    as workout_provider;
import 'package:flutter/services.dart';
import 'package:alphanessone/UI/components/app_dialog.dart';

class WorkoutDialogs {
  static Future<void> showNoteDialog(
    BuildContext context,
    WidgetRef ref,
    String exerciseId,
    String exerciseName,
    String workoutId, [
    String? existingNote,
  ]) async {
    if (!context.mounted) return;
    final TextEditingController noteController = TextEditingController(
      text: existingNote,
    );
    // Manteniamo i colori da Theme dove necessario direttamente nei widget

    return showAppDialog(
      context: context,
      title: Text('Note per $exerciseName'),
      child: TextField(
        controller: noteController,
        maxLines: 5,
        decoration: InputDecoration(
          hintText: 'Inserisci una nota...',
        ),
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
      actions: [
        if (existingNote != null)
          TextButton(
            onPressed: () async {
              await ref
                  .read(workout_provider.workoutServiceProvider)
                  .deleteNote(exerciseId, workoutId);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: Text(
              'Elimina',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Annulla'),
        ),
        FilledButton(
          onPressed: () async {
            final note = noteController.text.trim();
            if (note.isNotEmpty) {
              await ref
                  .read(workout_provider.workoutServiceProvider)
                  .showNoteDialog(exerciseId, exerciseName, workoutId, note);
            }
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Salva'),
        ),
      ],
    );
  }

  static Future<void> showUpdateMaxWeightDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> exercise,
    String userId,
  ) {
    final weightController = TextEditingController();
    final repsController = TextEditingController(text: "1");
    final calculatedMaxWeight = ValueNotifier<double?>(null);
    final keepWeightSwitch = ValueNotifier<bool>(false);

    void calculateMaxWeight() {
      final weight = double.tryParse(weightController.text);
      final reps = int.tryParse(repsController.text);

      if (weight != null && reps != null && reps > 0) {
        calculatedMaxWeight.value = (weight / (1.0278 - 0.0278 * reps))
            .roundToDouble();
      } else {
        calculatedMaxWeight.value = null;
      }
    }

    return showAppDialog(
      context: context,
      title: const Text('Aggiorna Massimale'),
      child: StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Peso (kg)'),
              onChanged: (_) => calculateMaxWeight(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Ripetizioni'),
              onChanged: (_) => calculateMaxWeight(),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<double?>(
              valueListenable: calculatedMaxWeight,
              builder: (context, maxWeight, child) {
                return maxWeight != null
                    ? Text(
                        'Massimale calcolato (1RM): ${maxWeight.toStringAsFixed(1)} kg',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Mantieni pesi attuali'),
                Switch(
                  value: keepWeightSwitch.value,
                  onChanged: (value) {
                    setState(() {
                      keepWeightSwitch.value = value;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () async {
            final maxWeight = calculatedMaxWeight.value;
            final weight = double.tryParse(weightController.text);
            if (maxWeight != null && weight != null) {
              await ref
                  .read(workout_provider.workoutServiceProvider)
                  .updateMaxWeight(
                    exercise,
                    maxWeight,
                    userId,
                    repetitions: 1,
                    keepCurrentWeights: keepWeightSwitch.value,
                  );
              Navigator.pop(context);
            }
          },
          child: const Text('Salva'),
        ),
      ],
    );
  }

  static void showChangeExerciseDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> currentExercise,
    String userId,
  ) {
    final exerciseRecordService = ref.read(
      app_providers.exerciseRecordServiceProvider,
    );

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => ExerciseDialog(
        exerciseRecordService: exerciseRecordService,
        athleteId: userId,
        exercise: Exercise(
          id: currentExercise['id'] ?? '',
          exerciseId: currentExercise['exerciseId'] ?? '',
          name: currentExercise['name'] ?? '',
          type: currentExercise['type'] ?? '',
          variant: currentExercise['variant'] ?? '',
          order: currentExercise['order'] ?? 0,
          series: [],
          weekProgressions: [],
        ),
      ),
    ).then((newExercise) async {
      if (newExercise != null) {
        await ref
            .read(workout_provider.workoutServiceProvider)
            .updateExercise(currentExercise, newExercise);
      }
    });
  }

  static void showSeriesEditDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> exercise,
    List<Map<String, dynamic>> series,
    String userId,
  ) async {
    final List<Series> seriesList = series
        .map((s) => Series.fromMap(s))
        .toList();
    final originalExerciseId =
        seriesList.first.originalExerciseId ?? exercise['id'];

    final recordsStream = ref
        .read(app_providers.exerciseRecordServiceProvider)
        .getExerciseRecords(userId: userId, exerciseId: originalExerciseId)
        .map(
          (records) => records.isNotEmpty
              ? records.reduce((a, b) => a.date.compareTo(b.date) > 0 ? a : b)
              : null,
        );

    final latestRecord = await recordsStream.first;
    num latestMaxWeight = latestRecord?.maxWeight ?? 0.0;

    // colorScheme non necessario con AppDialog, manteniamo la tipografia di tema

    final weightNotifier =
        ref
            .read(workout_provider.workoutServiceProvider)
            .getWeightNotifier(exercise['id']) ??
        ValueNotifier<double>(0.0);

  final result = await showDialog<dynamic>(
      context: context,
      builder: (context) => SeriesDialog(
        exerciseRecordService: ref.read(
          app_providers.exerciseRecordServiceProvider,
        ),
        athleteId: userId,
        exerciseId: exercise['id'],
        exerciseType: exercise['type'] ?? 'weight',
        weekIndex: 0,
        exercise: Exercise.fromMap(exercise),
        currentSeriesGroup: seriesList
            .map((s) => Series.fromMap(s.toMap()))
            .toList(),
        latestMaxWeight: latestMaxWeight.toDouble(),
        weightNotifier: weightNotifier,
      ),
    );

  if (result != null && context.mounted) {
      try {
    // Supporta sia il nuovo ritorno (List<Series>) che il vecchio (Map con chiave 'series')
    final List<Series> updatedSeries = result is List<Series>
      ? result
      : (result is Map<String, dynamic>
        ? (result['series'] as List<Series>)
        : <Series>[]);
    if (updatedSeries.isEmpty) return;
        await ref
            .read(workout_provider.workoutServiceProvider)
            .applySeriesChanges(exercise, updatedSeries);
      } catch (e) {
        if (!context.mounted) return;
        final cs = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante il salvataggio delle modifiche: $e'),
            backgroundColor: cs.error,
          ),
        );
      }
    }
  }

  static void showUserSeriesInputDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> seriesData,
    String field,
  ) {
    final TextEditingController repsController = TextEditingController();
    final TextEditingController weightController = TextEditingController();
    // Usa il colorScheme dove necessario direttamente dai widget

    // Initialize controllers with current values if they exist
    final currentReps = seriesData['reps_done'];
    final currentWeight = seriesData['weight_done'];
    if (currentReps != null) {
      repsController.text = currentReps.toString();
    }
    if (currentWeight != null) {
      weightController.text = currentWeight.toString();
    }

    // Prepare target values text
    final reps = seriesData['reps'];
    final maxReps = seriesData['maxReps'];
    final weight = seriesData['weight'];
    final maxWeight = seriesData['maxWeight'];

    final String repsTarget = maxReps != null ? "$reps-$maxReps" : "$reps";
    final String weightTarget = maxWeight != null
        ? "$weight-$maxWeight"
        : "$weight";

    showAppDialog(
      context: context,
      title: const Text('Inserisci ripetizioni e peso'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Obiettivo ripetizioni: ${repsTarget}R',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: repsController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: const InputDecoration(
              labelText: 'Ripetizioni eseguite',
              hintText: 'Inserisci le ripetizioni',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Obiettivo peso: ${weightTarget}Kg',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: weightController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: const InputDecoration(
              labelText: 'Peso eseguito',
              hintText: 'Inserisci il peso',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () {
            final reps = double.tryParse(repsController.text);
            final weight = double.tryParse(weightController.text);
            if (reps != null) {
              seriesData['reps_done'] = reps;
            }
            if (weight != null) {
              seriesData['weight_done'] = weight;
            }
            if (reps != null || weight != null) {
              ref
                  .read(workout_provider.workoutServiceProvider)
                  .updateSeriesData(seriesData['exerciseId'], seriesData);
            }
            Navigator.pop(context);
          },
          child: const Text('Salva'),
        ),
      ],
    );
  }
}
