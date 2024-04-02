import 'package:alphanessone/trainingBuilder/exercise_dialog.dart';
import 'package:alphanessone/trainingBuilder/series_dialog.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'training_model.dart';
import 'training_services.dart';
import '../users_services.dart';
import 'utility_functions.dart';

final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

final trainingProgramControllerProvider = ChangeNotifierProvider((ref) {
  final service = ref.watch(firestoreServiceProvider);
  final usersService = ref.watch(usersServiceProvider);
  return TrainingProgramController(service, usersService);
});

class TrainingProgramController extends ChangeNotifier {
  final FirestoreService _service;
  final UsersService _usersService;

  TrainingProgramController(this._service, this._usersService);

  late TrainingProgram _program;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _athleteIdController;
  late TextEditingController _athleteNameController;
  late TextEditingController _mesocycleNumberController;

  TrainingProgram get program => _program;
  TextEditingController get nameController => _nameController;
  TextEditingController get descriptionController => _descriptionController;
  TextEditingController get athleteIdController => _athleteIdController;
  TextEditingController get athleteNameController => _athleteNameController;
  TextEditingController get mesocycleNumberController =>
      _mesocycleNumberController;

  void _initProgram() {
    debugPrint('Initializing program...');
    _program = TrainingProgram();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _athleteIdController = TextEditingController();
    _athleteNameController = TextEditingController();
    _mesocycleNumberController = TextEditingController();
    debugPrint('Program initialized.');
  }

