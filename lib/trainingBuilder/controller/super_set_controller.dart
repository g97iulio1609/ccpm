import 'dart:math';

import 'package:alphanessone/trainingBuilder/models/superseries_model.dart';
import 'package:alphanessone/trainingBuilder/models/training_model.dart';

class SuperSetController {
  static int superSetCounter = 0;

  void loadSuperSets(TrainingProgram program) {
    int maxSuperSetIndex = 0;
    final superSets = <SuperSet>[];
    final exercisesWithSuperSet = program.weeks.expand((week) => week.workouts.expand((workout) => workout.exercises.where((exercise) => exercise.superSetId != null)));

    for (final exercise in exercisesWithSuperSet) {
      final superSetId = exercise.superSetId;
      if (superSetId != null) {
        final existingSuperSet = superSets.firstWhere(
          (superSet) => superSet.id == superSetId,
          orElse: () => SuperSet(id: superSetId, name: 'SS${superSets.length + 1}', exerciseIds: []),
        );
        final superSetIndex = int.tryParse(existingSuperSet.name!.replaceAll('SS', '')) ?? 0;
        if (superSetIndex > maxSuperSetIndex) {
          maxSuperSetIndex = superSetIndex;
        }
        if (!existingSuperSet.exerciseIds.contains(exercise.id)) {
          existingSuperSet.exerciseIds.add(exercise.id!);
        }
        if (!superSets.contains(existingSuperSet)) {
          superSets.add(existingSuperSet);
        }
      }
    }

    for (final week in program.weeks) {
      for (final workout in week.workouts) {
        final workoutSuperSets = superSets.where((superSet) {
          return superSet.exerciseIds.any((exerciseId) {
            return workout.exercises.any((exercise) => exercise.id == exerciseId);
          });
        }).toList();
        // Non possiamo assegnare direttamente, il workout è immutabile
        // Questo dovrebbe essere gestito tramite copyWith se necessario
      }
    }

    SuperSetController.superSetCounter = maxSuperSetIndex + 1;
  }

  String generateRandomId(int length) {
    final random = Random.secure();
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(Iterable.generate(
      length,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ));
  }

void createSuperSet(TrainingProgram program, int weekIndex, int workoutIndex) {
  final superSet = SuperSet(
    id: generateRandomId(16).toString(),
    name: 'Superset ${++superSetCounter}',
    exerciseIds: [],
  );

  final workout = program.weeks[weekIndex].workouts[workoutIndex];
  
  // Crea una nuova lista che include tutti i superset esistenti più il nuovo
  final updatedSuperSets = List<SuperSet>.from(workout.superSets ?? [])..add(superSet);
  
  // Assegna la nuova lista al workout
  program.weeks[weekIndex].workouts[workoutIndex] = workout.copyWith(
    superSets: updatedSuperSets.map((ss) => ss.toMap()).toList(),
  );
}

  void addExerciseToSuperSet(TrainingProgram program, int weekIndex, int workoutIndex, String superSetId, String exerciseId) {
    final superSets = program.weeks[weekIndex].workouts[workoutIndex].superSets;
    if (superSets != null) {
      final superSetMap = superSets.firstWhere(
        (ss) => ss['id'] == superSetId,
      );
      // Non possiamo modificare direttamente gli oggetti immutabili
      // Questo richiede una ristrutturazione per usare copyWith
      // superSet.exerciseIds.add(exerciseId);
      
      // final exercise = program.weeks[weekIndex].workouts[workoutIndex].exercises.firstWhere(
      //   (e) => e.id == exerciseId,
      // );
      // exercise.superSetId = superSetId;
    }
  }

  void removeExerciseFromSuperSet(TrainingProgram program, int weekIndex, int workoutIndex, String superSetId, String exerciseId) {
    final superSets = program.weeks[weekIndex].workouts[workoutIndex].superSets;
    if (superSets != null) {
      final superSetMap = superSets.firstWhere(
        (ss) => ss['id'] == superSetId,
      );
      // Non possiamo modificare direttamente gli oggetti immutabili
      // Questo richiede una ristrutturazione per usare copyWith
      // superSet.exerciseIds.remove(exerciseId);
      
      // final exercise = program.weeks[weekIndex].workouts[workoutIndex].exercises.firstWhere(
      //   (e) => e.id == exerciseId,
      // );
      // exercise.superSetId = null;

      final exerciseIds = List<String>.from(superSetMap['exerciseIds'] ?? []);
      if (exerciseIds.isEmpty) {
        removeSuperSet(program, weekIndex, workoutIndex, superSetId);
      }
    }
  }

  void removeSuperSet(TrainingProgram program, int weekIndex, int workoutIndex, String superSetId) {
    final workout = program.weeks[weekIndex].workouts[workoutIndex];
    final superSets = workout.superSets;
    if (superSets != null) {
      final removedSuperSets = superSets.where((ss) => ss['id'] == superSetId).toList();
      // Non possiamo modificare direttamente gli oggetti immutabili
      // workout.superSets.removeWhere((ss) => ss.id == superSetId);

      if (removedSuperSets.isNotEmpty) {
        final removedSuperSetIndex = int.tryParse(removedSuperSets.first['name']?.replaceAll('SS', '') ?? '0') ?? 0;
        SuperSetController.superSetCounter = removedSuperSetIndex + 1;
      }

      // Non possiamo modificare direttamente gli oggetti immutabili
      // for (int i = 0; i < workout.superSets.length; i++) {
      //   workout.superSets[i].name = 'SS${i + 1}';
      // }
    }
  }
}
