import 'package:alphanessone/shared/shared.dart'
    hide ValidationUtils, ModelUtils, ExerciseRepository;
import '../../shared/utils/validation_utils.dart';
import '../../shared/utils/model_utils.dart';

/// Business service per le operazioni sui workout
/// Segue il principio Single Responsibility
class WorkoutBusinessService {
  WorkoutBusinessService();

  /// Aggiunge un nuovo workout alla settimana
  void addWorkout(TrainingProgram program, int weekIndex) {
    if (!ValidationUtils.isValidProgramIndex(program, weekIndex)) {
      throw ArgumentError('Indice settimana non valido: $weekIndex');
    }

    final newWorkout = Workout(
      name: 'Workout ${program.weeks[weekIndex].workouts.length + 1}',
      order: program.weeks[weekIndex].workouts.length + 1,
      exercises: [],
    );
    program.weeks[weekIndex].workouts.add(newWorkout);
  }

  /// Rimuove un workout dalla settimana
  void removeWorkout(TrainingProgram program, int weekIndex, int workoutIndex) {
    if (!ValidationUtils.isValidProgramIndex(
      program,
      weekIndex,
      workoutIndex,
    )) {
      throw ArgumentError(
        'Indici non validi: week=$weekIndex, workout=$workoutIndex',
      );
    }

    final workout = program.weeks[weekIndex].workouts[workoutIndex];
    _trackWorkoutForDeletion(program, workout);
    program.weeks[weekIndex].workouts.removeAt(workoutIndex);
    ModelUtils.updateWorkoutOrders(
      program.weeks[weekIndex].workouts,
      workoutIndex,
    );
  }

  /// Copia un workout in un'altra settimana
  Future<void> copyWorkout(
    TrainingProgram program,
    int sourceWeekIndex,
    int workoutIndex,
    int? destinationWeekIndex,
  ) async {
    if (!ValidationUtils.isValidProgramIndex(
      program,
      sourceWeekIndex,
      workoutIndex,
    )) {
      throw ArgumentError('Indici sorgente non validi');
    }

    final sourceWorkout = program.weeks[sourceWeekIndex].workouts[workoutIndex];
    final copiedWorkout = ModelUtils.copyWorkout(sourceWorkout);

    if (destinationWeekIndex != null &&
        destinationWeekIndex < program.weeks.length) {
      final destinationWeek = program.weeks[destinationWeekIndex];
      final existingWorkoutIndex = destinationWeek.workouts.indexWhere(
        (workout) => workout.order == sourceWorkout.order,
      );

      if (existingWorkoutIndex != -1) {
        final existingWorkout = destinationWeek.workouts[existingWorkoutIndex];
        if (existingWorkout.id != null) {
          program.trackToDeleteWorkouts.add(existingWorkout.id!);
        }
        destinationWeek.workouts[existingWorkoutIndex] = copiedWorkout;
      } else {
        destinationWeek.workouts.add(copiedWorkout);
      }
    } else {
      // Se la destinazione è null, copia nella stessa settimana sorgente
      if (destinationWeekIndex == null) {
        program.weeks[sourceWeekIndex].workouts.add(copiedWorkout);
        return;
      }

      // Destinazione oltre il numero attuale di settimane -> aggiungi solo il necessario
      while (program.weeks.length <= destinationWeekIndex) {
        _addWeekToProgram(program);
      }
      program.weeks[destinationWeekIndex].workouts.add(copiedWorkout);
    }
  }

  /// Riordina i workout in una settimana
  void reorderWorkouts(
    TrainingProgram program,
    int weekIndex,
    int oldIndex,
    int newIndex,
  ) {
    if (!ValidationUtils.isValidProgramIndex(program, weekIndex) ||
        oldIndex < 0 ||
        oldIndex >= program.weeks[weekIndex].workouts.length ||
        newIndex < 0 ||
        newIndex > program.weeks[weekIndex].workouts.length) {
      throw ArgumentError('Indici di riordinamento non validi');
    }

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final workout = program.weeks[weekIndex].workouts.removeAt(oldIndex);
    program.weeks[weekIndex].workouts.insert(newIndex, workout);
    ModelUtils.updateWorkoutOrders(program.weeks[weekIndex].workouts, 0);
  }

  /// Aggiorna un workout specifico
  void updateWorkout(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
    Workout updatedWorkout,
  ) {
    if (!ValidationUtils.isValidProgramIndex(
      program,
      weekIndex,
      workoutIndex,
    )) {
      throw ArgumentError('Indici non validi per aggiornamento workout');
    }

    program.weeks[weekIndex].workouts[workoutIndex] = updatedWorkout;
  }

  /// Duplica un workout nella stessa settimana
  void duplicateWorkout(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
  ) {
    if (!ValidationUtils.isValidProgramIndex(
      program,
      weekIndex,
      workoutIndex,
    )) {
      throw ArgumentError('Indici non validi per duplicazione workout');
    }

    final sourceWorkout = program.weeks[weekIndex].workouts[workoutIndex];
    final duplicatedWorkout = ModelUtils.copyWorkout(sourceWorkout);

    final workoutWithNewOrder = duplicatedWorkout.copyWith(
      order: program.weeks[weekIndex].workouts.length + 1,
    );
    program.weeks[weekIndex].workouts.add(workoutWithNewOrder);
  }

  /// Valida che tutti i workout della settimana siano corretti
  bool validateWeekWorkouts(Week week) {
    final workouts = week.workouts;

    // Controlla ordini sequenziali
    for (int i = 0; i < workouts.length; i++) {
      if (workouts[i].order != i + 1) {
        return false;
      }
    }

    // Controlla che ogni workout abbia almeno un esercizio o sia configurato correttamente
    return workouts.every(
      (workout) => workout.exercises.isNotEmpty || workout.order > 0,
    );
  }

  /// Ottiene statistiche sui workout per una settimana
  Map<String, dynamic> getWorkoutStatistics(Week week) {
    int totalExercises = 0;
    int totalSeries = 0;
    final exerciseTypes = <String, int>{};

    for (final workout in week.workouts) {
      totalExercises += workout.exercises.length;

      for (final exercise in workout.exercises) {
        totalSeries += exercise.series.length;
        exerciseTypes[exercise.type] = (exerciseTypes[exercise.type] ?? 0) + 1;
      }
    }

    return {
      'totalWorkouts': week.workouts.length,
      'totalExercises': totalExercises,
      'totalSeries': totalSeries,
      'averageExercisesPerWorkout': week.workouts.isNotEmpty
          ? totalExercises / week.workouts.length
          : 0,
      'exerciseTypeDistribution': exerciseTypes,
    };
  }

  // Metodi privati helper

  void _trackWorkoutForDeletion(TrainingProgram program, Workout workout) {
    if (workout.id != null) {
      program.trackToDeleteWorkouts.add(workout.id!);
    }
    for (final exercise in workout.exercises) {
      _trackExerciseForDeletion(program, exercise);
    }
  }

  void _trackExerciseForDeletion(TrainingProgram program, Exercise exercise) {
    if (exercise.id != null) {
      program.trackToDeleteExercises.add(exercise.id!);
    }
    for (final series in exercise.series) {
      _trackSeriesForDeletion(program, series);
    }
  }

  void _trackSeriesForDeletion(TrainingProgram program, Series series) {
    program.markSeriesForDeletion(series);
  }

  void _addWeekToProgram(TrainingProgram program) {
    final newWeek = Week(
      id: null,
      number: program.weeks.length + 1,
      workouts: [Workout(id: '', name: 'Workout 1', order: 1, exercises: [])],
    );
    program.weeks.add(newWeek);
  }
}
