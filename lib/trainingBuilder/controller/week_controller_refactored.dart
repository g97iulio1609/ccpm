import 'package:flutter/material.dart';
import '../models/training_model.dart';
import 'package:alphanessone/shared/shared.dart';
import '../domain/services/week_business_service.dart';
import '../shared/utils/validation_utils.dart';

/// Controller refactorizzato per le operazioni sulle settimane
/// Segue il principio Single Responsibility - solo presentazione
class WeekControllerRefactored extends ChangeNotifier {
  final WeekBusinessService _businessService;

  // Stato UI
  bool _isLoading = false;
  String? _errorMessage;

  WeekControllerRefactored({
    required WeekBusinessService businessService,
  }) : _businessService = businessService;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Aggiunge una settimana al programma
  void addWeek(TrainingProgram program) {
    _clearError();

    try {
      _businessService.addWeek(program);
      notifyListeners();
    } catch (e) {
      _setError('Errore nell\'aggiunta della settimana: $e');
    }
  }

  /// Rimuove una settimana dal programma
  void removeWeek(TrainingProgram program, int weekIndex) {
    _clearError();

    try {
      _businessService.removeWeek(program, weekIndex);
      notifyListeners();
    } catch (e) {
      _setError('Errore nella rimozione della settimana: $e');
    }
  }

  /// Copia una settimana in una nuova posizione
  Future<void> copyWeek(
    TrainingProgram program,
    int sourceWeekIndex,
    BuildContext context,
  ) async {
    _clearError();

    try {
      final destinationWeekIndex = await _showCopyWeekDialog(program, context);
      if (destinationWeekIndex != null) {
        _setLoading(true);
        await _businessService.copyWeek(
            program, sourceWeekIndex, destinationWeekIndex);
        notifyListeners();
      }
    } catch (e) {
      _setError('Errore nella copia della settimana: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Riordina le settimane
  void reorderWeeks(TrainingProgram program, int oldIndex, int newIndex) {
    _clearError();

    try {
      _businessService.reorderWeeks(program, oldIndex, newIndex);
      notifyListeners();
    } catch (e) {
      _setError('Errore nel riordinamento delle settimane: $e');
    }
  }

  /// Aggiorna una settimana
  void updateWeek(TrainingProgram program, int weekIndex, Week updatedWeek) {
    _clearError();

    try {
      _businessService.updateWeek(program, weekIndex, updatedWeek);
      notifyListeners();
    } catch (e) {
      _setError('Errore nell\'aggiornamento della settimana: $e');
    }
  }

  /// Valida il programma
  bool validateProgram(TrainingProgram program) {
    return _businessService.validateProgram(program);
  }

  /// Ottiene statistiche delle settimane
  Map<String, dynamic> getWeekStatistics(TrainingProgram program) {
    try {
      return _businessService.getWeekStatistics(program);
    } catch (e) {
      _setError('Errore nel calcolo delle statistiche: $e');
      return {};
    }
  }

  /// Mostra dialog per selezione settimana di destinazione per copia
  Future<int?> _showCopyWeekDialog(
      TrainingProgram program, BuildContext context) async {
    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Copia Settimana'),
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
                      child: Text('Settimana ${program.weeks[index].number}'),
                    ),
                  ),
                  // Nuova settimana
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Nuova Settimana'),
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
  Future<bool> showRemoveWeekConfirmation(
      BuildContext context, int weekNumber) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Conferma Rimozione'),
          content: Text(
              'Sei sicuro di voler rimuovere la Settimana $weekNumber?\n\nQuesta azione eliminerà anche tutti gli allenamenti e gli esercizi contenuti.'),
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
