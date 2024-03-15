// trainingController.dart
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
    if (week.id != null) {
      program.trackToDeleteWeeks.add(week.id!);
    }
    program.weeks.removeAt(index);

    // Remove all child workouts, exercises, and series
    for (var workout in week.workouts) {
      if (workout.id != null) {
        program.trackToDeleteWorkouts.add(workout.id!);
      }
      for (var exercise in workout.exercises) {
        if (exercise.id != null) {
          program.trackToDeleteExercises.add(exercise.id!);
        }
        for (var series in exercise.series) {
          if (series.serieId != null) {
            program.trackToDeleteSeries.add(series.serieId!);
          }
        }
      }
    }

    notifyListeners();
  }

  void addWorkout(int weekIndex) {
    Workout newWorkout = Workout(order: program.weeks[weekIndex].workouts.length + 1, exercises: []);
    program.weeks[weekIndex].workouts.add(newWorkout);
    notifyListeners();
  }

  void removeWorkout(int weekIndex, int workoutIndex) {
    Workout workout = program.weeks[weekIndex].workouts[workoutIndex];
    if (workout.id != null) {
      program.trackToDeleteWorkouts.add(workout.id!);
    }
    program.weeks[weekIndex].workouts.removeAt(workoutIndex);

    // Remove all child exercises and series
    for (var exercise in workout.exercises) {
      if (exercise.id != null) {
        program.trackToDeleteExercises.add(exercise.id!);
      }
      for (var series in exercise.series) {
        if (series.serieId != null) {
          program.trackToDeleteSeries.add(series.serieId!);
        }
      }
    }

    notifyListeners();
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
      // Genera un ID temporaneo per l'esercizio
      exercise.id = UniqueKey().toString();
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
      program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex] = updatedExercise;
      notifyListeners();
    }
  }

  void removeExercise(int weekIndex, int workoutIndex, int exerciseIndex) {
    Exercise exercise = program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    if (exercise.id != null) {
      program.trackToDeleteExercises.add(exercise.id!);
    }
    program.weeks[weekIndex].workouts[workoutIndex].exercises.removeAt(exerciseIndex);

    // Remove all child series
    for (var series in exercise.series) {
      if (series.serieId != null) {
        program.trackToDeleteSeries.add(series.serieId!);
      }
    }

    notifyListeners();
  }

Future<void> addSeries(int weekIndex, int workoutIndex, int exerciseIndex, BuildContext context) async {
  final exercise = program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
  final seriesList = await showDialog<List<Series>>(
    context: context,
    builder: (context) => SeriesDialog(
      usersService: _usersService,
      athleteId: athleteIdController.text,
      exerciseId: exercise.exerciseId ?? '',
    ),
  );
  if (seriesList != null) {
    print('Debug: Series received from SeriesDialog: ${seriesList.length}');
    exercise.series.addAll(seriesList);
    notifyListeners();
  }
}

Future<void> editSeries(int weekIndex, int workoutIndex, int exerciseIndex, int seriesIndex, BuildContext context) async {
  final series = program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex].series[seriesIndex];
  final exercise = program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
  print('Debug: exerciseId passed from editSeries: ${exercise.exerciseId}');

  final updatedSeriesList = await showDialog<List<Series>>(
    context: context,
    builder: (context) => SeriesDialog(
      usersService: _usersService,
      athleteId: athleteIdController.text,
      exerciseId: exercise.exerciseId ?? '',
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
    if (series.serieId != null) {
      program.trackToDeleteSeries.add(series.serieId!);
    }
    program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex].series.removeAt(seriesIndex);
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