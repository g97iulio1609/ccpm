part of 'training_program_controller.dart';

extension SuperSetExtension on TrainingProgramController {
  static int _superSetCounter = 0;

  void loadSuperSets() {
    int maxSuperSetIndex = 0;
    final superSets = <SuperSet>[];
    final exercisesWithSuperSet = _program.weeks.expand((week) =>
        week.workouts.expand((workout) =>
            workout.exercises.where((exercise) => exercise.superSetId != null)));

    for (final exercise in exercisesWithSuperSet) {
      final superSetId = exercise.superSetId;
      if (superSetId != null) {
        final existingSuperSet = superSets.firstWhere(
          (superSet) => superSet.id == superSetId,
          orElse: () => SuperSet(id: superSetId, name: 'SS${superSets.length + 1}', exerciseIds: []),
        );
        final superSetIndex = int.tryParse(existingSuperSet.name?.replaceAll('SS', '') ?? '0') ?? 0;
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

    for (final week in _program.weeks) {
      for (final workout in week.workouts) {
        final workoutSuperSets = superSets.where((superSet) {
          return superSet.exerciseIds.any((exerciseId) {
            return workout.exercises.any((exercise) => exercise.id == exerciseId);
          });
        }).toList();
        workout.superSets = workoutSuperSets;
      }
    }

    _superSetCounter = maxSuperSetIndex + 1;
    notifyListeners();
  }

  void createSuperSet(int weekIndex, int workoutIndex) {
    final superSetId = generateRandomId(16);
    final superSetName = 'SS${_superSetCounter + 1}';
    _superSetCounter++;

    if (_superSetCounter > 100) {
      _superSetCounter = 1;
    }

    final superSet = SuperSet(id: superSetId, name: superSetName, exerciseIds: []);
    _program.weeks[weekIndex].workouts[workoutIndex].superSets.add(superSet);
    notifyListeners();
  }

  void addExerciseToSuperSet(int weekIndex, int workoutIndex, String superSetId, String exerciseId) {
    final superSet = _program.weeks[weekIndex].workouts[workoutIndex].superSets.firstWhere(
      (ss) => ss.id == superSetId,
    );
    superSet.exerciseIds.add(exerciseId);

    final exercise = _program.weeks[weekIndex].workouts[workoutIndex].exercises.firstWhere(
      (e) => e.id == exerciseId,
    );
    exercise.superSetId = superSetId;

    notifyListeners();
  }

  void removeExerciseFromSuperSet(int weekIndex, int workoutIndex, String superSetId, String exerciseId) {
    final superSet = _program.weeks[weekIndex].workouts[workoutIndex].superSets.firstWhere(
      (ss) => ss.id == superSetId,
    );
    superSet.exerciseIds.remove(exerciseId);

    final exercise = _program.weeks[weekIndex].workouts[workoutIndex].exercises.firstWhere(
      (e) => e.id == exerciseId,
    );
    exercise.superSetId = null;

    if (superSet.exerciseIds.isEmpty) {
      removeSuperSet(weekIndex, workoutIndex, superSetId);
    }

    notifyListeners();
  }

  void removeSuperSet(int weekIndex, int workoutIndex, String superSetId) {
    final workout = _program.weeks[weekIndex].workouts[workoutIndex];
    final removedSuperSets = workout.superSets.where((ss) => ss.id == superSetId).toList();
    workout.superSets.removeWhere((ss) => ss.id == superSetId);

    if (removedSuperSets.isNotEmpty) {
      final removedSuperSetIndex = int.tryParse(removedSuperSets.first.name?.replaceAll('SS', '') ?? '0') ?? 0;
      _superSetCounter = removedSuperSetIndex;
    }

    for (int i = 0; i < workout.superSets.length; i++) {
      workout.superSets[i].name = 'SS${i + 1}';
    }

    notifyListeners();
  }
}