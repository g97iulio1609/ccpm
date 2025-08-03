import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/training_model.dart';
import '../models/exercise_model.dart';
import '../models/series_model.dart';
import '../models/week_model.dart';
import '../domain/services/training_business_service.dart';
import '../shared/utils/validation_utils.dart';
import '../../services/users_services.dart';

/// Refactored TrainingProgramController following SOLID principles
/// Focused on presentation logic only, delegates business logic to service
class TrainingProgramControllerRefactored extends ChangeNotifier {
  final TrainingBusinessService _businessService;
  final UsersService _usersService;

  TrainingProgram? _program;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _athleteIdController;
  late final TextEditingController _mesocycleNumberController;

  // State management for UI
  bool _isLoading = false;
  String? _errorMessage;

  TrainingProgramControllerRefactored({
    required TrainingBusinessService businessService,
    required UsersService usersService,
    TrainingProgram? initialProgram,
  })  : _businessService = businessService,
        _usersService = usersService {
    _initializeProgram(initialProgram);
  }

  // Getters
  TrainingProgram? get program => _program;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasProgram => _program != null;

  TextEditingController get nameController => _nameController;
  TextEditingController get descriptionController => _descriptionController;
  TextEditingController get athleteIdController => _athleteIdController;
  TextEditingController get mesocycleNumberController =>
      _mesocycleNumberController;

  /// Initialize program with default or provided values
  void _initializeProgram(TrainingProgram? initialProgram) {
    _program = initialProgram ??
        TrainingProgram(
          id: '',
          name: '',
          description: '',
          athleteId: '',
          mesocycleNumber: 1,
          hide: false,
          status: 'private',
          weeks: [],
        );

    _initializeControllers();
  }

