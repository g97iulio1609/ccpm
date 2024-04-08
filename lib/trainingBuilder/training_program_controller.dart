import 'package:alphanessone/trainingBuilder/exercise_dialog.dart';
import 'package:alphanessone/trainingBuilder/series_dialog.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'training_model.dart';
import 'training_services.dart';
import '../users_services.dart';
import 'utility_functions.dart';
import 'training_program_state_provider.dart';

final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

final trainingProgramControllerProvider = ChangeNotifierProvider((ref) {
  final service = ref.watch(firestoreServiceProvider);
  final usersService = ref.watch(usersServiceProvider);
  final programStateNotifier = ref.watch(trainingProgramStateProvider.notifier);
  return TrainingProgramController(service, usersService, programStateNotifier);
});

class TrainingProgramController extends ChangeNotifier {
  final FirestoreService _service;
  final UsersService _usersService;
  final TrainingProgramStateNotifier _programStateNotifier;

  TrainingProgramController(
      this._service, this._usersService, this._programStateNotifier) {
    _initProgram();
  }

  late TrainingProgram _program;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _athleteIdController;
  late TextEditingController _mesocycleNumberController;

  TrainingProgram get program => _programStateNotifier.state;
  TextEditingController get nameController => _nameController;
  TextEditingController get descriptionController => _descriptionController;
  TextEditingController get athleteIdController => _athleteIdController;
  TextEditingController get mesocycleNumberController =>
      _mesocycleNumberController;

  void _initProgram() {
    _program = _programStateNotifier.state;
    _nameController = TextEditingController(text: _program.name);
    _descriptionController = TextEditingController(text: _program.description);
    _athleteIdController = TextEditingController(text: _program.athleteId);
    _mesocycleNumberController =
        TextEditingController(text: _program.mesocycleNumber.toString());
  }

  Future<void> loadProgram(String? programId) async {
    if (programId == null) {
      _initProgram();
      return;
    }

    try {
      _program = await _service.fetchTrainingProgram(programId);
      _updateProgram();
    } catch (error) {
      // Handle error
    }
  }

  void _updateProgram() {
    _nameController.text = _program.name;
    _descriptionController.text = _program.description;
    _athleteIdController.text = _program.athleteId;
    _mesocycleNumberController.text = _program.mesocycleNumber.toString();
    _program.hide = _program.hide;
    _programStateNotifier.updateProgram(_program);
  }

  void updateHideProgram(bool value) {
    _program.hide = value;
    _programStateNotifier.updateProgram(_program);
    notifyListeners();
  }

  Future<void> addWeek() async {
    final newWeek = Week(
      id: UniqueKey().toString(),
      number: _program.weeks.length + 1,
      workouts: [
        Workout(
          id: '',
          order: 1,
          exercises: [],
        ),
      ],
    );

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
      order: _program.weeks[weekIndex].workouts.length + 1,
      exercises: [],
    );
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
      exercise.id = null;
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
      _updateExerciseWeights(changedExercise, newMaxWeight as double);
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

 void _updateExerciseWeights(Exercise exercise, double newMaxWeight) {
  final exerciseType = exercise.type ?? '';
  _updateSeriesWeights(exercise.series, newMaxWeight, exerciseType);
  _updateWeekProgressionWeights(exercise.weekProgressions, newMaxWeight, exerciseType);
}

 void _updateSeriesWeights(
      List<Series> series, double maxWeight, String exerciseType) {
    for (final item in series) {
      final intensity = double.tryParse(item.intensity) ?? 0;
      final calculatedWeight = calculateWeightFromIntensity(maxWeight, intensity);
      item.weight = roundWeight(calculatedWeight, exerciseType);
    }
  }


 void _updateWeekProgressionWeights(
      List<WeekProgression> progressions, double maxWeight, String exerciseType) {
    for (final item in progressions) {
      final intensity = double.tryParse(item.intensity) ?? 0;
      final calculatedWeight = calculateWeightFromIntensity(maxWeight, intensity);
      item.weight = roundWeight(calculatedWeight, exerciseType);
    }
  }

  Future<void> addSeries(int weekIndex, int workoutIndex, int exerciseIndex,
      BuildContext context) async {
    final exercise = _program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final seriesList = await _showSeriesDialog(context, exercise, weekIndex);
    if (seriesList != null) {
      for (final series in seriesList) {
        series.serieId = null;
      }
      exercise.series.addAll(seriesList);
      notifyListeners();
    }
  }

