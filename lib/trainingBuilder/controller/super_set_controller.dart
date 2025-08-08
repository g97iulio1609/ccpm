import 'dart:math';

import 'package:alphanessone/shared/shared.dart';

class SuperSetController {
  static int superSetCounter = 0;

  void loadSuperSets(TrainingProgram program) {
    int maxSuperSetIndex = 0;
    final superSets = <SuperSet>[];
    final exercisesWithSuperSet = program.weeks.expand(
      (week) => week.workouts.expand(
        (workout) =>
            workout.exercises.where((exercise) => exercise.superSetId != null),
      ),
    );

    for (final exercise in exercisesWithSuperSet) {
      final superSetId = exercise.superSetId;
      if (superSetId != null) {
        final existingSuperSet = superSets.firstWhere(
          (superSet) => superSet.id == superSetId,
          orElse: () => SuperSet(
            id: superSetId,
            name: 'SS${superSets.length + 1}',
            exerciseIds: [],
          ),
        );
        final superSetIndex =
            int.tryParse(existingSuperSet.name!.replaceAll('SS', '')) ?? 0;
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

    // Logica per gestire i superset nei workout
    // Non possiamo assegnare direttamente, il workout è immutabile
    // Questo dovrebbe essere gestito tramite copyWith se necessario

    SuperSetController.superSetCounter = maxSuperSetIndex + 1;
  }

  String generateRandomId(int length) {
    final random = Random.secure();
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  void createSuperSet(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
  ) {
    final superSet = SuperSet(
      id: generateRandomId(16).toString(),
      name: 'Superset ${++superSetCounter}',
      exerciseIds: [],
    );

    final workout = program.weeks[weekIndex].workouts[workoutIndex];

    // Crea una nuova lista che include tutti i superset esistenti più il nuovo
    final updatedSuperSets = List<SuperSet>.from(workout.superSets ?? [])
      ..add(superSet);

    // Assegna la nuova lista al workout
    program.weeks[weekIndex].workouts[workoutIndex] = workout.copyWith(
      superSets: updatedSuperSets.map((ss) => ss.toMap()).toList(),
    );
  }

  void addExerciseToSuperSet(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
    String superSetId,
    String exerciseId,
  ) {
    final workout = program.weeks[weekIndex].workouts[workoutIndex];
    final superSets = List<Map<String, dynamic>>.from(workout.superSets ?? []);

    // Trova o crea il superset
    int ssIndex = superSets.indexWhere((ss) => ss['id'] == superSetId);
    Map<String, dynamic> target;
    if (ssIndex == -1) {
      target = {
        'id': superSetId,
        'name': 'Superset ${++superSetCounter}',
        'exerciseIds': <String>[],
      };
      superSets.add(target);
      ssIndex = superSets.length - 1;
    } else {
      target = Map<String, dynamic>.from(superSets[ssIndex]);
    }

    final exerciseIds = List<String>.from(target['exerciseIds'] ?? <String>[]);
    if (!exerciseIds.contains(exerciseId)) {
      exerciseIds.add(exerciseId);
    }
    target['exerciseIds'] = exerciseIds;
    superSets[ssIndex] = target;

    // Aggiorna exercise.superSetId in modo immutabile
    final exercises = List<Exercise>.from(workout.exercises);
    final exIdx = exercises.indexWhere((e) => e.id == exerciseId);
    if (exIdx != -1) {
      exercises[exIdx] = exercises[exIdx].copyWith(superSetId: superSetId);
    }

    program.weeks[weekIndex].workouts[workoutIndex] = workout.copyWith(
      superSets: superSets,
      exercises: exercises,
    );
  }

  void removeExerciseFromSuperSet(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
    String superSetId,
    String exerciseId,
  ) {
    final workout = program.weeks[weekIndex].workouts[workoutIndex];
    final superSets = List<Map<String, dynamic>>.from(workout.superSets ?? []);
    final ssIndex = superSets.indexWhere((ss) => ss['id'] == superSetId);
    if (ssIndex == -1) return;

    final target = Map<String, dynamic>.from(superSets[ssIndex]);
    final exerciseIds = List<String>.from(target['exerciseIds'] ?? <String>[]);
    exerciseIds.removeWhere((id) => id == exerciseId);
    target['exerciseIds'] = exerciseIds;
    superSets[ssIndex] = target;

    // Aggiorna exercise.superSetId a null
    final exercises = List<Exercise>.from(workout.exercises);
    final exIdx = exercises.indexWhere((e) => e.id == exerciseId);
    if (exIdx != -1) {
      exercises[exIdx] = exercises[exIdx].copyWith(superSetId: null);
    }

    // Se il superset è vuoto, rimuovilo
    List<Map<String, dynamic>> updatedSuperSets = superSets;
    if (exerciseIds.isEmpty) {
      updatedSuperSets = List<Map<String, dynamic>>.from(superSets)
        ..removeAt(ssIndex);
    }

    program.weeks[weekIndex].workouts[workoutIndex] = workout.copyWith(
      superSets: updatedSuperSets,
      exercises: exercises,
    );
  }

  void removeSuperSet(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
    String superSetId,
  ) {
    final workout = program.weeks[weekIndex].workouts[workoutIndex];
    final superSets = List<Map<String, dynamic>>.from(workout.superSets ?? []);
    final filtered = superSets.where((ss) => ss['id'] != superSetId).toList();

    // Pulisce anche gli exercise.superSetId che puntavano al superset rimosso
    final exercises = workout.exercises
        .map(
          (e) => e.superSetId == superSetId ? e.copyWith(superSetId: null) : e,
        )
        .toList();

    program.weeks[weekIndex].workouts[workoutIndex] = workout.copyWith(
      superSets: filtered,
      exercises: exercises,
    );
  }
}
