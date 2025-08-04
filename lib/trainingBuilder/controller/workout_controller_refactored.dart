import 'package:flutter/material.dart';
import '../models/training_model.dart';
import 'package:alphanessone/shared/shared.dart';
import '../domain/services/workout_business_service.dart';
import '../shared/utils/validation_utils.dart';

/// Controller refactorizzato per le operazioni sui workout
/// Segue il principio Single Responsibility - solo presentazione
class WorkoutControllerRefactored extends ChangeNotifier {
  final WorkoutBusinessService _businessService;

  // Stato UI
  bool _isLoading = false;
  String? _errorMessage;

  WorkoutControllerRefactored({
    required WorkoutBusinessService businessService,
  }) : _businessService = businessService;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Aggiunge un workout alla settimana
  void addWorkout(TrainingProgram program, int weekIndex) {
    _clearError();

    try {
      _businessService.addWorkout(program, weekIndex);
      notifyListeners();
    } catch (e) {
      _setError('Errore nell\'aggiunta dell\'allenamento: $e');
    }
  }

  /// Rimuove un workout dalla settimana
  void removeWorkout(TrainingProgram program, int weekIndex, int workoutIndex) {
    _clearError();

    try {
      _businessService.removeWorkout(program, weekIndex, workoutIndex);
      notifyListeners();
    } catch (e) {
      _setError('Errore nella rimozione dell\'allenamento: $e');
    }
  }

  /// Copia un workout in un'altra settimana
  Future<void> copyWorkout(
    TrainingProgram program,
    int sourceWeekIndex,
    int workoutIndex,
    BuildContext context,
  ) async {
    _clearError();

    try {
      final destinationWeekIndex =
          await _showCopyWorkoutDialog(program, context);
      if (destinationWeekIndex != null) {
        _setLoading(true);
        await _businessService.copyWorkout(
            program, sourceWeekIndex, workoutIndex, destinationWeekIndex);
        notifyListeners();
      }
    } catch (e) {
      _setError('Errore nella copia dell\'allenamento: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Duplica un workout nella stessa settimana
  void duplicateWorkout(
      TrainingProgram program, int weekIndex, int workoutIndex) {
    _clearError();

    try {
      _businessService.duplicateWorkout(program, weekIndex, workoutIndex);
      notifyListeners();
    } catch (e) {
      _setError('Errore nella duplicazione dell\'allenamento: $e');
    }
  }

  /// Riordina i workout in una settimana
  void reorderWorkouts(
      TrainingProgram program, int weekIndex, int oldIndex, int newIndex) {
    _clearError();

    try {
      _businessService.reorderWorkouts(program, weekIndex, oldIndex, newIndex);
      notifyListeners();
    } catch (e) {
      _setError('Errore nel riordinamento degli allenamenti: $e');
    }
  }

  /// Aggiorna un workout
  void updateWorkout(TrainingProgram program, int weekIndex, int workoutIndex,
      Workout updatedWorkout) {
    _clearError();

    try {
      _businessService.updateWorkout(
          program, weekIndex, workoutIndex, updatedWorkout);
      notifyListeners();
    } catch (e) {
      _setError('Errore nell\'aggiornamento dell\'allenamento: $e');
    }
  }

  /// Valida i workout di una settimana
  bool validateWeekWorkouts(int weekIndex, TrainingProgram program) {
    if (!ValidationUtils.isValidProgramIndex(program, weekIndex)) {
      return false;
    }

    try {
      return _businessService.validateWeekWorkouts(program.weeks[weekIndex]);
    } catch (e) {
      _setError('Errore nella validazione degli allenamenti: $e');
      return false;
    }
  }

  /// Ottiene statistiche sui workout per una settimana
  Map<String, dynamic> getWorkoutStatistics(
      int weekIndex, TrainingProgram program) {
    if (!ValidationUtils.isValidProgramIndex(program, weekIndex)) {
      return {};
    }

    try {
      return _businessService.getWorkoutStatistics(program.weeks[weekIndex]);
    } catch (e) {
      _setError('Errore nel calcolo delle statistiche: $e');
      return {};
    }
  }

  /// Mostra dialog per selezione settimana di destinazione per copia
  Future<int?> _showCopyWorkoutDialog(
      TrainingProgram program, BuildContext context) async {
    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Copia Allenamento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Seleziona la settimana di destinazione:'),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: null,
                items: [
                  // Settimane esistenti
                  ...List.generate(
                    program.weeks.length,
                    (index) => DropdownMenuItem(
                      value: index,
                      child: Text('Settimana ${index + 1}'),
                    ),
                  ),
                  // Nuova settimana
                  DropdownMenuItem(
                    value: program.weeks.length,
                    child: const Text('Nuova Settimana'),
                  ),
                ],
                onChanged: (value) {
                  Navigator.pop(context, value);
                },
                decoration: const InputDecoration(
                  labelText: 'Settimana di Destinazione',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
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

  /// Mostra dialog di conferma rimozione
  Future<bool> showRemoveWorkoutConfirmation(
      BuildContext context, int workoutOrder) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Conferma Rimozione'),
          content: Text(
              'Sei sicuro di voler rimuovere l\'Allenamento $workoutOrder?\n\n'
              'Questa azione eliminerà anche tutti gli esercizi contenuti.'),
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

  /// Mostra dialog per rinominare workout
  Future<String?> showRenameWorkoutDialog(
      BuildContext context, String currentName) async {
    final textController = TextEditingController(text: currentName);

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rinomina Allenamento'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nome Allenamento',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = textController.text.trim();
                if (newName.isNotEmpty) {
                  Navigator.pop(context, newName);
                }
              },
              child: const Text('Salva'),
            ),
          ],
        );
      },
    );

    textController.dispose();
    return result;
  }

  /// Pulisce l'errore
  void clearError() {
    _clearError();
  }

  // Metodi privati per gestione stato UI

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
}
