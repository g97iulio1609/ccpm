import 'package:alphanessone/trainingBuilder/exercise_dialog.dart';
import 'package:alphanessone/trainingBuilder/series_dialog.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'training_model.dart';
import 'training_services.dart';
import '../users_services.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

final trainingProgramControllerProvider = ChangeNotifierProvider((ref) {
  final service = ref.watch(firestoreServiceProvider);
  final usersService = ref.watch(usersServiceProvider);
  return TrainingProgramController(service, usersService);
});

class TrainingProgramController extends ChangeNotifier {
  final FirestoreService _service;
  final UsersService _usersService;

  TrainingProgramController(this._service, this._usersService);

  TrainingProgram _program = TrainingProgram();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _athleteIdController = TextEditingController();
  final TextEditingController _athleteNameController = TextEditingController();
  final TextEditingController _mesocycleNumberController = TextEditingController();

  TrainingProgram get program => _program;
  TextEditingController get nameController => _nameController;
  TextEditingController get descriptionController => _descriptionController;
  TextEditingController get athleteIdController => _athleteIdController;
  TextEditingController get athleteNameController => _athleteNameController;
  TextEditingController get mesocycleNumberController => _mesocycleNumberController;

  Future<void> loadProgram(String? programId) async {
    if (programId == null) return;

    try {
      _program = await _service.fetchTrainingProgram(programId);
      _nameController.text = _program.name;
      _descriptionController.text = _program.description;
      _athleteIdController.text = _program.athleteId;
      _mesocycleNumberController.text = _program.mesocycleNumber.toString();

      // Ordina gli esercizi in base al campo 'order'
      for (final week in _program.weeks) {
        for (final workout in week.workouts) {
          workout.exercises.sort((a, b) => a.order.compareTo(b.order));
        }
      }

      _rebuildWeekProgressions();
      notifyListeners();
    } catch (error) {
      // Handle error
    }
  }

  void addWeek() {
    final newWeek = Week(number: _program.weeks.length + 1, workouts: []);
    _program.weeks.add(newWeek);
    notifyListeners();
  }

  void removeWeek(int index) {
    final week = _program.weeks[index];
    _removeWeekAndRelatedData(week);
    _program.weeks.removeAt(index);
    _updateWeekNumbers(index);
    notifyListeners();
  }

  void _removeWeekAndRelatedData(Week week) {
    if (week.id != null) {
      _program.trackToDeleteWeeks.add(week.id!);
    }
    week.workouts.forEach(_removeWorkoutAndRelatedData);
  }

  void addWorkout(int weekIndex) {
    final newWorkout = Workout(order: _program.weeks[weekIndex].workouts.length + 1, exercises: []);
    _program.weeks[weekIndex].workouts.add(newWorkout);
    notifyListeners();
  }

  void removeWorkout(int weekIndex, int workoutIndex) {
    final workout = _program.weeks[weekIndex].workouts[workoutIndex];
    _removeWorkoutAndRelatedData(workout);
    _program.weeks[weekIndex].workouts.removeAt(workoutIndex);
    _updateWorkoutOrders(weekIndex, workoutIndex);
    notifyListeners();
  }

  void _removeWorkoutAndRelatedData(Workout workout) {
    if (workout.id != null) {
      _program.trackToDeleteWorkouts.add(workout.id!);
    }
    workout.exercises.forEach(_removeExerciseAndRelatedData);
  }

Future<void> addExercise(int weekIndex, int workoutIndex, BuildContext context) async {
  final exercise = await showDialog<Exercise>(
    context: context,
    builder: (context) => ExerciseDialog(
      usersService: _usersService,
      athleteId: _athleteIdController.text,
    ),
  );
  if (exercise != null) {
    exercise.id = UniqueKey().toString();
    exercise.order = _program.weeks[weekIndex].workouts[workoutIndex].exercises.length + 1;
    _program.weeks[weekIndex].workouts[workoutIndex].exercises.add(exercise);
    notifyListeners();
  }
}

