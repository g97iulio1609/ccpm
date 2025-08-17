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
import '../domain/services/training_business_service.dart';
import '../infrastructure/repositories/firestore_training_repository.dart';
import 'series_controller.dart';
import 'super_set_controller.dart';
import 'package:alphanessone/providers/providers.dart';

final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(),
);

// Provider spostato in training_providers.dart come StateNotifierProvider

class TrainingProgramController extends StateNotifier<TrainingProgram> {
  final UsersService _usersService;
  final ExerciseRecordService _exerciseRecordService;
  final TrainingProgramStateNotifier _programStateNotifier;
  final TrainingProgram? _programState;

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
  late final TrainingBusinessService _trainingBusinessService;
  final Ref ref;
  bool _disposed = false;

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
      _superSetController = SuperSetController(),
      super(
        _programState ??
            TrainingProgram(
              id: '',
              name: '',
              description: '',
              athleteId: '',
              mesocycleNumber: 0,
              hide: false,
              status: '',
              weeks: [],
            ),
      ) {
    _initControllers();
    _trainingBusinessService = TrainingBusinessService(
      trainingRepository: FirestoreTrainingRepository(),
      exerciseRecordService: _exerciseRecordService,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _initControllers() {
    _nameController = TextEditingController(text: state.name);
    _descriptionController = TextEditingController(text: state.description);
    _athleteIdController = TextEditingController(text: state.athleteId);
    _mesocycleNumberController = TextEditingController(
      text: state.mesocycleNumber.toString(),
    );

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

  TrainingProgram get program => state;

  TextEditingController get nameController => _nameController;
  TextEditingController get descriptionController => _descriptionController;
  TextEditingController get athleteIdController => _athleteIdController;
  TextEditingController get mesocycleNumberController =>
      _mesocycleNumberController;
  SeriesController get seriesController => _seriesController;

  set athleteId(String value) {
    state = program.copyWith(athleteId: value);
    _athleteIdController.text = value;
    _emit();
  }

  Future<String> get athleteName async {
    if (program.athleteId.isNotEmpty) {
      final user = await _usersService.getUserById(program.athleteId);
      return user?.name ?? '';
    } else {
      return '';
    }
  }

  void _initProgram() {
    if (_programState == null) {
      state = TrainingProgram(
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
      state = _programState;
    }

    _nameController.text = state.name;
    _descriptionController.text = state.description;
    _athleteIdController.text = state.athleteId;
    _mesocycleNumberController.text = state.mesocycleNumber.toString();
  }

  void updateWeekProgressions(
    List<List<WeekProgression>> updatedProgressions,
    String exerciseId,
  ) {
    for (
      int weekIndex = 0;
      weekIndex < program.weeks.length &&
          weekIndex < updatedProgressions.length;
      weekIndex++
    ) {
      final week = program.weeks[weekIndex];
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

    _emit();
  }

  Future<void> loadProgram(String? programId) async {
    if (programId == null) {
      _initProgram();
      return;
    }

    try {
      final fetched = (await _trainingService.fetchTrainingProgram(programId))!;
      state = fetched;
      _updateProgram();
      _superSetController.loadSuperSets(program);

      final exercisesService = ref.read(exercisesServiceProvider);

      for (int weekIndex = 0; weekIndex < program.weeks.length; weekIndex++) {
        final week = program.weeks[weekIndex];
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

      _emit();
    } catch (error) {
      // Handle error
    }
  }

  void _updateProgram() {
    _nameController.text = program.name;
    _descriptionController.text = program.description;
    _athleteIdController.text = program.athleteId;
    _mesocycleNumberController.text = program.mesocycleNumber.toString();
    _programStateNotifier.updateProgram(program);
  }

  void updateHideProgram(bool value) {
    state = program.copyWith(hide: value);
    _programStateNotifier.updateProgram(program);
    _emit();
  }

  void updateProgramStatus(String status) {
    state = program.copyWith(status: status);
    _programStateNotifier.updateProgram(program);
    _emit();
  }

  Future<void> addWeek() async {
    _trainingBusinessService.addWeek(program);
    _emit();
  }

  void removeWeek(int index) {
    _trainingBusinessService.removeWeek(program, index);
    _emit();
  }

  void addWorkout(int weekIndex) {
    _trainingBusinessService.addWorkout(program, weekIndex);
    _emit();
  }

  void removeWorkout(int weekIndex, int workoutOrder) {
    // Converte order in index per business‑service
    final index = program.weeks[weekIndex].workouts.indexWhere(
      (w) => w.order == workoutOrder,
    );
    if (index != -1) {
      _trainingBusinessService.removeWorkout(program, weekIndex, index);
    }
    _emit();
  }

  Future<void> addExercise(
    int weekIndex,
    int workoutIndex,
    BuildContext context,
  ) async {
    await _exerciseController.addExercise(
      program,
      weekIndex,
      workoutIndex,
      context,
    );
    
    // Salva le modifiche nel database
    try {
      await _trainingService.addOrUpdateTrainingProgram(program);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nel salvare l\'esercizio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    _emit();
  }

  Future<void> editExercise(
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
    BuildContext context,
  ) async {
    await _exerciseController.editExercise(
      program,
      weekIndex,
      workoutIndex,
      exerciseIndex,
      context,
    );
    
    // Salva le modifiche nel database
    try {
      await _trainingService.addOrUpdateTrainingProgram(program);
    } catch (e) {}
    
    _emit();
  }

  Future<void> removeExercise(int weekIndex, int workoutIndex, int exerciseIndex) async {
    _trainingBusinessService.removeExercise(
      program,
      weekIndex,
      workoutIndex,
      exerciseIndex,
    );
    
    // Salva le modifiche nel database
    try {
      await _trainingService.addOrUpdateTrainingProgram(program);
    } catch (e) {}
    
    _emit();
  }

  Future<void> updateExercise(Exercise exercise) async {
    await _exerciseController.updateExerciseWeights(
      program,
      exercise.exerciseId!,
      exercise.type,
    );
    _emit();
  }

  void createSuperSet(int weekIndex, int workoutIndex) {
    _superSetController.createSuperSet(program, weekIndex, workoutIndex);
    _emit();
  }

  void addExerciseToSuperSet(
    int weekIndex,
    int workoutIndex,
    String superSetId,
    String exerciseId,
  ) {
    _superSetController.addExerciseToSuperSet(
      program,
      weekIndex,
      workoutIndex,
      superSetId,
      exerciseId,
    );
    _emit();
  }

  void removeExerciseFromSuperSet(
    int weekIndex,
    int workoutIndex,
    String superSetId,
    String exerciseId,
  ) {
    _superSetController.removeExerciseFromSuperSet(
      program,
      weekIndex,
      workoutIndex,
      superSetId,
      exerciseId,
    );
    _emit();
  }

  void removeSuperSet(int weekIndex, int workoutIndex, String superSetId) {
    _superSetController.removeSuperSet(
      program,
      weekIndex,
      workoutIndex,
      superSetId,
    );
    _emit();
  }

  Future<void> addSeries(
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
    String exerciseType,
    BuildContext context,
  ) async {
    await _seriesController.addSeries(
      program,
      weekIndex,
      workoutIndex,
      exerciseIndex,
      context,
    );
    _emit();
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
      program,
      weekIndex,
      workoutIndex,
      exerciseIndex,
      currentSeriesGroup,
      context,
      latestMaxWeight,
    );
    _emit();
  }

  Future<void> removeExercisesBulk(
    int weekIndex,
    int workoutIndex,
    List<String> exerciseIds,
    BuildContext context,
  ) async {
    if (exerciseIds.isEmpty) return;
    if (_disposed) return;
    final prog = program; // snapshot to avoid accessing state after dispose
    // Update in-memory state first for snappy UI
    _trainingBusinessService.removeExercisesBulkByIds(
      prog,
      weekIndex,
      workoutIndex,
      exerciseIds,
    );
    _emit();

    // Persist asynchronously with optimized batching
    try {
      await _trainingService.removeToDeleteItems(prog);
      await _trainingService.addOrUpdateTrainingProgram(prog);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eliminati ${exerciseIds.length} esercizi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore eliminando esercizi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void removeSeries(
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
    int groupIndex,
    int seriesIndex,
  ) {
    _seriesController.removeSeries(
      program,
      weekIndex,
      workoutIndex,
      exerciseIndex,
      groupIndex,
      seriesIndex,
    );
    _emit();
  }

  Future<void> copyWeek(int sourceWeekIndex, BuildContext context) async {
    await _trainingBusinessService.copyWeek(program, sourceWeekIndex, null);
    _emit();
  }

  void updateWeekNumber(int weekIndex, int newWeekNumber) {
    _trainingBusinessService.updateWeekNumber(program, weekIndex, newWeekNumber);
    _emit();
  }

  Future<void> copyWorkout(
    int sourceWeekIndex,
    int workoutIndex,
    BuildContext context,
  ) async {
    await _workoutController.copyWorkout(
      program,
      sourceWeekIndex,
      workoutIndex,
      context,
    );
    _emit();
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
    _emit();
  }

  void reorderWeeks(int oldIndex, int newIndex) {
    _weekController.reorderWeeks(program, oldIndex, newIndex);
    _emit();
  }

  void updateWeek(int weekIndex, Week updatedWeek) {
    _weekController.updateWeek(program, weekIndex, updatedWeek);
    _emit();
  }

  void reorderWorkouts(int weekIndex, int oldIndex, int newIndex) {
    _workoutController.reorderWorkouts(program, weekIndex, oldIndex, newIndex);
    _emit();
  }

  void reorderExercises(
    int weekIndex,
    int workoutIndex,
    int oldIndex,
    int newIndex,
  ) {
    _exerciseController.reorderExercises(
      program,
      weekIndex,
      workoutIndex,
      oldIndex,
      newIndex,
    );
    _emit();
  }

  Future<void> duplicateExercise(
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
  ) async {
    _exerciseController.duplicateExercise(
      program,
      weekIndex,
      workoutIndex,
      exerciseIndex,
    );
    _emit();
  }

  void moveExercise(
    int weekIndex,
    int sourceWorkoutIndex,
    int destinationWorkoutIndex,
    int exerciseIndex,
  ) {
    _exerciseController.moveExercise(
      program,
      weekIndex,
      sourceWorkoutIndex,
      destinationWorkoutIndex,
      exerciseIndex,
    );
    _emit();
  }

  void reorderSeries(
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
    int oldIndex,
    int newIndex,
  ) {
    _seriesController.reorderSeries(
      program,
      weekIndex,
      workoutIndex,
      exerciseIndex,
      oldIndex,
      newIndex,
    );
    _emit();
  }

  Future<void> submitProgram(BuildContext context) async {
    _updateProgramFields();

    try {
      await _trainingService.removeToDeleteItems(program);
      await _trainingService.addOrUpdateTrainingProgram(program);

      program.trackToDeleteSeries = [];
      program.trackToDeleteWeeks = [];
      program.trackToDeleteWorkouts = [];
      program.trackToDeleteExercises = [];

      await _usersService.updateUser(_athleteIdController.text, {
        'currentProgram': program.id,
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
    state = program.copyWith(
      name: _nameController.text,
      description: _descriptionController.text,
      athleteId: _athleteIdController.text,
      mesocycleNumber: int.tryParse(_mesocycleNumberController.text) ?? 0,
    );
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
    _emit();
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

  void _emit() {
    if (_disposed) return;
    // Forza un nuovo stato immutabile per notificare i listener
    state = state.copyWith();
    _programStateNotifier.updateProgram(state);
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

      // Use WeekUtils for consistent copying and proper reset of completion data
      newProgram.weeks = newProgram.weeks.asMap().entries.map<Week>((entry) {
        final weekIndex = entry.key;
        final week = entry.value;
        return WeekUtils.resetWeek(WeekUtils.duplicateWeek(week, newNumber: week.number));
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
