import 'package:alphanessone/shared/shared.dart';
import 'package:alphanessone/trainingBuilder/providers/training_providers.dart';
import 'package:alphanessone/trainingBuilder/utility_functions.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/training_services.dart';
import 'package:alphanessone/ExerciseRecords/exercise_record_services.dart';
import 'package:alphanessone/services/users_services.dart';
import 'week_controller.dart';
import 'workout_controller.dart';
import 'exercise_controller.dart';
import '../domain/services/exercise_business_service.dart';
import 'series_controller.dart';
import 'super_set_controller.dart';
import 'package:alphanessone/providers/providers.dart';

final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(),
);

final trainingProgramControllerProvider =
    ChangeNotifierProvider<TrainingProgramController>((ref) {
      final service = ref.watch(firestoreServiceProvider);
      final usersService = ref.watch(usersServiceProvider);
      final exerciseRecordService = ref.watch(exerciseRecordServiceProvider);
      final programStateNotifier = ref.watch(
        trainingProgramStateProvider.notifier,
      );
      final programState = ref.watch(trainingProgramStateProvider);
      return TrainingProgramController(
        service,
        usersService,
        exerciseRecordService,
        programStateNotifier,
        programState,
        ref,
      );
    });

class TrainingProgramController extends ChangeNotifier {
  final UsersService _usersService;
  final ExerciseRecordService _exerciseRecordService;
  final TrainingProgramStateNotifier _programStateNotifier;
  final TrainingProgram? _programState;

  late TrainingProgram _program;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _athleteIdController;
  late TextEditingController _mesocycleNumberController;

  final TrainingProgramService _trainingService;
  final WeekController _weekController;
  final WorkoutController _workoutController;
  late final SeriesController _seriesController;
  late final ExerciseControllerRefactored _exerciseController;
  final SuperSetController _superSetController;
  final Ref ref;

  TrainingProgramController(
    FirestoreService service,
    this._usersService,
    this._exerciseRecordService,
    this._programStateNotifier,
    this._programState,
    this.ref,
  ) : _trainingService = TrainingProgramService(service),
      _weekController = WeekController(),
      _workoutController = WorkoutController(),
      _superSetController = SuperSetController() {
    _initProgram();
    final weightNotifier = ValueNotifier<double>(0.0);
    _seriesController = SeriesController(
      _exerciseRecordService,
      weightNotifier,
    );
    _exerciseController = ExerciseControllerRefactored(
      businessService: ExerciseBusinessService(
        exerciseRecordService: _exerciseRecordService,
      ),
    );
  }

  TrainingProgram get program => _program;

  TextEditingController get nameController => _nameController;
  TextEditingController get descriptionController => _descriptionController;
  TextEditingController get athleteIdController => _athleteIdController;
  TextEditingController get mesocycleNumberController =>
      _mesocycleNumberController;
  SeriesController get seriesController => _seriesController;

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

  void _initProgram() {
    if (_programState == null) {
      _program = TrainingProgram(
        id: '',
        name: '',
        description: '',
        athleteId: '',
        mesocycleNumber: 0,
        hide: false,
        status: '',
        weeks: [],
      );
    } else {
      _program = _programState;
    }

    _nameController = TextEditingController(text: _program.name);
    _descriptionController = TextEditingController(text: _program.description);
    _athleteIdController = TextEditingController(text: _program.athleteId);
    _mesocycleNumberController = TextEditingController(
      text: _program.mesocycleNumber.toString(),
    );
  }

