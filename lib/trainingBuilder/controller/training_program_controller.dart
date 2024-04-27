import 'package:alphanessone/exerciseManager/exercises_services.dart';
import 'package:alphanessone/trainingBuilder/utility_functions.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../training_model.dart';
import '../training_services.dart';
import 'package:alphanessone/users_services.dart' as user_services;
import '../training_program_state_provider.dart';
import 'training_program_repository.dart';
import 'week_controller.dart';
import 'workout_controller.dart';
import 'exercise_controller.dart';
import 'series_controller.dart';
import 'super_set_controller.dart';
import 'progression_controller.dart';

final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

final trainingProgramControllerProvider =
    ChangeNotifierProvider<TrainingProgramController>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  final usersService = ref.watch(user_services.usersServiceProvider);
  final programStateNotifier = ref.watch(trainingProgramStateProvider.notifier);
  return TrainingProgramController(service, usersService, programStateNotifier, ref);
});

class TrainingProgramController extends ChangeNotifier {
  final FirestoreService _service;
  final user_services.UsersService _usersService;
  final TrainingProgramStateNotifier _programStateNotifier;
  static int superSetCounter = 0;

  set athleteId(String value) {
    _program.athleteId = value;
    _athleteIdController.text = value;
    notifyListeners();
  }

  Future<String> get athleteName async {
    if (_program.athleteId.isNotEmpty) {
      final user = await _usersService.getUserById(_program.athleteId);
      return user?.name ?? '';
    } else {
      return '';
    }
  }

  final TrainingProgramRepository _repository;
  final WeekController _weekController;
  final WorkoutController _workoutController;
  late final SeriesController _seriesController;
  late final ExerciseController _exerciseController;
  final SuperSetController _superSetController;
  final Ref ref;

  TrainingProgramController(
    this._service,
    this._usersService,
    this._programStateNotifier,
    this.ref,
  )   : _repository = TrainingProgramRepository(_service),
        _weekController = WeekController(),
        _workoutController = WorkoutController(),
        _superSetController = SuperSetController() {
    _initProgram();
    final weightNotifier = ValueNotifier<double>(0.0);
    _seriesController = SeriesController(_usersService, weightNotifier);
    _exerciseController = ExerciseController(_usersService, _seriesController);
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
      _program = await _repository.fetchTrainingProgram(programId);
      _updateProgram();
      _superSetController.loadSuperSets(_program);

      // Itera su tutti gli esercizi e "seleziona" automaticamente l'esercizio corrispondente
      final exercisesService = ref.read(exercisesServiceProvider);

      for (final week in _program.weeks) {
        for (final workout in week.workouts) {
          for (final exercise in workout.exercises) {
            final exerciseModel = await exercisesService
                .getExerciseById(exercise.exerciseId ?? '');
            if (exerciseModel != null) {
              exercise.type = exerciseModel.type;
            }
          }
        }
      }

      notifyListeners();
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
    _weekController.addWeek(_program);
    notifyListeners();
  }

  void removeWeek(int index) {
    _weekController.removeWeek(_program, index);
    notifyListeners();
  }

  void addWorkout(int weekIndex) {
    _workoutController.addWorkout(_program, weekIndex);
    notifyListeners();
  }

  void removeWorkout(int weekIndex, int workoutOrder) {
    _workoutController.removeWorkout(_program, weekIndex, workoutOrder);
    notifyListeners();
  }

  Future<void> addExercise(
      int weekIndex, int workoutIndex, BuildContext context) async {
    await _exerciseController.addExercise(
        _program, weekIndex, workoutIndex, context);
    notifyListeners();
  }

  Future<void> editExercise(int weekIndex, int workoutIndex, int exerciseIndex,
      BuildContext context) async {
    await _exerciseController.editExercise(
        _program, weekIndex, workoutIndex, exerciseIndex, context);
    notifyListeners();
  }

  void removeExercise(int weekIndex, int workoutIndex, int exerciseIndex) {
    _exerciseController.removeExercise(
        _program, weekIndex, workoutIndex, exerciseIndex);
    notifyListeners();
  }

Future<void> updateExercise(Exercise exercise) async {
  await _exerciseController.updateExercise(program, exercise.exerciseId!, exercise.type!);
  notifyListeners();
}

  void createSuperSet(int weekIndex, int workoutIndex) {
    _superSetController.createSuperSet(_program, weekIndex, workoutIndex);
    notifyListeners();
  }

  void addExerciseToSuperSet(
      int weekIndex, int workoutIndex, String superSetId, String exerciseId) {
    _superSetController.addExerciseToSuperSet(
        _program, weekIndex, workoutIndex, superSetId, exerciseId);
    notifyListeners();
  }

  void removeExerciseFromSuperSet(
      int weekIndex, int workoutIndex, String superSetId, String exerciseId) {
    _superSetController.removeExerciseFromSuperSet(
        _program, weekIndex, workoutIndex, superSetId, exerciseId);
    notifyListeners();
  }

  void removeSuperSet(int weekIndex, int workoutIndex, String superSetId) {
    _superSetController.removeSuperSet(
        _program, weekIndex, workoutIndex, superSetId);
    notifyListeners();
  }

  Future<void> addSeries(int weekIndex, int workoutIndex, int exerciseIndex,
      String exerciseType, BuildContext context) async {
    await _seriesController.addSeries(_program, weekIndex, workoutIndex,
        exerciseIndex,  context);
    notifyListeners();
  }

  Future<void> editSeries(int weekIndex, int workoutIndex, int exerciseIndex,
      Series currentSeries, BuildContext context, String exerciseType) async {
    await _seriesController.editSeries(_program, weekIndex, workoutIndex,
        exerciseIndex, currentSeries, context);
    notifyListeners();
  }

