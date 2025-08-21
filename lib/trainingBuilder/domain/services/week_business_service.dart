import 'package:alphanessone/shared/shared.dart' hide ValidationUtils, ModelUtils, WeekRepository;
import '../../shared/utils/validation_utils.dart';
import '../../shared/utils/model_utils.dart';

/// Business service per le operazioni sulle settimane
/// Segue il principio Single Responsibility
class WeekBusinessService {
  WeekBusinessService();

  /// Aggiunge una nuova settimana al programma
  void addWeek(TrainingProgram program) {
    final newWeek = Week(
      id: null,
      number: program.weeks.length + 1,
      workouts: [Workout(id: '', name: 'Workout 1', order: 1, exercises: [])],
    );
    program.weeks.add(newWeek);
  }

  /// Rimuove una settimana dal programma con validazione
  void removeWeek(TrainingProgram program, int weekIndex) {
    if (!ValidationUtils.isValidProgramIndex(program, weekIndex)) {
      throw ArgumentError('Indice settimana non valido: $weekIndex');
    }

    final week = program.weeks[weekIndex];
    _trackWeekForDeletion(program, week);
    program.weeks.removeAt(weekIndex);
    ModelUtils.updateWeekNumbers(program.weeks, weekIndex);
  }

  /// Copia una settimana in una nuova posizione
  Future<void> copyWeek(
    TrainingProgram program,
    int sourceWeekIndex,
    int? destinationWeekIndex,
  ) async {
    if (!ValidationUtils.isValidProgramIndex(program, sourceWeekIndex)) {
      throw ArgumentError('Indice settimana sorgente non valido: $sourceWeekIndex');
    }

    final sourceWeek = program.weeks[sourceWeekIndex];
    final copiedWeek = ModelUtils.copyWeek(sourceWeek);

    if (destinationWeekIndex != null && destinationWeekIndex < program.weeks.length) {
      final destinationWeek = program.weeks[destinationWeekIndex];
      if (destinationWeek.id != null) {
        program.trackToDeleteWeeks.add(destinationWeek.id!);
      }
      program.weeks[destinationWeekIndex] = copiedWeek;
    } else {
      final weekWithNewNumber = copiedWeek.copyWith(number: program.weeks.length + 1);
      program.weeks.add(weekWithNewNumber);
    }
  }

  /// Riordina le settimane nel programma
  void reorderWeeks(TrainingProgram program, int oldIndex, int newIndex) {
    if (!ValidationUtils.isValidProgramIndex(program, oldIndex) ||
        newIndex < 0 ||
        newIndex >= program.weeks.length) {
      throw ArgumentError('Indici di riordinamento non validi');
    }

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final week = program.weeks.removeAt(oldIndex);
    program.weeks.insert(newIndex, week);
    ModelUtils.updateWeekNumbers(program.weeks, 0);
  }

  /// Aggiorna una settimana specifica
  void updateWeek(TrainingProgram program, int weekIndex, Week updatedWeek) {
    if (!ValidationUtils.isValidProgramIndex(program, weekIndex)) {
      throw ArgumentError('Indice settimana non valido: $weekIndex');
    }

    program.weeks[weekIndex] = updatedWeek;
  }

  /// Valida che tutte le settimane del programma siano corrette
  bool validateProgram(TrainingProgram program) {
    if (!ValidationUtils.isValidTrainingProgram(program)) {
      return false;
    }

    for (int i = 0; i < program.weeks.length; i++) {
      final week = program.weeks[i];
      if (week.number != i + 1) {
        return false;
      }
    }

    return true;
  }

  /// Ottiene informazioni statistiche sulle settimane
  Map<String, dynamic> getWeekStatistics(TrainingProgram program) {
    int totalWorkouts = 0;
    int totalExercises = 0;

    for (final week in program.weeks) {
      totalWorkouts += week.workouts.length;
      for (final workout in week.workouts) {
        totalExercises += workout.exercises.length;
      }
    }

    return {
      'totalWeeks': program.weeks.length,
      'totalWorkouts': totalWorkouts,
      'totalExercises': totalExercises,
      'averageWorkoutsPerWeek': program.weeks.isNotEmpty ? totalWorkouts / program.weeks.length : 0,
      'averageExercisesPerWorkout': totalWorkouts > 0 ? totalExercises / totalWorkouts : 0,
    };
  }

  // Metodi privati helper

  void _trackWeekForDeletion(TrainingProgram program, Week week) {
    if (week.id != null) {
      program.trackToDeleteWeeks.add(week.id!);
    }
    for (var workout in week.workouts) {
      _trackWorkoutForDeletion(program, workout);
    }
  }

  void _trackWorkoutForDeletion(TrainingProgram program, Workout workout) {
    if (workout.id != null) {
      program.trackToDeleteWorkouts.add(workout.id!);
    }
    for (var exercise in workout.exercises) {
      _trackExerciseForDeletion(program, exercise);
    }
  }

  void _trackExerciseForDeletion(TrainingProgram program, exercise) {
    if (exercise.id != null) {
      program.trackToDeleteExercises.add(exercise.id!);
    }
    for (var series in exercise.series) {
      _trackSeriesForDeletion(program, series);
    }
  }

  void _trackSeriesForDeletion(TrainingProgram program, series) {
    if (series.serieId != null) {
      program.trackToDeleteSeries.add(series.serieId!);
    }
  }
}