  void updateWeekProgressions(
    List<List<WeekProgression>> updatedProgressions,
    String exerciseId,
  ) {
    for (
      int weekIndex = 0;
      weekIndex < _program.weeks.length &&
          weekIndex < updatedProgressions.length;
      weekIndex++
    ) {
      final week = _program.weeks[weekIndex];
      for (
        int workoutIndex = 0;
        workoutIndex < week.workouts.length &&
            workoutIndex < updatedProgressions[weekIndex].length;
        workoutIndex++
      ) {
        final workout = week.workouts[workoutIndex];
        final exerciseIndex = workout.exercises.indexWhere(
          (e) => e.exerciseId == exerciseId,
        );

        if (exerciseIndex != -1) {
          final exercise = workout.exercises[exerciseIndex];

          for (final series in exercise.series) {
            if (!program.trackToDeleteSeries.contains(series.serieId ?? '')) {
              program.trackToDeleteSeries.add(series.serieId ?? '');
            }
          }

          // Create updated series with the new progressions
          final updatedSeries = updatedProgressions[weekIndex][workoutIndex]
              .series
              .map(
                (s) => Series(
                  serieId: s.serieId,
                  exerciseId: s.exerciseId,
                  reps: s.reps,
                  maxReps: s.maxReps, // This will be null if it was cleared
                  sets: s.sets,
                  intensity: s.intensity,
                  maxIntensity: s
                      .maxIntensity, // This will be null or empty if it was cleared
                  rpe: s.rpe,
                  maxRpe:
                      s.maxRpe, // This will be null or empty if it was cleared
                  weight: s.weight,
                  maxWeight: s.maxWeight, // This will be null if it was cleared
                  order: s.order,
                  done: s.done,
                  repsDone: s.repsDone,
                  weightDone: s.weightDone,
                ),
              )
              .toList();

          // Initialize weekProgressions if null
          var currentProgressions =
              exercise.weekProgressions ?? <List<WeekProgression>>[];

          // Ensure we have enough weeks
          while (currentProgressions.length <= weekIndex) {
            currentProgressions.add(<WeekProgression>[]);
          }

          // Initialize week progression if empty
          if (currentProgressions[weekIndex].isEmpty) {
            currentProgressions[weekIndex] = [
              WeekProgression(
                weekNumber: weekIndex + 1,
                sessionNumber: workoutIndex + 1,
                series: [],
              ),
            ];
          }

          // Update the progression
          currentProgressions[weekIndex][0] =
              updatedProgressions[weekIndex][workoutIndex];

          // Create new exercise instance with updated progressions and series
          final updatedExercise = exercise.copyWith(
            weekProgressions: currentProgressions,
            series: updatedSeries,
          );

          // Replace the exercise in the workout
          workout.exercises[exerciseIndex] = updatedExercise;
        }
      }
    }

    notifyListeners();
  }

