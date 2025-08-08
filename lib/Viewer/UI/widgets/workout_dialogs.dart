import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/trainingBuilder/dialog/exercise_dialog.dart';
import 'package:alphanessone/trainingBuilder/presentation/widgets/dialogs/series_dialog.dart';
import 'package:alphanessone/shared/shared.dart';
import 'package:alphanessone/providers/providers.dart' as app_providers;
import 'package:alphanessone/Viewer/UI/workout_provider.dart'
    as workout_provider;
import 'package:flutter/services.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Note per $exerciseName',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
        ),
        content: TextField(
          controller: noteController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Inserisci una nota...',
            hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radii.sm),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radii.sm),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radii.sm),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
          style: TextStyle(color: colorScheme.onSurface),
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
                style: TextStyle(color: colorScheme.error),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Annulla',
              style: TextStyle(color: colorScheme.primary),
            ),
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
            style: FilledButton.styleFrom(backgroundColor: colorScheme.primary),
            child: Text(
              'Salva',
              style: TextStyle(color: colorScheme.onPrimary),
            ),
          ),
        ],
      ),
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

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Aggiorna Massimale'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Peso (kg)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => calculateMaxWeight(),
              ),
              SizedBox(height: 16),
              TextField(
                controller: repsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Ripetizioni',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => calculateMaxWeight(),
              ),
              SizedBox(height: 16),
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
                      : SizedBox.shrink();
                },
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Text('Mantieni pesi attuali'),
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
            child: Text('Annulla'),
          ),
          TextButton(
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
            child: Text('Salva'),
          ),
        ],
      ),
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

    final colorScheme = Theme.of(context).colorScheme;

    final weightNotifier =
        ref
            .read(workout_provider.workoutServiceProvider)
            .getWeightNotifier(exercise['id']) ??
        ValueNotifier<double>(0.0);

    final result = await showDialog<Map<String, dynamic>>(
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
        final List<Series> updatedSeries = result['series'] as List<Series>;
        await ref
            .read(workout_provider.workoutServiceProvider)
            .applySeriesChanges(exercise, updatedSeries);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante il salvataggio delle modifiche: $e'),
            backgroundColor: colorScheme.error,
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
    final colorScheme = Theme.of(context).colorScheme;

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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Inserisci ripetizioni e peso',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Obiettivo ripetizioni: ${repsTarget}R',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
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
              decoration: InputDecoration(
                labelText: 'Ripetizioni eseguite',
                hintText: 'Inserisci le ripetizioni',
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Obiettivo peso: ${weightTarget}Kg',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
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
              decoration: InputDecoration(
                labelText: 'Peso eseguito',
                hintText: 'Inserisci il peso',
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annulla',
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
          TextButton(
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
            child: Text('Salva', style: TextStyle(color: colorScheme.primary)),
          ),
        ],
      ),
    );
  }
}