  /// Initialize text controllers
  void _initializeControllers() {
    _nameController = TextEditingController(text: _program?.name ?? '');
    _descriptionController =
        TextEditingController(text: _program?.description ?? '');
    _athleteIdController =
        TextEditingController(text: _program?.athleteId ?? '');
    _mesocycleNumberController = TextEditingController(
      text: _program?.mesocycleNumber.toString() ?? '1',
    );
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Update program and notify listeners
  void _updateProgram() {
    if (_program != null) {
      _program!.name = _nameController.text;
      _program!.description = _descriptionController.text;
      _program!.athleteId = _athleteIdController.text;
      _program!.mesocycleNumber =
          int.tryParse(_mesocycleNumberController.text) ?? 1;
    }
    notifyListeners();
  }

  // Program Operations

  /// Load program by ID
  Future<void> loadProgram(String? programId) async {
    if (programId == null) {
      _initializeProgram(null);
      return;
    }

    _setLoading(true);
    _setError(null);

    try {
      // This would be implemented by the business service
      // _program = await _businessService.loadProgram(programId);
      _initializeControllers();
      notifyListeners();
    } catch (e) {
      _setError('Errore nel caricamento del programma: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Save current program
  Future<void> saveProgram() async {
    if (_program == null) {
      _setError('Nessun programma da salvare');
      return;
    }

    _setLoading(true);
    _setError(null);

    try {
      _updateProgram();

      if (!ValidationUtils.isValidTrainingProgram(_program!)) {
        throw ArgumentError('Dati del programma non validi');
      }

      await _businessService.saveTrainingProgram(_program!);

      // Update user's current program
      await _usersService.updateUser(
        _program!.athleteId,
        {'currentProgram': _program!.id},
      );
    } catch (e) {
      _setError('Errore nel salvataggio: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Week Operations

  /// Add a new week
  void addWeek() {
    if (_program == null) return;

    try {
      _businessService.addWeek(_program!);
      notifyListeners();
    } catch (e) {
      _setError('Errore nell\'aggiunta della settimana: $e');
    }
  }

  /// Remove a week
  void removeWeek(int weekIndex) {
    if (_program == null) return;

    try {
      _businessService.removeWeek(_program!, weekIndex);
      notifyListeners();
    } catch (e) {
      _setError('Errore nella rimozione della settimana: $e');
    }
  }

  /// Copy a week
  Future<void> copyWeek(int sourceWeekIndex, int? destinationWeekIndex) async {
    if (_program == null) return;

    try {
      await _businessService.copyWeek(
          _program!, sourceWeekIndex, destinationWeekIndex);
      notifyListeners();
    } catch (e) {
      _setError('Errore nella copia della settimana: $e');
    }
  }

  // Workout Operations

  /// Add a workout to a week
  void addWorkout(int weekIndex) {
    if (_program == null) return;

    try {
      _businessService.addWorkout(_program!, weekIndex);
      notifyListeners();
    } catch (e) {
      _setError('Errore nell\'aggiunta dell\'allenamento: $e');
    }
  }

  /// Remove a workout from a week
  void removeWorkout(int weekIndex, int workoutIndex) {
    if (_program == null) return;

    try {
      _businessService.removeWorkout(_program!, weekIndex, workoutIndex);
      notifyListeners();
    } catch (e) {
      _setError('Errore nella rimozione dell\'allenamento: $e');
    }
  }

  /// Copy a workout
  Future<void> copyWorkout(
      int sourceWeekIndex, int workoutIndex, int? destinationWeekIndex) async {
    if (_program == null) return;

    try {
      await _businessService.copyWorkout(
          _program!, sourceWeekIndex, workoutIndex, destinationWeekIndex);
      notifyListeners();
    } catch (e) {
      _setError('Errore nella copia dell\'allenamento: $e');
    }
  }

  // Exercise Operations

  /// Add an exercise to a workout
  void addExercise(int weekIndex, int workoutIndex, Exercise exercise) {
    if (_program == null) return;

    try {
      _businessService.addExercise(
          _program!, weekIndex, workoutIndex, exercise);
      notifyListeners();
    } catch (e) {
      _setError('Errore nell\'aggiunta dell\'esercizio: $e');
    }
  }

  /// Remove an exercise from a workout
  void removeExercise(int weekIndex, int workoutIndex, int exerciseIndex) {
    if (_program == null) return;

    try {
      _businessService.removeExercise(
          _program!, weekIndex, workoutIndex, exerciseIndex);
      notifyListeners();
    } catch (e) {
      _setError('Errore nella rimozione dell\'esercizio: $e');
    }
  }

  /// Duplicate an exercise
  void duplicateExercise(int weekIndex, int workoutIndex, int exerciseIndex) {
    if (_program == null) return;

    try {
      _businessService.duplicateExercise(
          _program!, weekIndex, workoutIndex, exerciseIndex);
      notifyListeners();
    } catch (e) {
      _setError('Errore nella duplicazione dell\'esercizio: $e');
    }
  }

  /// Update exercise weights
  Future<void> updateExerciseWeights(
      String exerciseId, String exerciseType) async {
    if (_program == null) return;

    try {
      await _businessService.updateExerciseWeights(
          _program!, exerciseId, exerciseType);
      notifyListeners();
    } catch (e) {
      _setError('Errore nell\'aggiornamento dei pesi: $e');
    }
  }

  // Utility Methods

  /// Get athlete name
  Future<String> getAthleteName() async {
    if (_program?.athleteId.isEmpty ?? true) return '';

    try {
      final user = await _usersService.getUserById(_program!.athleteId);
      return user?.name ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Update program visibility
  void updateProgramVisibility(bool hide) {
    if (_program == null) return;

    _program!.hide = hide;
    notifyListeners();
  }

  /// Update program status
  void updateProgramStatus(String status) {
    if (_program == null) return;

    _program!.status = status;
    notifyListeners();
  }

  /// Reset program to default state
  void resetProgram() {
    _initializeProgram(null);
    _setError(null);
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _setError(null);
  }

  /// Reorder weeks
  void reorderWeeks(int oldIndex, int newIndex) {
    if (_program == null ||
        !ValidationUtils.isValidProgramIndex(_program!, oldIndex)) {
      return;
    }

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final week = _program!.weeks.removeAt(oldIndex);
    _program!.weeks.insert(newIndex, week);

    // Update week numbers
    for (int i = 0; i < _program!.weeks.length; i++) {
      _program!.weeks[i].number = i + 1;
    }

    notifyListeners();
  }

  /// Reorder workouts in a week
  void reorderWorkouts(int weekIndex, int oldIndex, int newIndex) {
    if (_program == null ||
        !ValidationUtils.isValidProgramIndex(_program!, weekIndex) ||
        oldIndex < 0 ||
        oldIndex >= _program!.weeks[weekIndex].workouts.length ||
        newIndex < 0 ||
        newIndex > _program!.weeks[weekIndex].workouts.length) {
      return;
    }

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final workout = _program!.weeks[weekIndex].workouts.removeAt(oldIndex);
    _program!.weeks[weekIndex].workouts.insert(newIndex, workout);

    // Update workout orders
    for (int i = 0; i < _program!.weeks[weekIndex].workouts.length; i++) {
      _program!.weeks[weekIndex].workouts[i].order = i + 1;
    }

    notifyListeners();
  }

  /// Reorder exercises in a workout
  void reorderExercises(
      int weekIndex, int workoutIndex, int oldIndex, int newIndex) {
    if (_program == null ||
        !ValidationUtils.isValidProgramIndex(
            _program!, weekIndex, workoutIndex) ||
        oldIndex < 0 ||
        oldIndex >=
            _program!
                .weeks[weekIndex].workouts[workoutIndex].exercises.length ||
        newIndex < 0 ||
        newIndex >
            _program!
                .weeks[weekIndex].workouts[workoutIndex].exercises.length) {
      return;
    }

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final exercise = _program!.weeks[weekIndex].workouts[workoutIndex].exercises
        .removeAt(oldIndex);
    _program!.weeks[weekIndex].workouts[workoutIndex].exercises
        .insert(newIndex, exercise);

    // Update exercise orders
    final exercises =
        _program!.weeks[weekIndex].workouts[workoutIndex].exercises;
    for (int i = 0; i < exercises.length; i++) {
      exercises[i].order = i + 1;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _athleteIdController.dispose();
    _mesocycleNumberController.dispose();
    super.dispose();
  }
}