  Future<void> loadProgram(String? programId) async {
    if (programId == null) {
      _initProgram();
      return;
    }

    try {
      _program = (await _trainingService.fetchTrainingProgram(programId))!;
      _updateProgram();
      _superSetController.loadSuperSets(_program);

      final exercisesService = ref.read(exercisesServiceProvider);

      for (int weekIndex = 0; weekIndex < _program.weeks.length; weekIndex++) {
        final week = _program.weeks[weekIndex];
        for (
          int workoutIndex = 0;
          workoutIndex < week.workouts.length;
          workoutIndex++
        ) {
          final workout = week.workouts[workoutIndex];
          for (
            int exerciseIndex = 0;
            exerciseIndex < workout.exercises.length;
            exerciseIndex++
          ) {
            final exercise = workout.exercises[exerciseIndex];
            final exerciseModel = await exercisesService.getExerciseById(
              exercise.exerciseId ?? '',
            );
            if (exerciseModel != null) {
              final updatedExercise = exercise.copyWith(
                type: exerciseModel.type,
              );
              workout.exercises[exerciseIndex] = updatedExercise;
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
    _program.status = _program.status;

    _programStateNotifier.updateProgram(_program);
  }

  void updateHideProgram(bool value) {
    _program.hide = value;
    _programStateNotifier.updateProgram(_program);
    notifyListeners();
  }

  void updateProgramStatus(String status) {
    _program.status = status;
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
    int weekIndex,
    int workoutIndex,
    BuildContext context,
  ) async {
    await _exerciseController.addExercise(
      _program,
      weekIndex,
      workoutIndex,
      context,
    );
    notifyListeners();
  }

  Future<void> editExercise(
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
    BuildContext context,
  ) async {
    await _exerciseController.editExercise(
      _program,
      weekIndex,
      workoutIndex,
      exerciseIndex,
      context,
    );
    notifyListeners();
  }

  void removeExercise(int weekIndex, int workoutIndex, int exerciseIndex) {
    _exerciseController.removeExercise(
      _program,
      weekIndex,
      workoutIndex,
      exerciseIndex,
    );
    notifyListeners();
  }

  Future<void> updateExercise(Exercise exercise) async {
    await _exerciseController.updateExerciseWeights(
      program,
      exercise.exerciseId!,
      exercise.type,
    );
    notifyListeners();
  }

  void createSuperSet(int weekIndex, int workoutIndex) {
    _superSetController.createSuperSet(_program, weekIndex, workoutIndex);
    notifyListeners();
  }

  void addExerciseToSuperSet(
    int weekIndex,
    int workoutIndex,
    String superSetId,
    String exerciseId,
  ) {
    _superSetController.addExerciseToSuperSet(
      _program,
      weekIndex,
      workoutIndex,
      superSetId,
      exerciseId,
    );
    notifyListeners();
  }

  void removeExerciseFromSuperSet(
    int weekIndex,
    int workoutIndex,
    String superSetId,
    String exerciseId,
  ) {
    _superSetController.removeExerciseFromSuperSet(
      _program,
      weekIndex,
      workoutIndex,
      superSetId,
      exerciseId,
    );
    notifyListeners();
  }

  void removeSuperSet(int weekIndex, int workoutIndex, String superSetId) {
    _superSetController.removeSuperSet(
      _program,
      weekIndex,
      workoutIndex,
      superSetId,
    );
    notifyListeners();
  }

  Future<void> addSeries(
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
    String exerciseType,
    BuildContext context,
  ) async {
    await _seriesController.addSeries(
      _program,
      weekIndex,
      workoutIndex,
      exerciseIndex,
      context,
    );
    notifyListeners();
  }

  Future<void> editSeries(
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
    List<Series> currentSeriesGroup,
    BuildContext context,
    String exerciseType,
    num latestMaxWeight,
  ) async {
    await _seriesController.editSeries(
      _program,
      weekIndex,
      workoutIndex,
      exerciseIndex,
      currentSeriesGroup,
      context,
      latestMaxWeight,
    );
    notifyListeners();
  }

  void removeSeries(
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
    int groupIndex,
    int seriesIndex,
  ) {
    _seriesController.removeSeries(
      _program,
      weekIndex,
      workoutIndex,
      exerciseIndex,
      groupIndex,
      seriesIndex,
    );
    notifyListeners();
  }

  Future<void> copyWeek(int sourceWeekIndex, BuildContext context) async {
    await _weekController.copyWeek(_program, sourceWeekIndex, context);
    notifyListeners();
  }

  Future<void> copyWorkout(
    int sourceWeekIndex,
    int workoutIndex,
    BuildContext context,
  ) async {
    await _workoutController.copyWorkout(
      _program,
      sourceWeekIndex,
      workoutIndex,
      context,
    );
    notifyListeners();
  }

  void updateSeries(
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
    List<Series> updatedSeries,
  ) {
    final exercise = program
        .weeks[weekIndex]
        .workouts[workoutIndex]
        .exercises[exerciseIndex];
    final updatedExercise = exercise.copyWith(series: updatedSeries);
    program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex] =
        updatedExercise;
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
    int weekIndex,
    int workoutIndex,
    int oldIndex,
    int newIndex,
  ) {
    _exerciseController.reorderExercises(
      _program,
      weekIndex,
      workoutIndex,
      oldIndex,
      newIndex,
    );
    notifyListeners();
  }

  Future<void> duplicateExercise(
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
  ) async {
    _exerciseController.duplicateExercise(
      _program,
      weekIndex,
      workoutIndex,
      exerciseIndex,
    );
    notifyListeners();
  }

  void moveExercise(
    int weekIndex,
    int sourceWorkoutIndex,
    int destinationWorkoutIndex,
    int exerciseIndex,
  ) {
    _exerciseController.moveExercise(
      _program,
      weekIndex,
      sourceWorkoutIndex,
      destinationWorkoutIndex,
      exerciseIndex,
    );
    notifyListeners();
  }

  void reorderSeries(
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
    int oldIndex,
    int newIndex,
  ) {
    _seriesController.reorderSeries(
      _program,
      weekIndex,
      workoutIndex,
      exerciseIndex,
      oldIndex,
      newIndex,
    );
    notifyListeners();
  }

  Future<void> submitProgram(BuildContext context) async {
    _updateProgramFields();

    try {
      await _trainingService.removeToDeleteItems(_program);
      await _trainingService.addOrUpdateTrainingProgram(_program);

      _program.trackToDeleteSeries = [];

      await _usersService.updateUser(_athleteIdController.text, {
        'currentProgram': _program.id,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Program added/updated successfully')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding/updating program: $error')),
        );
      }
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

  void _showSuccessSnackBar(
    ScaffoldMessengerState scaffoldMessenger,
    String message,
  ) {
    scaffoldMessenger.showSnackBar(SnackBar(content: Text(message)));
  }

  void _showErrorSnackBar(
    ScaffoldMessengerState scaffoldMessenger,
    String message,
  ) {
    scaffoldMessenger.showSnackBar(SnackBar(content: Text(message)));
  }

  void resetFields() {
    _initProgram();
    notifyListeners();
  }

  Future<void> updateProgramWeights(TrainingProgram program) async {
    for (final week in program.weeks) {
      for (final workout in week.workouts) {
        for (final exercise in workout.exercises) {
          await _exerciseController.updateSingleProgramExercise(
            program,
            exercise.exerciseId!,
            exercise.type,
          );
        }
      }
    }
  }

  Future<String?> duplicateProgram(
    String programId,
    String newProgramName,
    BuildContext context, {
    String? currentUserId,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      TrainingProgram? existingProgram = await _trainingService
          .fetchTrainingProgram(programId);

      if (existingProgram == null) {
        _showErrorSnackBar(
          scaffoldMessenger,
          'Programma esistente non trovato',
        );
        return null;
      }

      TrainingProgram newProgram = existingProgram.copyWith(
        id: generateRandomId(16).toString(),
        name: newProgramName,
        athleteId: currentUserId ?? existingProgram.athleteId,
      );

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
                      repsDone: 0,
                      weightDone: 0.0,
                      done: false,
                    );
                  }).toList(),
                );
              }).toList(),
              superSets: workout.superSets?.map<Map<String, dynamic>>((
                superSet,
              ) {
                return {
                  'id': generateRandomId(16).toString(),
                  'name': superSet['name'] ?? '',
                  'exerciseIds': List<String>.from(
                    superSet['exerciseIds'] ?? [],
                  ),
                };
              }).toList(),
            );
          }).toList(),
        );
      }).toList();

      final exercisesService = ref.read(exercisesServiceProvider);

      for (
        int weekIndex = 0;
        weekIndex < newProgram.weeks.length;
        weekIndex++
      ) {
        final week = newProgram.weeks[weekIndex];
        for (
          int workoutIndex = 0;
          workoutIndex < week.workouts.length;
          workoutIndex++
        ) {
          final workout = week.workouts[workoutIndex];
          for (
            int exerciseIndex = 0;
            exerciseIndex < workout.exercises.length;
            exerciseIndex++
          ) {
            final exercise = workout.exercises[exerciseIndex];
            final exerciseModel = await exercisesService.getExerciseById(
              exercise.exerciseId ?? '',
            );
            if (exerciseModel != null) {
              final updatedExercise = exercise.copyWith(
                type: exerciseModel.type,
              );
              workout.exercises[exerciseIndex] = updatedExercise;
            }

            await _exerciseController.updateSingleProgramExercise(
              newProgram,
              exercise.exerciseId!,
              exercise.type,
            );
          }
        }
      }

      await _trainingService.addOrUpdateTrainingProgram(newProgram);

      _showSuccessSnackBar(
        scaffoldMessenger,
        'Programma duplicato con successo',
      );

      return newProgram.id;
    } catch (error) {
      _showErrorSnackBar(
        scaffoldMessenger,
        'Errore durante la duplicazione del programma: $error',
      );
      return null;
    }
  }
}
