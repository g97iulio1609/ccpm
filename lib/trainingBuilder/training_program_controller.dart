import 'package:alphanessone/trainingBuilder/exercise_dialog.dart';
import 'package:alphanessone/trainingBuilder/series_dialog.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'trainingModel.dart';
import 'trainingServices.dart';
import '../usersServices.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final trainingProgramControllerProvider = ChangeNotifierProvider((ref) {
  final service = ref.watch(firestoreServiceProvider);
  final usersService = ref.watch(usersServiceProvider);
  return TrainingProgramController(service, usersService);
});

class TrainingProgramController extends ChangeNotifier {
  final FirestoreService _service;
  final UsersService _usersService;

  TrainingProgramController(this._service, this._usersService);

  TrainingProgram program = TrainingProgram();
  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController athleteIdController = TextEditingController();
  TextEditingController athleteNameController = TextEditingController();
  TextEditingController mesocycleNumberController = TextEditingController();

  void loadProgram(String? programId) {
    if (programId != null) {
      _service.fetchTrainingProgram(programId).then((program) {
        this.program = program;
        nameController.text = program.name;
        descriptionController.text = program.description;
        athleteIdController.text = program.athleteId;
        mesocycleNumberController.text = program.mesocycleNumber.toString();
        rebuildWeekProgressions();
        notifyListeners();
      }).catchError((error) {
        // Handle error
      });
    }
  }

  void addWeek() {
    Week newWeek = Week(number: program.weeks.length + 1, workouts: []);
    program.weeks.add(newWeek);
    notifyListeners();
  }

void removeWeek(int index) {
  Week week = program.weeks[index];
  _removeWeekAndRelatedData(week);
  program.weeks.removeAt(index);
  _updateWeekNumbers(index); // Aggiungi questa riga
  notifyListeners();
}

void _updateWeekNumbers(int startIndex) {
  for (int i = startIndex; i < program.weeks.length; i++) {
    program.weeks[i].number = i + 1;
  }
}

  void _removeWeekAndRelatedData(Week week) {
    if (week.id != null) {
      program.trackToDeleteWeeks.add(week.id!);
    }
    for (var workout in week.workouts) {
      _removeWorkoutAndRelatedData(workout);
    }
  }

  void addWorkout(int weekIndex) {
    Workout newWorkout = Workout(order: program.weeks[weekIndex].workouts.length + 1, exercises: []);
    program.weeks[weekIndex].workouts.add(newWorkout);
    notifyListeners();
  }

  void removeWorkout(int weekIndex, int workoutIndex) {
  Workout workout = program.weeks[weekIndex].workouts[workoutIndex];
  _removeWorkoutAndRelatedData(workout);
  program.weeks[weekIndex].workouts.removeAt(workoutIndex);
  _updateWorkoutOrders(weekIndex, workoutIndex); // Aggiungi questa riga
  notifyListeners();
}

void _updateWorkoutOrders(int weekIndex, int startIndex) {
  for (int i = startIndex; i < program.weeks[weekIndex].workouts.length; i++) {
    program.weeks[weekIndex].workouts[i].order = i + 1;
  }
}

  void _removeWorkoutAndRelatedData(Workout workout) {
    if (workout.id != null) {
      program.trackToDeleteWorkouts.add(workout.id!);
    }
    for (var exercise in workout.exercises) {
      _removeExerciseAndRelatedData(exercise);
    }
  }

  Future<void> addExercise(int weekIndex, int workoutIndex, BuildContext context) async {
    final exercise = await showDialog<Exercise>(
      context: context,
      builder: (context) => ExerciseDialog(
        usersService: _usersService,
        athleteId: athleteIdController.text,
      ),
    );
    if (exercise != null) {
      exercise.id = UniqueKey().toString();
      exercise.order = program.weeks[weekIndex].workouts[workoutIndex].exercises.length + 1;
      program.weeks[weekIndex].workouts[workoutIndex].exercises.add(exercise);
      notifyListeners();
    }
  }

  Future<void> editExercise(int weekIndex, int workoutIndex, int exerciseIndex, BuildContext context) async {
    final exercise = program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final updatedExercise = await showDialog<Exercise>(
      context: context,
      builder: (context) => ExerciseDialog(
        usersService: _usersService,
        athleteId: athleteIdController.text,
        exercise: exercise,
      ),
    );
    if (updatedExercise != null) {
      updatedExercise.order = exercise.order;
      program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex] = updatedExercise;
      notifyListeners();
    }
  }

