import 'dart:math';
import 'package:alphanessone/trainingBuilder/models/superseries_model.dart';
import 'package:alphanessone/trainingBuilder/models/training_model.dart';

class SuperSetController {
  static int superSetCounter = 0;

  void loadSuperSets(TrainingProgram program) {
    int maxSuperSetIndex = 0;
    final superSets = <SuperSet>[];
    final exercisesWithSuperSet = program.weeks.expand((week) => week.workouts
        .expand((workout) =>
            workout.exercises.where((exercise) => exercise.superSetId != null)));

    for (final exercise in exercisesWithSuperSet) {
      final superSetId = exercise.superSetId;
      if (superSetId != null) {
        final existingSuperSet = superSets.firstWhere(
          (superSet) => superSet.id == superSetId,
          orElse: () => SuperSet(
              id: superSetId,
              name: 'SS${superSets.length + 1}',
              exerciseIds: []),
        );
        final superSetIndex = int.tryParse(
                existingSuperSet.name?.replaceAll('SS', '') ?? '0') ??
            0;
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
        workout.superSets = workoutSuperSets;
      }
    }

    SuperSetController.superSetCounter = maxSuperSetIndex + 1;
  }

  String generateRandomId(int length) {
    final random = Random.secure();
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(Iterable.generate(
      length,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ));
  }

  void createSuperSet(TrainingProgram program, int weekIndex, int workoutIndex) {
    final superSetId = generateRandomId(16);
    final superSetName =
        'SS${SuperSetController.superSetCounter}'; // Rimuovi l'aggiunta di 1
    SuperSetController.superSetCounter++;

    // Controlla se il contatore ha superato il valore massimo (ad esempio, 100)
    if (SuperSetController.superSetCounter > 100) {
      SuperSetController.superSetCounter = 1;
    }

    final superSet =
        SuperSet(id: superSetId, name: superSetName, exerciseIds: []);
    program.weeks[weekIndex].workouts[workoutIndex].superSets.add(superSet);
  }

  void addExerciseToSuperSet(TrainingProgram program, int weekIndex,
      int workoutIndex, String superSetId, String exerciseId) {
    final superSet = program.weeks[weekIndex].workouts[workoutIndex].superSets
        .firstWhere(
      (ss) => ss.id == superSetId,
    );
    superSet.exerciseIds.add(exerciseId);

    // Aggiorna la proprietà superSetId dell'esercizio
    final exercise = program.weeks[weekIndex].workouts[workoutIndex].exercises
        .firstWhere(
      (e) => e.id == exerciseId,
    );
    exercise.superSetId = superSetId;
  }

  void removeExerciseFromSuperSet(TrainingProgram program, int weekIndex,
      int workoutIndex, String superSetId, String exerciseId) {
    final superSet = program.weeks[weekIndex].workouts[workoutIndex].superSets
        .firstWhere(
      (ss) => ss.id == superSetId,
    );
    superSet.exerciseIds.remove(exerciseId);

    // Reimposta la proprietà superSetId dell'esercizio a null
    final exercise = program.weeks[weekIndex].workouts[workoutIndex].exercises
        .firstWhere(
      (e) => e.id == exerciseId,
    );
    exercise.superSetId = null;

    // Se il superset non contiene più esercizi, rimuovilo
    if (superSet.exerciseIds.isEmpty) {
      removeSuperSet(program, weekIndex, workoutIndex, superSetId);
    }
  }

  void removeSuperSet(TrainingProgram program, int weekIndex, int workoutIndex,
      String superSetId) {
    final workout = program.weeks[weekIndex].workouts[workoutIndex];
    final removedSuperSets =
        workout.superSets.where((ss) => ss.id == superSetId).toList();
    workout.superSets.removeWhere((ss) => ss.id == superSetId);

    // Aggiorniamo il contatore dei supersets
    if (removedSuperSets.isNotEmpty) {
      final removedSuperSetIndex = int.tryParse(
              removedSuperSets.first.name?.replaceAll('SS', '') ?? '0') ??
          0;
      SuperSetController.superSetCounter = removedSuperSetIndex + 1;
    }

    // Aggiorniamo gli indici dei supersets rimanenti
    for (int i = 0; i < workout.superSets.length; i++) {
      workout.superSets[i].name = 'SS${i + 1}';
    }
  }
}