  Future<List<Series>?> _showSeriesDialog(
      BuildContext context, Exercise exercise, int weekIndex,
      [Series? currentSeries]) async {
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
    Series currentSeries,
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
    final exercise = _program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final series = exercise.series[groupIndex * 1 + seriesIndex];
    _removeSeriesData(series);
    exercise.series.removeAt(groupIndex * 1 + seriesIndex);
    _updateSeriesOrders(
        weekIndex, workoutIndex, exerciseIndex, groupIndex * 1 + seriesIndex);
    notifyListeners();
  }

  void _removeSeriesData(Series series) {
    if (series.serieId != null) {
      _program.trackToDeleteSeries.add(series.serieId!);
    }
  }

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

      notifyListeners();
    }
  }

  Week _copyWeek(Week sourceWeek) {
    final copiedWorkouts =
        sourceWeek.workouts.map((workout) => _copyWorkout(workout)).toList();

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
                child: Text(index < _program.weeks.length
                    ? 'Week ${_program.weeks[index].number}'
                    : 'New Week'),
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

  Future<void> copyWorkout(int sourceWeekIndex, int workoutIndex,
      BuildContext context) async {
    final destinationWeekIndex = await _showCopyWorkoutDialog(context);
    if (destinationWeekIndex != null) {
      final sourceWorkout =
          _program.weeks[sourceWeekIndex].workouts[workoutIndex];
      final copiedWorkout = _copyWorkout(sourceWorkout);

      if (destinationWeekIndex < _program.weeks.length) {
        final destinationWeek = _program.weeks[destinationWeekIndex];
        final existingWorkoutIndex = destinationWeek.workouts.indexWhere(
          (workout) => workout.order == sourceWorkout.order,
        );

        if (existingWorkoutIndex != -1) {
          final existingWorkout =
              destinationWeek.workouts[existingWorkoutIndex];
          if (existingWorkout.id != null) {
            _program.trackToDeleteWorkouts.add(existingWorkout.id!);
          }
          destinationWeek.workouts[existingWorkoutIndex] = copiedWorkout;
        } else {
          destinationWeek.workouts.add(copiedWorkout);
        }
      } else {
        while (_program.weeks.length <= destinationWeekIndex) {
          addWeek();
        }
        _program.weeks[destinationWeekIndex].workouts.add(copiedWorkout);
      }

      notifyListeners();
    }
  }

  Workout _copyWorkout(Workout sourceWorkout) {
    final copiedExercises = sourceWorkout.exercises
        .map((exercise) => _copyExercise(exercise))
        .toList();

    return Workout(
      id: null,
      order: sourceWorkout.order,
      exercises: copiedExercises,
    );
  }

  Exercise _copyExercise(Exercise sourceExercise) {
    final copiedSeries =
        sourceExercise.series.map((series) => _copySeries(series)).toList();

    return sourceExercise.copyWith(
      id: UniqueKey().toString(),
      exerciseId: sourceExercise.exerciseId,
      series: copiedSeries,
    );
  }

  Series _copySeries(Series sourceSeries) {
    return sourceSeries.copyWith(
      serieId: UniqueKey().toString(),
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

  void updateSeries(int weekIndex, int workoutIndex, int exerciseIndex,
      List<Series> updatedSeries) {
    _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex]
        .series = updatedSeries;
    notifyListeners();
  }

  Future<void> applyWeekProgressions(int exerciseIndex,
      List<WeekProgression> weekProgressions, BuildContext context) async {
    for (int weekIndex = 0; weekIndex < _program.weeks.length; weekIndex++) {
      final week = _program.weeks[weekIndex];

      for (int workoutIndex = 0;
          workoutIndex < week.workouts.length;
          workoutIndex++) {
        final workout = week.workouts[workoutIndex];

        for (int currentExerciseIndex = 0;
            currentExerciseIndex < workout.exercises.length;
            currentExerciseIndex++) {
          final exercise = workout.exercises[currentExerciseIndex];

          if (currentExerciseIndex == exerciseIndex) {
            final progression = weekIndex < weekProgressions.length
                ? weekProgressions[weekIndex]
                : weekProgressions.last;

            await _updateOrCreateSeries(exercise, progression, weekIndex,
                workoutIndex, currentExerciseIndex, context);
            _updateWeekProgression(
                weekIndex, workoutIndex, currentExerciseIndex, progression);
          }
        }
      }
    }

    notifyListeners();
  }

  Future<void> _updateOrCreateSeries(
      Exercise exercise,
      WeekProgression progression,
      int weekIndex,
      int workoutIndex,
      int exerciseIndex,
      BuildContext context) async {
    final existingSeries = exercise.series
        .where((series) => series.order ~/ 100 == weekIndex)
        .toList();

    await _adjustSeriesCount(existingSeries, progression.sets, weekIndex,
        workoutIndex, exerciseIndex, context);

    for (int i = 0; i < progression.sets; i++) {
      final series = existingSeries[i];
      series.reps = progression.reps;
      series.intensity = progression.intensity;
      series.rpe = progression.rpe;
      series.weight = progression.weight;
    }

    notifyListeners();
  }

  Future<void> _adjustSeriesCount(
      List<Series> existingSeries,
      int newSeriesCount,
      int weekIndex,
      int workoutIndex,
      int exerciseIndex,
      BuildContext context) async {
    if (existingSeries.length < newSeriesCount) {
      for (int i = existingSeries.length; i < newSeriesCount; i++) {
        await addSeries(weekIndex, workoutIndex, exerciseIndex, context);
      }
    } else if (existingSeries.length > newSeriesCount) {
      for (int i = newSeriesCount; i < existingSeries.length; i++) {
        final seriesIndex = existingSeries[i].order % 100 - 1;
        removeSeries(weekIndex, workoutIndex, exerciseIndex, 0, seriesIndex);
      }
    }
  }

  void _updateWeekProgression(int weekIndex, int workoutIndex,
      int exerciseIndex, WeekProgression progression) {
    final exercise =
        _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];

    if (exercise.weekProgressions.length <= weekIndex) {
      exercise.weekProgressions.add(progression);
    } else {
      exercise.weekProgressions[weekIndex] = progression;
    }
  }

  Future<void> addSeriesToProgression(int weekIndex, int workoutIndex,
      int exerciseIndex, BuildContext context) async {
    final exercise = _program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final newSeriesOrder = exercise.series.length + 1;
    final newSeries = Series(
      serieId: UniqueKey().toString(),
      reps: 0,
      sets: 1,
      intensity: '',
      rpe: '',
      weight: 0.0,
      order: newSeriesOrder,
      done: false,
      reps_done: 0,
      weight_done: 0.0,
    );
    exercise.series.add(newSeries);
    notifyListeners();
  }

  Future<void> updateExerciseProgressions(Exercise exercise,
      List<WeekProgression> updatedProgressions, BuildContext context) async {
    for (int weekIndex = 0; weekIndex < _program.weeks.length; weekIndex++) {
      final week = _program.weeks[weekIndex];

      for (int workoutIndex = 0;
          workoutIndex < week.workouts.length;
          workoutIndex++) {
        final workout = week.workouts[workoutIndex];

        final exerciseIndex =
            workout.exercises.indexWhere((e) => e.id == exercise.id);
        if (exerciseIndex != -1) {
          final currentExercise = workout.exercises[exerciseIndex];
          currentExercise.weekProgressions = updatedProgressions;

          final progression = weekIndex < updatedProgressions.length
              ? updatedProgressions[weekIndex]
              : updatedProgressions.last;

          currentExercise.series.clear();

          await Future.forEach<int>(
              List.generate(progression.sets, (index) => index), (index) async {
            await addSeriesToProgression(
                weekIndex, workoutIndex, exerciseIndex, context);
            final latestSeries = currentExercise.series[index];
            latestSeries.reps = progression.reps;
            latestSeries.intensity = progression.intensity;
            latestSeries.rpe = progression.rpe;
            latestSeries.weight = progression.weight;
          });
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

  void updateWeek(int weekIndex, Week updatedWeek) {
    _program.weeks[weekIndex] = updatedWeek;
    _programStateNotifier.updateProgram(_program);
    notifyListeners();
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

  void reorderExercises(
      int weekIndex, int workoutIndex, int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final exercise =
        _program.weeks[weekIndex].workouts[workoutIndex].exercises.removeAt(oldIndex);
    _program.weeks[weekIndex].workouts[workoutIndex].exercises.insert(newIndex, exercise);
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
    _updateProgramFields();

    try {
      await _service.addOrUpdateTrainingProgram(_program);
      await _service.removeToDeleteItems(_program);
      await _usersService.updateUser(
          _athleteIdController.text, {'currentProgram': _program.id});

      _showSuccessSnackBar(context, 'Program added/updated successfully');
    } catch (error) {
      _showErrorSnackBar(context, 'Error adding/updating program: $error');
    }
  }

  void _updateProgramFields() {
    _program.name = _nameController.text;
    _program.description = _descriptionController.text;
    _program.athleteId = _athleteIdController.text;
    _program.mesocycleNumber =
        int.tryParse(_mesocycleNumberController.text) ?? 0;
    _program.hide = _program.hide;
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void resetFields() {
    _initProgram();
    notifyListeners();
  }
}
