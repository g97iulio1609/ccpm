import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'training_model.dart';
import 'training_program_controller.dart';

class VolumeDashboard extends ConsumerWidget {
  final TrainingProgramController controller;

  const VolumeDashboard({super.key, required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final program = controller.program;

    // Calcola il volume giornaliero, settimanale e mensile per ogni esercizio
    final exerciseVolumes = <String, _ExerciseVolume>{};
    for (final week in program.weeks) {
      for (final workout in week.workouts) {
        for (final exercise in workout.exercises) {
          if (!exerciseVolumes.containsKey(exercise.name)) {
            exerciseVolumes[exercise.name] = _ExerciseVolume();
          }

          final volume = exerciseVolumes[exercise.name]!;
          volume.dailyVolume += _calculateDailyVolume(exercise);
          volume.weeklyVolume += _calculateWeeklyVolume(exercise);
          volume.monthlyVolume += _calculateMonthlyVolume(exercise);
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Volume Dashboard'),
      ),
      body: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Exercise')),
            DataColumn(label: Text('Daily Volume')),
            DataColumn(label: Text('Weekly Volume')),
            DataColumn(label: Text('Monthly Volume')),
          ],
          rows: exerciseVolumes.entries.map((entry) {
            final exerciseName = entry.key;
            final volume = entry.value;
            return DataRow(cells: [
              DataCell(Text(exerciseName)),
              DataCell(Text(volume.dailyVolume.toStringAsFixed(2))),
              DataCell(Text(volume.weeklyVolume.toStringAsFixed(2))),
              DataCell(Text(volume.monthlyVolume.toStringAsFixed(2))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  double _calculateDailyVolume(Exercise exercise) {
    // Implementa la logica per calcolare il volume giornaliero dell'esercizio
    // Esempio: somma il prodotto di peso e ripetizioni per ogni serie dell'esercizio
    return exercise.series.fold(
      0.0,
      (sum, series) => sum + (series.weight * series.reps),
    );
  }

  double _calculateWeeklyVolume(Exercise exercise) {
    // Implementa la logica per calcolare il volume settimanale dell'esercizio
    // Esempio: moltiplica il volume giornaliero per il numero di volte che l'esercizio viene eseguito in una settimana
    return _calculateDailyVolume(exercise) * _getWeeklyFrequency(exercise);
  }

  double _calculateMonthlyVolume(Exercise exercise) {
    // Implementa la logica per calcolare il volume mensile dell'esercizio
    // Esempio: moltiplica il volume settimanale per 4 (assumendo 4 settimane in un mese)
    return _calculateWeeklyVolume(exercise) * 4;
  }

  int _getWeeklyFrequency(Exercise exercise) {
    // Implementa la logica per ottenere la frequenza settimanale dell'esercizio
    // Esempio: conta il numero di volte che l'esercizio appare nei workout di una settimana
    int frequency = 0;
    for (final week in controller.program.weeks) {
      for (final workout in week.workouts) {
        if (workout.exercises.contains(exercise)) {
          frequency++;
        }
      }
    }
    return frequency;
  }
}

class _ExerciseVolume {
  double dailyVolume = 0;
  double weeklyVolume = 0;
  double monthlyVolume = 0;
}