  Future<void> editExercise(int weekIndex, int workoutIndex, int exerciseIndex, BuildContext context) async {
    final exercise = _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final updatedExercise = await showDialog<Exercise>(
      context: context,
      builder: (context) => ExerciseDialog(
        usersService: _usersService,
        athleteId: _athleteIdController.text,
        exercise: exercise,
      ),
    );
    if (updatedExercise != null) {
      updatedExercise.order = exercise.order;
      _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex] = updatedExercise;
      notifyListeners();
    }
  }

  void removeExercise(int weekIndex, int workoutIndex, int exerciseIndex) {
    final exercise = _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    _removeExerciseAndRelatedData(exercise);
    _program.weeks[weekIndex].workouts[workoutIndex].exercises.removeAt(exerciseIndex);
    _updateExerciseOrders(weekIndex, workoutIndex, exerciseIndex);
    notifyListeners();
  }

  void _removeExerciseAndRelatedData(Exercise exercise) {
    if (exercise.id != null) {
      _program.trackToDeleteExercises.add(exercise.id!);
    }
    exercise.series.forEach(_removeSeriesData);
  }

  Future<void> addSeries(int weekIndex, int workoutIndex, int exerciseIndex, BuildContext context) async {
    final exercise = _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final seriesList = await _showSeriesDialog(context, exercise, weekIndex);
    if (seriesList != null) {
      exercise.series.addAll(seriesList);
      notifyListeners();
    }
  }

  Future<void> editSeries(int weekIndex, int workoutIndex, int exerciseIndex, int seriesIndex, BuildContext context) async {
    final series = _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex].series[seriesIndex];
    final exercise = _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final updatedSeriesList = await _showSeriesDialog(context, exercise, weekIndex, series);
    if (updatedSeriesList != null) {
      _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex].series
          .replaceRange(seriesIndex, seriesIndex + 1, updatedSeriesList);
      notifyListeners();
    }
  }

  Future<List<Series>?> _showSeriesDialog(BuildContext context, Exercise exercise, int weekIndex, [Series? series]) async {
    return await showDialog<List<Series>>(
      context: context,
      builder: (context) => SeriesDialog(
        usersService: _usersService,
        athleteId: _athleteIdController.text,
        exerciseId: exercise.exerciseId ?? '',
        weekIndex: weekIndex,
        exercise: exercise,
        series: series,
      ),
    );
  }

  void removeSeries(int weekIndex, int workoutIndex, int exerciseIndex, int seriesIndex) {
    final series = _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex].series[seriesIndex];
    _removeSeriesData(series);
    _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex].series.removeAt(seriesIndex);
    _updateSeriesOrders(weekIndex, workoutIndex, exerciseIndex, seriesIndex);
    notifyListeners();
  }

  void _removeSeriesData(Series series) {
    if (series.serieId != null) {
      _program.trackToDeleteSeries.add(series.serieId!);
    }
  }

void updateWeekProgression(int weekIndex, int workoutIndex, int exerciseIndex, WeekProgression weekProgression) {
  _createWeekProgressionIfNotExists(weekIndex, workoutIndex, exerciseIndex);
  _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex]
      .weekProgressions[weekProgression.weekNumber - 1] = weekProgression;
  notifyListeners();
}

