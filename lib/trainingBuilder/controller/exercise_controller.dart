import 'package:flutter/material.dart';
import 'package:alphanessone/shared/shared.dart';
import '../domain/services/exercise_business_service.dart';
import '../dialog/exercise_dialog.dart';
import '../shared/utils/validation_utils.dart' as local_validation_utils;

/// Controller refactorizzato per le operazioni sugli esercizi
/// Segue il principio Single Responsibility - solo presentazione
class ExerciseControllerRefactored {
  final ExerciseBusinessService _businessService;

  // Stato UI
  bool _isLoading = false;
  String? _errorMessage;

  ExerciseControllerRefactored({
    required ExerciseBusinessService businessService,
  }) : _businessService = businessService;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Aggiunge un esercizio al workout
  Future<void> addExercise(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
    BuildContext context,
  ) async {
    _clearError();

    try {
      final exercise = await _showExerciseDialog(
        context,
        null,
        program.athleteId,
      );
      if (exercise != null) {
        _setLoading(true);
        await _businessService.addExercise(
          program,
          weekIndex,
          workoutIndex,
          exercise,
        );
        // state delegated to outer controller
      }
    } catch (e) {
      _setError('Errore nell\'aggiunta dell\'esercizio: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Rimuove un esercizio dal workout
  void removeExercise(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
  ) {
    _clearError();

    try {
      _businessService.removeExercise(
        program,
        weekIndex,
        workoutIndex,
        exerciseIndex,
      );
      // state delegated to outer controller
    } catch (e) {
      _setError('Errore nella rimozione dell\'esercizio: $e');
    }
  }

  /// Duplica un esercizio nel workout
  void duplicateExercise(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
  ) {
    _clearError();

    try {
      _businessService.duplicateExercise(
        program,
        weekIndex,
        workoutIndex,
        exerciseIndex,
      );
      // state delegated to outer controller
    } catch (e) {
      _setError('Errore nella duplicazione dell\'esercizio: $e');
    }
  }

  /// Modifica un esercizio esistente
  Future<void> editExercise(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
    BuildContext context,
  ) async {
    _clearError();

    try {
      final currentExercise = program
          .weeks[weekIndex]
          .workouts[workoutIndex]
          .exercises[exerciseIndex];

      final updatedExercise = await _showExerciseDialog(
        context,
        currentExercise,
        program.athleteId,
      );

      if (updatedExercise != null) {
        _setLoading(true);
        await _businessService.updateExercise(
          program,
          weekIndex,
          workoutIndex,
          exerciseIndex,
          updatedExercise,
        );
        // state delegated to outer controller
      }
    } catch (e) {
      _setError('Errore nella modifica dell\'esercizio: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Aggiorna i pesi degli esercizi
  Future<void> updateExerciseWeights(
    TrainingProgram program,
    String exerciseId,
    String exerciseType,
  ) async {
    _clearError();

    try {
      _setLoading(true);
      await _businessService.updateExerciseWeights(
        program,
        exerciseId,
        exerciseType,
      );
      // state delegated to outer controller
    } catch (e) {
      _setError('Errore nell\'aggiornamento dei pesi: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Aggiorna un singolo esercizio del programma
  Future<void> updateSingleProgramExercise(
    TrainingProgram program,
    String exerciseId,
    String exerciseType,
  ) async {
    _clearError();

    try {
      _setLoading(true);
      await _businessService.updateSingleProgramExercise(
        program,
        exerciseId,
        exerciseType,
      );
      // state delegated to outer controller
    } catch (e) {
      _setError('Errore nell\'aggiornamento dell\'esercizio: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Riordina gli esercizi in un workout
  void reorderExercises(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
    int oldIndex,
    int newIndex,
  ) {
    _clearError();

    try {
      _businessService.reorderExercises(
        program,
        weekIndex,
        workoutIndex,
        oldIndex,
        newIndex,
      );
      // state delegated to outer controller
    } catch (e) {
      _setError('Errore nel riordinamento degli esercizi: $e');
    }
  }

  /// Sposta un esercizio da un workout a un altro
  void moveExercise(
    TrainingProgram program,
    int weekIndex,
    int sourceWorkoutIndex,
    int destinationWorkoutIndex,
    int exerciseIndex,
  ) {
    _clearError();

    try {
      _businessService.moveExercise(
        program,
        weekIndex,
        sourceWorkoutIndex,
        destinationWorkoutIndex,
        exerciseIndex,
      );
      // state delegated to outer controller
    } catch (e) {
      _setError('Errore nello spostamento dell\'esercizio: $e');
    }
  }

  /// Aggiunge una serie alla progressione
  void addSeriesToProgression(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
  ) {
    _clearError();

    try {
      _businessService.addSeriesToProgression(
        program,
        weekIndex,
        workoutIndex,
        exerciseIndex,
      );
      // state delegated to outer controller
    } catch (e) {
      _setError('Errore nell\'aggiunta della serie: $e');
    }
  }

  /// Valida gli esercizi di un workout
  bool validateWorkoutExercises(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
  ) {
    if (!local_validation_utils.ValidationUtils.isValidProgramIndex(
      program,
      weekIndex,
      workoutIndex,
    )) {
      return false;
    }

    try {
      final exercises =
          program.weeks[weekIndex].workouts[workoutIndex].exercises;
      return _businessService.validateWorkoutExercises(exercises);
    } catch (e) {
      _setError('Errore nella validazione degli esercizi: $e');
      return false;
    }
  }

  /// Ottiene statistiche sugli esercizi
  Map<String, dynamic> getExerciseStatistics(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
  ) {
    if (!local_validation_utils.ValidationUtils.isValidProgramIndex(
      program,
      weekIndex,
      workoutIndex,
    )) {
      return {};
    }

    try {
      final exercises =
          program.weeks[weekIndex].workouts[workoutIndex].exercises;
      return _businessService.getExerciseStatistics(exercises);
    } catch (e) {
      _setError('Errore nel calcolo delle statistiche: $e');
      return {};
    }
  }

  /// Mostra dialog per aggiunta/modifica esercizio
  Future<Exercise?> _showExerciseDialog(
    BuildContext context,
    Exercise? exercise,
    String athleteId,
  ) async {
    try {
      final result = await showDialog<Exercise>(
        context: context,
        builder: (context) => ExerciseDialog(
          exerciseRecordService: _businessService.exerciseRecordService,
          athleteId: athleteId,
          exercise: exercise,
        ),
      );
      return result;
    } catch (e) {
      _setError('Errore nel dialog esercizio: $e');
      return null;
    }
  }

  /// Mostra dialog di conferma rimozione
  Future<bool> showRemoveExerciseConfirmation(
    BuildContext context,
    String exerciseName,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          scrollable: true,
          insetPadding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          title: const Text('Conferma Rimozione'),
          content: Text(
            'Sei sicuro di voler rimuovere l\'esercizio "$exerciseName"?\n\n'
            'Questa azione eliminerà anche tutte le serie associate.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Rimuovi'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  /// Mostra dialog per selezionare esercizio da copiare
  Future<Exercise?> showCopyExerciseDialog(
    BuildContext context,
    TrainingProgram program,
  ) async {
    final allExercises = <Exercise>[];

    // Raccogli tutti gli esercizi del programma
    for (final week in program.weeks) {
      for (final workout in week.workouts) {
        allExercises.addAll(workout.exercises);
      }
    }

    if (allExercises.isEmpty) {
      _setError('Nessun esercizio disponibile da copiare');
      return null;
    }

    return showDialog<Exercise>(
      context: context,
      builder: (context) {
        return AlertDialog(
          scrollable: true,
          insetPadding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          title: const Text('Seleziona Esercizio da Copiare'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: allExercises.length,
              itemBuilder: (context, index) {
                final exercise = allExercises[index];
                return ListTile(
                  title: Text(exercise.name),
                  subtitle: Text('${exercise.type} - ${exercise.variant}'),
                  trailing: Text('${exercise.series.length} serie'),
                  onTap: () => Navigator.pop(context, exercise),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
          ],
        );
      },
    );
  }

  /// Pulisce l'errore
  void clearError() {
    _clearError();
  }

  // Metodi privati per gestione stato UI

  void _setLoading(bool loading) {
    _isLoading = loading;
  }

  void _setError(String? error) {
    _errorMessage = error;
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
    }
  }
}