  Future<void> loadProgram(String? programId) async {
    debugPrint('Loading program with ID: $programId');
    _initProgram();
    if (programId == null) {
      debugPrint('No program ID provided. Initialization only.');
      return;
    }

    try {
      _program = await _service.fetchTrainingProgram(programId);
      _nameController.text = _program.name;
      _descriptionController.text = _program.description;
      _athleteIdController.text = _program.athleteId;
      _mesocycleNumberController.text = _program.mesocycleNumber.toString();
      _program.hide = _program.hide;

      debugPrint('Program loaded successfully. Name: ${_program.name}, Description: ${_program.description}');

      _rebuildWeekProgressions();
      notifyListeners();
    } catch (error) {
      debugPrint('Error loading program: $error');
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
    final newWorkout = Workout(
        order: _program.weeks[weekIndex].workouts.length + 1, exercises: []);
    _program.weeks[weekIndex].workouts.add(newWorkout);
    notifyListeners();
  }

  void removeWorkout(int weekIndex, int workoutOrder) {
    final workoutIndex = workoutOrder - 1;
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

Future<void> addExercise(
    int weekIndex, int workoutIndex, BuildContext context) async {
  final exercise = await _showExerciseDialog(context, null);
  if (exercise != null) {
    exercise.id = null; // Lasciamo che Firestore generi l'ID dell'esercizio
    exercise.order =
        _program.weeks[weekIndex].workouts[workoutIndex].exercises.length + 1;
    _program.weeks[weekIndex].workouts[workoutIndex].exercises.add(exercise);
    notifyListeners();
  }
}

  Future<Exercise?> _showExerciseDialog(
      BuildContext context, Exercise? exercise) async {
    return await showDialog<Exercise>(
      context: context,
      builder: (context) => ExerciseDialog(
        usersService: _usersService,
        athleteId: _athleteIdController.text,
        exercise: exercise,
      ),
    );
  }

  Future<void> editExercise(int weekIndex, int workoutIndex, int exerciseIndex,
      BuildContext context) async {
    final exercise = _program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final updatedExercise = await _showExerciseDialog(context, exercise);
    if (updatedExercise != null) {
      updatedExercise.order = exercise.order;
      _program.weeks[weekIndex].workouts[workoutIndex]
          .exercises[exerciseIndex] = updatedExercise;
      await updateExercise(updatedExercise.exerciseId ?? '');
    }
  }

  void removeExercise(int weekIndex, int workoutIndex, int exerciseIndex) {
    final exercise = _program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    _removeExerciseAndRelatedData(exercise);
    _program.weeks[weekIndex].workouts[workoutIndex].exercises
        .removeAt(exerciseIndex);
    _updateExerciseOrders(weekIndex, workoutIndex, exerciseIndex);
    notifyListeners();
  }

  void _removeExerciseAndRelatedData(Exercise exercise) {
    if (exercise.id != null) {
      _program.trackToDeleteExercises.add(exercise.id!);
    }
    exercise.series.forEach(_removeSeriesData);
  }

  Future<void> updateExercise(String exerciseId) async {
    await _onExerciseChanged(exerciseId);
    notifyListeners();
  }

  Future<void> _onExerciseChanged(String exerciseId) async {
    Exercise? changedExercise = _findExerciseById(exerciseId);

    if (changedExercise != null) {
      final newMaxWeight = await getLatestMaxWeight(
          _usersService, _athleteIdController.text, exerciseId);
      _updateExerciseSeries(changedExercise, newMaxWeight as double);
      _updateExerciseWeekProgressions(changedExercise, newMaxWeight as double);
    }
  }

  Exercise? _findExerciseById(String exerciseId) {
    for (final week in _program.weeks) {
      for (final workout in week.workouts) {
        for (final exercise in workout.exercises) {
          if (exercise.exerciseId == exerciseId) {
            return exercise;
          }
        }
      }
    }
    return null;
  }

  void _updateExerciseSeries(Exercise exercise, double newMaxWeight) {
    for (final series in exercise.series) {
      final intensity = double.tryParse(series.intensity) ?? 0;
      final calculatedWeight =
          calculateWeightFromIntensity(newMaxWeight, intensity);
      final roundedWeight = roundWeight(calculatedWeight, exercise.type);
      series.weight = roundedWeight;
    }
  }

  void _updateExerciseWeekProgressions(Exercise exercise, double newMaxWeight) {
    for (final progression in exercise.weekProgressions) {
      final intensity = double.tryParse(progression.intensity) ?? 0;
      final calculatedWeight =
          calculateWeightFromIntensity(newMaxWeight, intensity);
      final roundedWeight = roundWeight(calculatedWeight, exercise.type);
      progression.weight = roundedWeight;
    }
  }

Future<void> addSeries(int weekIndex, int workoutIndex, int exerciseIndex,
    BuildContext context) async {
  final exercise = _program
      .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
  final seriesList = await _showSeriesDialog(context, exercise, weekIndex);
  if (seriesList != null) {
    for (final series in seriesList) {
      series.serieId = null; // Lasciamo che Firestore generi l'ID della serie
    }
    exercise.series.addAll(seriesList);
    notifyListeners();
  }
}

  Future<List<Series>?> _showSeriesDialog(BuildContext context, Exercise exercise, int weekIndex, [Series? currentSeries]) async {
    return await showDialog<List<Series>>(
      context: context,
      builder: (context) => SeriesDialog(
        usersService: _usersService,
        athleteId: _athleteIdController.text,
        exerciseId: exercise.exerciseId ?? '',
        weekIndex: weekIndex,
        exercise: exercise,
        currentSeries: currentSeries,
      ),
    );
  }

  Future<void> editSeries(
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
    Series currentSeries, // Accetta l'oggetto Series corrente
    BuildContext context,
  ) async {
    final exercise = _program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final updatedSeriesList =
        await _showSeriesDialog(context, exercise, weekIndex, currentSeries);
    if (updatedSeriesList != null) {
      final groupIndex = exercise.series.indexWhere(
        (series) => series.serieId == currentSeries.serieId,
      );
      final seriesIndex = exercise.series.indexOf(currentSeries);
      _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex]
          .series
          .replaceRange(seriesIndex, seriesIndex + 1, updatedSeriesList);
      notifyListeners();
    }
  }

  void removeSeries(
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
    int groupIndex,
    int seriesIndex,
  ) {
    final exercise = _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final series = exercise.series[groupIndex * 1 + seriesIndex];

    // Aggiungi la serie all'elenco delle serie da eliminare
    if (series.serieId != null) {
      _program.trackToDeleteSeries.add(series.serieId!);
      debugPrint('Aggiunta la serie ${series.serieId} alla lista trackToDeleteSeries');
    } else {
      debugPrint('La serie non ha un ID valido');
    }

    exercise.series.removeAt(groupIndex * 1 + seriesIndex);
    _updateSeriesOrders(weekIndex, workoutIndex, exerciseIndex, groupIndex * 1 + seriesIndex);
    notifyListeners();
  }

  void _removeSeriesData(Series series) {
    if (series.serieId != null) {
      _program.trackToDeleteSeries.add(series.serieId!);
    }
  }


//COPY
Future<void> copyWeek(int sourceWeekIndex, BuildContext context) async {
  final destinationWeekIndex = await _showCopyWeekDialog(context);
  if (destinationWeekIndex != null) {
    final sourceWeek = _program.weeks[sourceWeekIndex];
    final copiedWeek = _copyWeek(sourceWeek);

    if (destinationWeekIndex < _program.weeks.length) {
      final destinationWeek = _program.weeks[destinationWeekIndex];
      _program.trackToDeleteWeeks.add(destinationWeek.id!);
      _program.weeks[destinationWeekIndex] = copiedWeek;
    } else {
      copiedWeek.number = _program.weeks.length + 1;
      _program.weeks.add(copiedWeek);
    }

    debugPrint('Copied week from index $sourceWeekIndex to index $destinationWeekIndex');
    debugPrint('Copied week: $copiedWeek');

    notifyListeners();
  }
}

Week _copyWeek(Week sourceWeek) {
  final copiedWorkouts = sourceWeek.workouts.map((workout) => _copyWorkout(workout)).toList();

  return Week(
    id: null,
    number: sourceWeek.number,
    workouts: copiedWorkouts,
  );
}

Future<int?> _showCopyWeekDialog(BuildContext context) async {
  return showDialog<int>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Copy Week'),
        content: DropdownButtonFormField<int>(
          value: null,
          items: List.generate(
            _program.weeks.length + 1,
            (index) => DropdownMenuItem(
              value: index,
              child: Text(index < _program.weeks.length ? 'Week ${_program.weeks[index].number}' : 'New Week'),
            ),
          ),
          onChanged: (value) {
            Navigator.pop(context, value);
          },
          decoration: const InputDecoration(
            labelText: 'Destination Week',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );
}

Future<void> copyWorkout(int sourceWeekIndex, int workoutIndex, BuildContext context) async {
  final destinationWeekIndex = await _showCopyWorkoutDialog(context);
  if (destinationWeekIndex != null) {
    final sourceWorkout = _program.weeks[sourceWeekIndex].workouts[workoutIndex];
    final copiedWorkout = _copyWorkout(sourceWorkout);

    if (destinationWeekIndex < _program.weeks.length) {
      final destinationWeek = _program.weeks[destinationWeekIndex];
      final existingWorkoutIndex = destinationWeek.workouts.indexWhere(
        (workout) => workout.order == sourceWorkout.order,
      );

      if (existingWorkoutIndex != -1) {
        // Se il workout esiste, aggiungi il workout esistente a trackToDeleteWorkouts
        final existingWorkout = destinationWeek.workouts[existingWorkoutIndex];
        if (existingWorkout.id != null) {
          _program.trackToDeleteWorkouts.add(existingWorkout.id!);
        }
        // Sovrascrivi l'allenamento esistente
        destinationWeek.workouts[existingWorkoutIndex] = copiedWorkout;
      } else {
        // Aggiungi il nuovo allenamento
        destinationWeek.workouts.add(copiedWorkout);
      }
    } else {
      while (_program.weeks.length <= destinationWeekIndex) {
        addWeek();
      }
      _program.weeks[destinationWeekIndex].workouts.add(copiedWorkout);
    }

    debugPrint('Copied workout from week $sourceWeekIndex to week $destinationWeekIndex');
    debugPrint('Copied workout: $copiedWorkout');

    notifyListeners();
  }
}

Workout _copyWorkout(Workout sourceWorkout) {
  final copiedExercises = sourceWorkout.exercises.map((exercise) => _copyExercise(exercise)).toList();

  return Workout(
    id: null, // Lasciamo che Firestore generi l'ID del workout
    order: sourceWorkout.order,
    exercises: copiedExercises,
  );
}

Exercise _copyExercise(Exercise sourceExercise) {
  final newExerciseId = UniqueKey().toString();
  final copiedSeries = sourceExercise.series.map((series) => _copySeries(series)).toList();

  return sourceExercise.copyWith(
    id: newExerciseId,
    exerciseId: sourceExercise.exerciseId,
    series: copiedSeries,
  );
}

Series _copySeries(Series sourceSeries) {
  final newSeriesId = UniqueKey().toString();
  return sourceSeries.copyWith(
    serieId: newSeriesId,
    done: false,
    reps_done: 0,
    weight_done: 0.0,
  );
}

Future<int?> _showCopyWorkoutDialog(BuildContext context) async {
  return showDialog<int>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Copy Workout'),
        content: DropdownButtonFormField<int>(
          value: null,
          items: List.generate(
            _program.weeks.length,
            (index) => DropdownMenuItem(
              value: index,
              child: Text('Week ${index + 1}'),
            ),
          ),
          onChanged: (value) {
            Navigator.pop(context, value);
          },
          decoration: const InputDecoration(
            labelText: 'Destination Week',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );
}

//REORDER


  //PROGRESSION

  void updateWeekProgression(int weekIndex, int workoutIndex, int exerciseIndex,
      WeekProgression weekProgression) {
    _createWeekProgressionIfNotExists(weekIndex, workoutIndex, exerciseIndex);
    _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex]
        .weekProgressions[weekProgression.weekNumber - 1] = weekProgression;
    notifyListeners();
  }

  void _createWeekProgressionIfNotExists(
      int weekIndex, int workoutIndex, int exerciseIndex) {
    final exercise = _program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
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

  void updateSeries(int weekIndex, int workoutIndex, int exerciseIndex,
      List<Series> updatedSeries) {
    _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex]
        .series = updatedSeries;
    notifyListeners();
  }

Future<void> applyWeekProgressions(int exerciseIndex, List<WeekProgression> weekProgressions) async {
  debugPrint('Applying week progressions for exercise index: $exerciseIndex');
  debugPrint('Week progressions: $weekProgressions');

  for (int weekIndex = 0; weekIndex < _program.weeks.length; weekIndex++) {
    final week = _program.weeks[weekIndex];
    debugPrint('Processing week: $weekIndex');

    for (final workout in week.workouts) {
      debugPrint('Processing workout: ${workout.order}');

      for (int currentExerciseIndex = 0; currentExerciseIndex < workout.exercises.length; currentExerciseIndex++) {
        final exercise = workout.exercises[currentExerciseIndex];
        debugPrint('Processing exercise: ${exercise.name} (index: $currentExerciseIndex)');

        if (currentExerciseIndex == exerciseIndex) {
          WeekProgression progression;
          if (weekIndex < weekProgressions.length) {
            progression = weekProgressions[weekIndex];
            debugPrint('Using provided progression for week $weekIndex: $progression');
          } else {
            final previousWeekProgression = weekProgressions.last;
            progression = WeekProgression(
              weekNumber: weekIndex + 1,
              reps: previousWeekProgression.reps,
              sets: previousWeekProgression.sets,
              intensity: previousWeekProgression.intensity,
              rpe: previousWeekProgression.rpe,
              weight: previousWeekProgression.weight,
            );
            debugPrint('Using previous week progression for week $weekIndex: $progression');
          }

          await _updateOrCreateSeries(exercise, progression, weekIndex);
          _updateWeekProgression(weekIndex, workout.order - 1, currentExerciseIndex, progression);
        }
      }
    }
  }

  notifyListeners();
}

  WeekProgression _getProgressionFromSeries(
      List<Series> series, int weekIndex) {
    if (weekIndex < series.length) {
      final currentSeries = series[weekIndex];

      return WeekProgression(
        weekNumber: weekIndex + 1,
        reps: currentSeries.reps,
        sets: currentSeries.sets,
        intensity: currentSeries.intensity,
        rpe: currentSeries.rpe,
        weight: currentSeries.weight,
      );
    } else {
      return WeekProgression(
        weekNumber: weekIndex + 1,
        reps: 0,
        sets: 0,
        intensity: '',
        rpe: '',
        weight: 0.0,
      );
    }
  }

  void _updateWeekProgression(int weekIndex, int workoutIndex,
      int exerciseIndex, WeekProgression progression) {
    _createWeekProgressionIfNotExists(weekIndex, workoutIndex, exerciseIndex);
    _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex]
        .weekProgressions[weekIndex] = progression;
  }
Future<void> _updateOrCreateSeries(Exercise exercise, WeekProgression progression, int weekIndex) async {
  debugPrint('Updating or creating series for exercise: ${exercise.name}, week: $weekIndex');
  debugPrint('Progression: $progression');

  final newSeriesCount = progression.sets;

  // Rimuovi le serie esistenti per la settimana specifica
  exercise.series.removeWhere((series) => series.order ~/ 100 == weekIndex);

  final newSeries = <Series>[];
  for (int i = 0; i < newSeriesCount; i++) {
    final serieId = '${exercise.id}_${weekIndex}_$i';
    final series = Series(
      serieId: serieId,
      reps: progression.reps,
      sets: 1,
      intensity: progression.intensity,
      rpe: progression.rpe,
      weight: progression.weight,
      order: weekIndex * 100 + i + 1,
      done: false,
      reps_done: 0,
      weight_done: 0.0,
    );
    newSeries.add(series);
    debugPrint('Added new series: $series');
    debugPrint('Reps: ${series.reps}, Weight: ${series.weight}, Sets: ${series.sets}, Intensity: ${series.intensity}, RPE: ${series.rpe}');
  }

  // Aggiungi le nuove serie all'elenco delle serie dell'esercizio
  exercise.series.addAll(newSeries);

  debugPrint('Updated series for exercise ${exercise.name}: ${exercise.series}');
  notifyListeners();
}

  List<Series> _createSeriesFromProgression(
      WeekProgression progression, Exercise exercise) {
    final seriesList = <Series>[];
    for (int i = 0; i < progression.sets; i++) {
      final serieId = '${exercise.id}_$i';
      final series = Series(
        serieId: serieId,
        reps: progression.reps,
        sets: 1,
        intensity: progression.intensity,
        rpe: progression.rpe,
        weight: progression.weight,
        order: i + 1,
        done: false,
        reps_done: 0,
        weight_done: 0.0,
      );
      seriesList.add(series);
    }
    return seriesList;
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
    return WeekProgression(
      weekNumber: weekIndex + 1,
      reps: 0,
      sets: 0,
      intensity: '',
      rpe: '',
      weight: 0.0,
    );
  }

  void _rebuildWeekProgressions() {
    for (final week in _program.weeks) {
      final weekIndex = _program.weeks.indexOf(week);

      for (final workout in week.workouts) {
        for (final exercise in workout.exercises) {
          _rebuildExerciseProgressions(exercise);
        }
      }
    }

    notifyListeners();
  }

  void _rebuildExerciseProgressions(Exercise exercise) {
    final weekProgressions = List<WeekProgression>.generate(
      _program.weeks.length,
      (weekIndex) {
        final weekProgression =
            _getProgressionFromSeries(exercise.series, weekIndex);
        return weekProgression;
      },
    );

    exercise.weekProgressions = weekProgressions;
  }

Future<void> updateExerciseProgressions(Exercise exercise, List<WeekProgression> updatedProgressions) async {
  for (int weekIndex = 0; weekIndex < _program.weeks.length; weekIndex++) {
    final week = _program.weeks[weekIndex];
    for (final workout in week.workouts) {
      for (final currentExercise in workout.exercises) {
        if (currentExercise.id == exercise.id) {
          currentExercise.weekProgressions = updatedProgressions;
          if (weekIndex < updatedProgressions.length) {
            await _updateOrCreateSeries(currentExercise, updatedProgressions[weekIndex], weekIndex);
          }
        }
      }
    }
  }
  notifyListeners();
}

  //REORDER FUNCTIONS
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

  void reorderSeries(int weekIndex, int workoutIndex, int exerciseIndex,
      int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final exercise = _program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final series = exercise.series.removeAt(oldIndex);
    exercise.series.insert(newIndex, series);
    _updateSeriesOrders(weekIndex, workoutIndex, exerciseIndex, newIndex);
    notifyListeners();
  }

  void _updateSeriesOrders(
      int weekIndex, int workoutIndex, int exerciseIndex, int startIndex) {
    final exercise = _program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    for (int i = startIndex; i < exercise.series.length; i++) {
      exercise.series[i].order = i + 1;
    }
  }

  Future<void> submitProgram(BuildContext context) async {
    _program.name = _nameController.text;
    _program.description = _descriptionController.text;
    _program.athleteId = _athleteIdController.text;
    _program.mesocycleNumber = int.tryParse(_mesocycleNumberController.text) ?? 0;
    _program.hide = _program.hide;

    try {
      await _service.addOrUpdateTrainingProgram(_program);
      await _service.removeToDeleteItems(_program);
      await _usersService.updateUser(_athleteIdController.text, {'currentProgram': _program.id});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Program added/updated successfully')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding/updating program: $error')),
      );
    }
  }

  void resetFields() {
    _initProgram();
    notifyListeners();
  }
}