  void removeSeries(
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
    int groupIndex,
    int seriesIndex,
  ) {
    _seriesController.removeSeries(_program, weekIndex, workoutIndex,
        exerciseIndex, groupIndex, seriesIndex);
    notifyListeners();
  }

  Future<void> copyWeek(int sourceWeekIndex, BuildContext context) async {
    await _weekController.copyWeek(_program, sourceWeekIndex, context);
    notifyListeners();
  }

  Future<void> copyWorkout(
      int sourceWeekIndex, int workoutIndex, BuildContext context) async {
    await _workoutController.copyWorkout(
        _program, sourceWeekIndex, workoutIndex, context);
    notifyListeners();
  }

  void updateSeries(int weekIndex, int workoutIndex, int exerciseIndex,
      List<Series> updatedSeries) {
    _seriesController.updateSeries(
        _program, weekIndex, workoutIndex, exerciseIndex, updatedSeries);
    notifyListeners();
  }

  Future<void> applyWeekProgressions(int exerciseIndex,
      List<WeekProgression> weekProgressions, BuildContext context) async {
    final exercise = _program.weeks
        .expand((week) => week.workouts)
        .expand((workout) => workout.exercises)
        .elementAt(exerciseIndex);

    for (int weekIndex = 0; weekIndex < _program.weeks.length; weekIndex++) {
      final progression = weekIndex < weekProgressions.length
          ? weekProgressions[weekIndex]
          : weekProgressions.last;
      final series = List.generate(
          progression.sets,
          (index) => Series(
                serieId: generateRandomId(16).toString(),
                reps: progression.reps,
                sets: 1,
                intensity: progression.intensity,
                rpe: progression.rpe,
                weight: progression.weight,
                order: index + 1,
                done: false,
                reps_done: 0,
                weight_done: 0.0,
              ));

      for (var workout in _program.weeks[weekIndex].workouts) {
        final exerciseIndex =
            workout.exercises.indexWhere((e) => e.id == exercise.id);
        if (exerciseIndex != -1) {
          workout.exercises[exerciseIndex] =
              workout.exercises[exerciseIndex].copyWith(series: series);
        }
      }
    }

    notifyListeners();
  }

  Future<void> updateExerciseProgressions(Exercise exercise,
      List<WeekProgression> updatedProgressions, BuildContext context) async {
    final progressionController = ProgressionController(this);
    await progressionController.updateExerciseProgressions(
        exercise, updatedProgressions, context);
    notifyListeners();
  }

  void reorderWeeks(int oldIndex, int newIndex) {
    _weekController.reorderWeeks(_program, oldIndex, newIndex);
    notifyListeners();
  }

  void updateWeek(int weekIndex, Week updatedWeek) {
    _weekController.updateWeek(_program, weekIndex, updatedWeek);
    notifyListeners();
  }

  void reorderWorkouts(int weekIndex, int oldIndex, int newIndex) {
    _workoutController.reorderWorkouts(_program, weekIndex, oldIndex, newIndex);
    notifyListeners();
  }

  void reorderExercises(
      int weekIndex, int workoutIndex, int oldIndex, int newIndex) {
    _exerciseController.reorderExercises(
        _program, weekIndex, workoutIndex, oldIndex, newIndex);
    notifyListeners();
  }

  void reorderSeries(int weekIndex, int workoutIndex, int exerciseIndex,
      int oldIndex, int newIndex) {
    _seriesController.reorderSeries(
        _program, weekIndex, workoutIndex, exerciseIndex, oldIndex, newIndex);
    notifyListeners();
  }

  Future<void> submitProgram(BuildContext context) async {
    _updateProgramFields();

    try {
      await _repository.addOrUpdateTrainingProgram(_program);
      await _repository.removeToDeleteItems(_program);
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

  Future<void> duplicateProgram(
      String programId, String newProgramName, BuildContext context) async {
    try {
      // Fetch the existing program
      TrainingProgram? existingProgram =
          await _repository.fetchTrainingProgram(programId);


      // Create a new program with the new name and copy the existing program data
      TrainingProgram newProgram = existingProgram.copyWith(
        id: generateRandomId(16).toString(),
        name: newProgramName,
      );


      // Generate new IDs for weeks, workouts, exercises, series, and supersets
      newProgram.weeks = newProgram.weeks.map((week) {
        return week.copyWith(
          id: generateRandomId(16).toString(),
          workouts: week.workouts.map((workout) {
            return workout.copyWith(
              id: generateRandomId(16).toString(),
              exercises: workout.exercises.map((exercise) {
                return exercise.copyWith(
                  id: generateRandomId(16).toString(),
                  series: exercise.series.map((series) {
                    return series.copyWith(
                      serieId: generateRandomId(16).toString(),
                      reps_done: 0,
                      weight_done: 0.0,
                      done: false,
                    );
                  }).toList(),
                );
              }).toList(),
              superSets: workout.superSets.map((superSet) {
                return SuperSet(
                  id: generateRandomId(16).toString(),
                  name: superSet.name,
                  exerciseIds: superSet.exerciseIds,
                );
              }).toList(),
            );
          }).toList(),
        );
      }).toList();


      // Save the new program
      await _repository.addOrUpdateTrainingProgram(newProgram);

      // Show a success message
      _showSuccessSnackBar(context, 'Programma duplicato con successo');
    } catch (error) {
      _showErrorSnackBar(
          context, 'Errore durante la duplicazione del programma: $error');
    }
  }
}