void removeExercise(int weekIndex, int workoutIndex, int exerciseIndex) {
  Exercise exercise = program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
  _removeExerciseAndRelatedData(exercise);
  program.weeks[weekIndex].workouts[workoutIndex].exercises.removeAt(exerciseIndex);
  _updateExerciseOrders(weekIndex, workoutIndex, exerciseIndex); // Aggiungi questa riga
  notifyListeners();
}

void _updateExerciseOrders(int weekIndex, int workoutIndex, int startIndex) {
  for (int i = startIndex; i < program.weeks[weekIndex].workouts[workoutIndex].exercises.length; i++) {
    program.weeks[weekIndex].workouts[workoutIndex].exercises[i].order = i + 1;
  }
}

  void _removeExerciseAndRelatedData(Exercise exercise) {
    if (exercise.id != null) {
      program.trackToDeleteExercises.add(exercise.id!);
    }
    for (var series in exercise.series) {
      _removeSeriesData(series);
    }
  }

  Future<void> addSeries(int weekIndex, int workoutIndex, int exerciseIndex, BuildContext context) async {
    final exercise = program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final seriesList = await showDialog<List<Series>>(
      context: context,
      builder: (context) => SeriesDialog(
        usersService: _usersService,
        athleteId: athleteIdController.text,
        exerciseId: exercise.exerciseId ?? '',
        weekIndex: weekIndex,
        exercise: exercise,
      ),
    );
    if (seriesList != null) {
      exercise.series.addAll(seriesList);
      notifyListeners();
    }
  }

  Future<void> editSeries(int weekIndex, int workoutIndex, int exerciseIndex, int seriesIndex, BuildContext context) async {
    final series = program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex].series[seriesIndex];
    final exercise = program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];

    final updatedSeriesList = await showDialog<List<Series>>(
      context: context,
      builder: (context) => SeriesDialog(
        usersService: _usersService,
        athleteId: athleteIdController.text,
        exerciseId: exercise.exerciseId ?? '',
        weekIndex: weekIndex,
        exercise: exercise,
        series: series,
      ),
    );
    if (updatedSeriesList != null) {
      program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex].series.replaceRange(seriesIndex, seriesIndex + 1, updatedSeriesList);
      notifyListeners();
    }
  }

void removeSeries(int weekIndex, int workoutIndex, int exerciseIndex, int seriesIndex) {
  Series series = program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex].series[seriesIndex];
  _removeSeriesData(series);
  program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex].series.removeAt(seriesIndex);
  _updateSeriesOrders(weekIndex, workoutIndex, exerciseIndex, seriesIndex); // Aggiungi questa riga
  notifyListeners();
}

void _updateSeriesOrders(int weekIndex, int workoutIndex, int exerciseIndex, int startIndex) {
  for (int i = startIndex; i < program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex].series.length; i++) {
    program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex].series[i].order = i + 1;
  }
}

  void _removeSeriesData(Series series) {
    if (series.serieId != null) {
      program.trackToDeleteSeries.add(series.serieId!);
    }
  }

  void updateWeekProgression(int weekIndex, int workoutIndex, int exerciseIndex, WeekProgression weekProgression) {
    if (weekIndex < program.weeks.length &&
        workoutIndex < program.weeks[weekIndex].workouts.length &&
        exerciseIndex < program.weeks[weekIndex].workouts[workoutIndex].exercises.length) {
      program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex]
          .weekProgressions[weekProgression.weekNumber - 1] = weekProgression;
      notifyListeners();
    } else {
      // Gestisci l'errore o ignoralo se necessario
    }
  }

  void updateSeries(int weekIndex, int workoutIndex, int exerciseIndex, List<Series> updatedSeries) {
    program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex].series = updatedSeries;
    notifyListeners();
  }

  void applyWeekProgressions(int exerciseIndex, List<WeekProgression> weekProgressions) {
  print('Applying week progressions for exercise index: $exerciseIndex');
  print('Week progressions: $weekProgressions');

  for (var weekIndex = 0; weekIndex < program.weeks.length; weekIndex++) {
    final week = program.weeks[weekIndex];
    for (var workoutIndex = 0; workoutIndex < week.workouts.length; workoutIndex++) {
      final workout = week.workouts[workoutIndex];
      for (var currentExerciseIndex = 0; currentExerciseIndex < workout.exercises.length; currentExerciseIndex++) {
        final exercise = workout.exercises[currentExerciseIndex];
        if (currentExerciseIndex == exerciseIndex) {
          final progression = weekIndex < weekProgressions.length
              ? weekProgressions[weekIndex]
              : WeekProgression(
                  weekNumber: weekIndex + 1,
                  reps: 0,
                  sets: 0,
                  intensity: '',
                  rpe: '',
                  weight: 0.0,
                );

          print('Updating series for week: $weekIndex, workout: $workoutIndex, exercise: $currentExerciseIndex');
          print('Progression: $progression');
          _updateOrCreateSeries(exercise, progression, weekIndex);
          _updateOrAddWeekProgression(exercise, progression, weekIndex);
        }
      }
    }
  }
  notifyListeners();
}