void _createWeekProgressionIfNotExists(int weekIndex, int workoutIndex, int exerciseIndex) {
  final exercise = _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
  final weekCount = _program.weeks.length;

  while (exercise.weekProgressions.length < weekCount) {
    exercise.weekProgressions.add(WeekProgression(
      weekNumber: exercise.weekProgressions.length + 1,
      reps: 0,
      sets: 0,
      intensity: '',
      rpe: '',
      weight: 0.0,
    ));
  }
}
  void updateSeries(int weekIndex, int workoutIndex, int exerciseIndex, List<Series> updatedSeries) {
    _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex].series = updatedSeries;
    notifyListeners();
  }

  void applyWeekProgressions(int exerciseIndex, List<WeekProgression> weekProgressions) {
    for (int weekIndex = 0; weekIndex < _program.weeks.length; weekIndex++) {
      final week = _program.weeks[weekIndex];
      for (final workout in week.workouts) {
        for (int currentExerciseIndex = 0; currentExerciseIndex < workout.exercises.length; currentExerciseIndex++) {
          final exercise = workout.exercises[currentExerciseIndex];
          if (currentExerciseIndex == exerciseIndex) {
            final progression = _getWeekProgression(weekProgressions, weekIndex);
            _updateOrCreateSeries(exercise, progression, weekIndex);
            _updateOrAddWeekProgression(exercise, progression, weekIndex);
          }
        }
      }
    }
    notifyListeners();
  }

  WeekProgression _getWeekProgression(List<WeekProgression> weekProgressions, int weekIndex) {
    return weekIndex < weekProgressions.length
        ? weekProgressions[weekIndex]
        : WeekProgression(
            weekNumber: weekIndex + 1,
            reps: 0,
            sets: 0,
            intensity: '',
            rpe: '',
            weight: 0.0,
          );
  }

  void _updateOrCreateSeries(Exercise exercise, WeekProgression progression, int weekIndex) {
    if (exercise.series.isEmpty) {
      exercise.series = [_createSeries(progression, weekIndex)];
    } else {
      exercise.series[0] = _updateSeries(exercise.series[0], progression);
    }
  }

  Series _createSeries(WeekProgression progression, int weekIndex) {
    return Series(
      serieId: '${weekIndex}_0',
      reps: progression.reps,
      sets: progression.sets,
      intensity: progression.intensity,
      rpe: progression.rpe,
      weight: progression.weight,
      order: 1,
      done: false,
      reps_done: 0,
      weight_done: 0.0,
    );
  }

  Series _updateSeries(Series series, WeekProgression progression) {
    return Series(
      serieId: series.serieId,
      reps: progression.reps,
      sets: progression.sets,
      intensity: progression.intensity,
      rpe: progression.rpe,
      weight: progression.weight,
      order: series.order,
      done: series.done,
      reps_done: series.reps_done,
      weight_done: series.weight_done,
    );
  }

  void _updateOrAddWeekProgression(Exercise exercise, WeekProgression progression, int weekIndex) {
    if (weekIndex < exercise.weekProgressions.length) {
      exercise.weekProgressions[weekIndex] = progression;
    } else {
      exercise.weekProgressions.add(progression);
    }
  }

  WeekProgression getWeekProgression(int weekIndex, int exerciseIndex) {
    final week = _program.weeks[weekIndex];
    for (final workout in week.workouts) {
      if (workout.exercises.length > exerciseIndex) {
        final exercise = workout.exercises[exerciseIndex];
        if (exercise.weekProgressions.length > weekIndex) {
          return exercise.weekProgressions[weekIndex];
        }
      }
    }
    return WeekProgression(weekNumber: weekIndex + 1, reps: 0, sets: 0, intensity: '', rpe: '', weight: 0);
  }

  void _rebuildWeekProgressions() {
    for (final week in _program.weeks) {
      for (final workout in week.workouts) {
        for (final exercise in workout.exercises) {
          _rebuildExerciseProgressions(exercise, _program.weeks.indexOf(week));
        }
      }
    }
    notifyListeners();
  }

  void _rebuildExerciseProgressions(Exercise exercise, int currentWeekIndex) {
    final weekProgressions = List<WeekProgression>.generate(
      _program.weeks.length,
      (index) => WeekProgression(
        weekNumber: index + 1,
        reps: 0,
        sets: 0,
        intensity: '',
        rpe: '',
        weight: 0.0,
      ),
    );

    for (int weekIndex = 0; weekIndex < _program.weeks.length; weekIndex++) {
      final week = _program.weeks[weekIndex];
      for (final workout in week.workouts) {
        for (final currentExercise in workout.exercises) {
          if (currentExercise.id == exercise.id && currentExercise.series.isNotEmpty) {
            final series = currentExercise.series[0];
            weekProgressions[weekIndex] = WeekProgression(
              weekNumber: weekIndex + 1,
              reps: series.reps,
              sets: series.sets,
              intensity: series.intensity,
              rpe: series.rpe,
              weight: series.weight,
            );
          }
        }
      }
    }

    exercise.weekProgressions = weekProgressions;
  }

  void updateExerciseProgressions(Exercise exercise, List<WeekProgression> updatedProgressions) {
    for (int weekIndex = 0; weekIndex < _program.weeks.length; weekIndex++) {
      final week = _program.weeks[weekIndex];
      for (final workout in week.workouts) {
        for (final currentExercise in workout.exercises) {
          if (currentExercise.id == exercise.id) {
            currentExercise.weekProgressions = updatedProgressions;
            _updateOrCreateSeries(currentExercise, updatedProgressions[weekIndex], weekIndex);
          }
        }
      }
    }
    notifyListeners();
  }

  void reorderWeeks(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final week = _program.weeks.removeAt(oldIndex);
    _program.weeks.insert(newIndex, week);
    _updateWeekNumbers(newIndex);
    notifyListeners();
  }

  void _updateWeekNumbers(int startIndex) {
for (int i = startIndex; i < _program.weeks.length; i++) {
_program.weeks[i].number = i + 1;
}
}
void reorderWorkouts(int weekIndex, int oldIndex, int newIndex) {
if (oldIndex < newIndex) {
newIndex -= 1;
}
final workout = _program.weeks[weekIndex].workouts.removeAt(oldIndex);
_program.weeks[weekIndex].workouts.insert(newIndex, workout);
_updateWorkoutOrders(weekIndex, newIndex);
notifyListeners();
}
void _updateWorkoutOrders(int weekIndex, int startIndex) {
for (int i = startIndex; i < _program.weeks[weekIndex].workouts.length; i++) {
_program.weeks[weekIndex].workouts[i].order = i + 1;
}
}
void reorderExercises(int weekIndex, int workoutIndex, int oldIndex, int newIndex) {
if (oldIndex < newIndex) {
newIndex -= 1;
}
final exercise = _program.weeks[weekIndex].workouts[workoutIndex].exercises.removeAt(oldIndex);
_program.weeks[weekIndex].workouts[workoutIndex].exercises.insert(newIndex, exercise);
_updateExerciseOrders(weekIndex, workoutIndex, newIndex);
notifyListeners();
}
void _updateExerciseOrders(int weekIndex, int workoutIndex, int startIndex) {
for (int i = startIndex; i < _program.weeks[weekIndex].workouts[workoutIndex].exercises.length; i++) {
_program.weeks[weekIndex].workouts[workoutIndex].exercises[i].order = i + 1;
}
}
void reorderSeries(int weekIndex, int workoutIndex, int exerciseIndex, int oldIndex, int newIndex) {
if (oldIndex < newIndex) {
newIndex -= 1;
}
final exercise = _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
final series = exercise.series.removeAt(oldIndex);
exercise.series.insert(newIndex, series);
_updateSeriesOrders(weekIndex, workoutIndex, exerciseIndex, newIndex);
notifyListeners();
}
void _updateSeriesOrders(int weekIndex, int workoutIndex, int exerciseIndex, int startIndex) {
final exercise = _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
for (int i = startIndex; i < exercise.series.length; i++) {
exercise.series[i].order = i + 1;
}
}

Future<void> submitProgram(BuildContext context) async {
_program.name = _nameController.text;
_program.description = _descriptionController.text;
_program.athleteId = _athleteIdController.text;
_program.mesocycleNumber = int.tryParse(_mesocycleNumberController.text) ?? 0;
try {
  await _service.addOrUpdateTrainingProgram(_program);
  await _service.removeToDeleteItems(_program);
  await _usersService.updateUser(_athleteIdController.text, {'currentProgram': program.id});

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Program added/updated successfully')),
  );
  // resetFields();
} catch (error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error adding/updating program: $error')),
  );
}}


void resetFields() {
_program = TrainingProgram();
_nameController.clear();
_descriptionController.clear();
_athleteIdController.clear();
_mesocycleNumberController.clear();
notifyListeners();
}
}
