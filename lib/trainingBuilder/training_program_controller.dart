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
      exercise.id = UniqueKey().toString();
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

  void applyWeekProgressions(
      int exerciseIndex, List<WeekProgression> weekProgressions) {
    for (int weekIndex = 0; weekIndex < _program.weeks.length; weekIndex++) {
      final week = _program.weeks[weekIndex];
      for (final workout in week.workouts) {
        for (int currentExerciseIndex = 0;
            currentExerciseIndex < workout.exercises.length;
            currentExerciseIndex++) {
          final exercise = workout.exercises[currentExerciseIndex];
          if (currentExerciseIndex == exerciseIndex) {
            final progression = weekIndex < weekProgressions.length
                ? weekProgressions[weekIndex]
                : _getProgressionFromSeries(exercise.series, weekIndex);
            _updateOrCreateSeries(exercise, progression, weekIndex);
            _updateWeekProgression(weekIndex, workout.order - 1,
                currentExerciseIndex, progression);
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

  void _updateOrCreateSeries(
      Exercise exercise, WeekProgression progression, int weekIndex) {
    final newSeriesCount = progression.sets;
    final existingSeriesCount = exercise.series.length;

    for (int i = 0; i < newSeriesCount; i++) {
      if (i < existingSeriesCount) {
        final existingSeries = exercise.series[i];
        exercise.series[i] = existingSeries.copyWith(
          reps: progression.reps,
          sets: 1,
          intensity: progression.intensity,
          rpe: progression.rpe,
          weight: progression.weight,
        );
      } else {
        final newSeries = Series(
          serieId: '${exercise.id}_${weekIndex}_$i',
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
        exercise.series.add(newSeries);
      }
    }

    // Rimuovi le serie in eccesso
    if (existingSeriesCount > newSeriesCount) {
      exercise.series.removeRange(newSeriesCount, existingSeriesCount);
    }
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

  void updateExerciseProgressions(
      Exercise exercise, List<WeekProgression> updatedProgressions) {
    for (int weekIndex = 0; weekIndex < _program.weeks.length; weekIndex++) {
      final week = _program.weeks[weekIndex];
      for (final workout in week.workouts) {
        for (final currentExercise in workout.exercises) {
          if (currentExercise.id == exercise.id) {
            currentExercise.weekProgressions = updatedProgressions;
            if (weekIndex < updatedProgressions.length) {
              _updateOrCreateSeries(
                  currentExercise, updatedProgressions[weekIndex], weekIndex);
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
    for (int i = startIndex;
        i < _program.weeks[weekIndex].workouts.length;
        i++) {
      _program.weeks[weekIndex].workouts[i].order = i + 1;
    }
  }

  void reorderExercises(
      int weekIndex, int workoutIndex, int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final exercise = _program.weeks[weekIndex].workouts[workoutIndex].exercises
        .removeAt(oldIndex);
    _program.weeks[weekIndex].workouts[workoutIndex].exercises
        .insert(newIndex, exercise);
    _updateExerciseOrders(weekIndex, workoutIndex, newIndex);
    notifyListeners();
  }

  void _updateExerciseOrders(int weekIndex, int workoutIndex, int startIndex) {
    for (int i = startIndex;
        i < _program.weeks[weekIndex].workouts[workoutIndex].exercises.length;
        i++) {
      _program.weeks[weekIndex].workouts[workoutIndex].exercises[i].order =
          i + 1;
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