void _updateOrCreateSeries(Exercise exercise, WeekProgression progression, int weekIndex) {
  print('Updating or creating series for exercise: ${exercise.id}, week: $weekIndex');
  print('Progression: $progression');

  if (exercise.series.isEmpty) {
    print('Creating new series');
    exercise.series = [
      Series(
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
      ),
    ];
  } else {
    print('Updating existing series');
    exercise.series[0] = Series(
      serieId: exercise.series[0].serieId,
      reps: progression.reps,
      sets: progression.sets,
      intensity: progression.intensity,
      rpe: progression.rpe,
      weight: progression.weight,
      order: exercise.series[0].order,
      done: exercise.series[0].done,
      reps_done: exercise.series[0].reps_done,
      weight_done: exercise.series[0].weight_done,
    );
  }
}

void _updateOrAddWeekProgression(Exercise exercise, WeekProgression progression, int weekIndex) {
  print('Updating or adding week progression for exercise: ${exercise.id}, week: $weekIndex');
  print('Progression: $progression');

  if (weekIndex < exercise.weekProgressions.length) {
    print('Updating existing week progression');
    exercise.weekProgressions[weekIndex] = progression;
  } else {
    print('Adding new week progression');
    exercise.weekProgressions.add(progression);
  }
}

  WeekProgression getWeekProgression(int weekIndex, int exerciseIndex) {
    final week = program.weeks[weekIndex];
    for (var workoutIndex = 0; workoutIndex < week.workouts.length; workoutIndex++) {
      final workout = week.workouts[workoutIndex];
      if (workout.exercises.length > exerciseIndex) {
        final exercise = workout.exercises[exerciseIndex];
        if (exercise.weekProgressions.length > weekIndex) {
          return exercise.weekProgressions[weekIndex];
        }
      }
    }
    return WeekProgression(weekNumber: weekIndex + 1, reps: 0, sets: 0, intensity: '', rpe: '', weight: 0);
  }

void rebuildWeekProgressions() {
  print('Rebuilding week progressions');

  for (var weekIndex = 0; weekIndex < program.weeks.length; weekIndex++) {
    final week = program.weeks[weekIndex];
    for (var workoutIndex = 0; workoutIndex < week.workouts.length; workoutIndex++) {
      final workout = week.workouts[workoutIndex];
      for (var exerciseIndex = 0; exerciseIndex < workout.exercises.length; exerciseIndex++) {
        final exercise = workout.exercises[exerciseIndex];
        final exerciseId = exercise.exerciseId;

        print('Rebuilding week progressions for exercise: $exerciseId');

        final weekProgressions = List<WeekProgression>.generate(
          program.weeks.length,
          (index) => WeekProgression(
            weekNumber: index + 1,
            reps: 0,
            sets: 0,
            intensity: '',
            rpe: '',
            weight: 0.0,
          ),
        );

        print('Generated week progressions: $weekProgressions');

        for (var progressionWeekIndex = 0; progressionWeekIndex < program.weeks.length; progressionWeekIndex++) {
          final progressionWeek = program.weeks[progressionWeekIndex];
          for (var progressionWorkoutIndex = 0; progressionWorkoutIndex < progressionWeek.workouts.length; progressionWorkoutIndex++) {
            final progressionWorkout = progressionWeek.workouts[progressionWorkoutIndex];
            for (var progressionExerciseIndex = 0; progressionExerciseIndex < progressionWorkout.exercises.length; progressionExerciseIndex++) {
              final progressionExercise = progressionWorkout.exercises[progressionExerciseIndex];
              if (progressionExercise.exerciseId == exerciseId && progressionExercise.series.isNotEmpty) {
                final series = progressionExercise.series[0];
                print('Found matching exercise in week: $progressionWeekIndex, workout: $progressionWorkoutIndex, exercise: $progressionExerciseIndex');
                print('Series: $series');
                weekProgressions[progressionWeekIndex] = WeekProgression(
                  weekNumber: progressionWeekIndex + 1,
                  reps: series.reps,
                  sets: series.sets,
                  intensity: series.intensity,
                  rpe: series.rpe,
                  weight: series.weight,
                );
                print('Updated week progression: ${weekProgressions[progressionWeekIndex]}');
              }
            }
          }
        }

        print('Rebuilt week progressions: $weekProgressions');
        exercise.weekProgressions = weekProgressions;
      }
    }
  }

  notifyListeners();
}

void _rebuildExerciseProgressions(Exercise exercise, int currentWeekIndex) {
  print('Rebuilding progressions for exercise: ${exercise.id}, current week: $currentWeekIndex');

  final weekProgressions = List<WeekProgression>.generate(
    program.weeks.length,
    (index) => WeekProgression(
      weekNumber: index + 1,
      reps: 0,
      sets: 0,
      intensity: '',
      rpe: '',
      weight: 0.0,
    ),
  );

  print('Generated week progressions: $weekProgressions');

  for (var weekIndex = 0; weekIndex < program.weeks.length; weekIndex++) {
    final week = program.weeks[weekIndex];
    for (var workoutIndex = 0; workoutIndex < week.workouts.length; workoutIndex++) {
      final workout = week.workouts[workoutIndex];
      for (var exerciseIndex = 0; exerciseIndex < workout.exercises.length; exerciseIndex++) {
        final currentExercise = workout.exercises[exerciseIndex];
        if (currentExercise.id == exercise.id && currentExercise.series.isNotEmpty) {
          final series = currentExercise.series[0];
          print('Found matching exercise in week: $weekIndex, workout: $workoutIndex, exercise: $exerciseIndex');
          print('Series: $series');
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

  print('Rebuilt week progressions: $weekProgressions');
  exercise.weekProgressions = weekProgressions;
}

void updateExerciseProgressions(Exercise exercise, List<WeekProgression> updatedProgressions) {
  for (var weekIndex = 0; weekIndex < program.weeks.length; weekIndex++) {
    final week = program.weeks[weekIndex];
    for (var workoutIndex = 0; workoutIndex < week.workouts.length; workoutIndex++) {
      final workout = week.workouts[workoutIndex];
      for (var exerciseIndex = 0; exerciseIndex < workout.exercises.length; exerciseIndex++) {
        final currentExercise = workout.exercises[exerciseIndex];
        if (currentExercise.id == exercise.id) {
          currentExercise.weekProgressions = updatedProgressions;
          _updateOrCreateSeries(currentExercise, updatedProgressions[weekIndex], weekIndex);
        }
      }
    }
  }
  notifyListeners();
}

//Reorder
void reorderWeeks(int oldIndex, int newIndex) {
  if (oldIndex < newIndex) {
    newIndex -= 1;
  }
  final week = program.weeks.removeAt(oldIndex);
  program.weeks.insert(newIndex, week);
  _updateWeekNumbers(0);
  notifyListeners();
}
void reorderWorkouts(int weekIndex, int oldIndex, int newIndex) {
  if (oldIndex < newIndex) {
    newIndex -= 1;
  }
  final workout = program.weeks[weekIndex].workouts.removeAt(oldIndex);
  program.weeks[weekIndex].workouts.insert(newIndex, workout);
  _updateWorkoutOrders(weekIndex, 0);
  notifyListeners();
}

void reorderExercises(int weekIndex, int workoutIndex, int oldIndex, int newIndex) {
  if (oldIndex < newIndex) {
    newIndex -= 1;
  }
  final exercise = program.weeks[weekIndex].workouts[workoutIndex].exercises.removeAt(oldIndex);
  program.weeks[weekIndex].workouts[workoutIndex].exercises.insert(newIndex, exercise);
  _updateExerciseOrders(weekIndex, workoutIndex, 0);
  notifyListeners();
}

void reorderSeries(int weekIndex, int workoutIndex, int exerciseIndex, int oldIndex, int newIndex) {
  if (oldIndex < newIndex) {
    newIndex -= 1;
  }
  final series = program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex].series.removeAt(oldIndex);
  program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex].series.insert(newIndex, series);
  _updateSeriesOrders(weekIndex, workoutIndex, exerciseIndex, 0);
  notifyListeners();
}

  void submitProgram(BuildContext context) {
    program.name = nameController.text;
    program.description = descriptionController.text;
    program.athleteId = athleteIdController.text;
    program.mesocycleNumber = int.tryParse(mesocycleNumberController.text) ?? 0;

    _service.addOrUpdateTrainingProgram(program).then((_) async {
      await _service.removeToDeleteItems(program);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Program added/updated successfully')),
      );
      // resetFields();
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding/updating program: $error')),
      );
    });
  }

  void resetFields() {
    program = TrainingProgram();
    nameController.clear();
    descriptionController.clear();
    athleteIdController.clear();
    mesocycleNumberController.clear();
    notifyListeners();
  }
}