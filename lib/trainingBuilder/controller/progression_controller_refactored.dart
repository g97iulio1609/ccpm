import 'package:flutter/material.dart';
import '../models/training_model.dart';
import 'package:alphanessone/shared/shared.dart';
import '../models/progressions_model.dart';
import '../models/progression_view_model.dart';
import '../services/progression_business_service_optimized.dart';
import '../shared/utils/validation_utils.dart';

/// Controller refactorizzato per le operazioni sulle progressioni
/// Segue il principio Single Responsibility - solo presentazione
class ProgressionControllerRefactored extends ChangeNotifier {
  // Stato UI
  bool _isLoading = false;
  String? _errorMessage;
  List<List<WeekProgression>> _weekProgressions = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<List<WeekProgression>> get weekProgressions => _weekProgressions;

  /// Costruisce le progressioni settimanali per un esercizio
  void buildWeekProgressions(
    List<Week> weeks,
    Exercise exercise,
  ) {
    _clearError();

    try {
      _setLoading(true);
      _weekProgressions =
          ProgressionBusinessServiceOptimized.buildWeekProgressions(
              weeks, exercise);
      notifyListeners();
    } catch (e) {
      _setError('Errore nella costruzione delle progressioni: $e');
      _weekProgressions = [];
    } finally {
      _setLoading(false);
    }
  }

  /// Aggiunge un gruppo di serie
  void addSeriesGroup({
    required int weekIndex,
    required int sessionIndex,
    required int groupIndex,
    required Exercise exercise,
  }) {
    _clearError();

    try {
      ProgressionBusinessServiceOptimized.addSeriesGroup(
        weekIndex: weekIndex,
        sessionIndex: sessionIndex,
        groupIndex: groupIndex,
        weekProgressions: _weekProgressions,
        exercise: exercise,
      );
      notifyListeners();
    } catch (e) {
      _setError('Errore nell\'aggiunta del gruppo serie: $e');
    }
  }

  /// Rimuove un gruppo di serie
  void removeSeriesGroup({
    required int weekIndex,
    required int sessionIndex,
    required int groupIndex,
  }) {
    _clearError();

    try {
      ProgressionBusinessServiceOptimized.removeSeriesGroup(
        weekIndex: weekIndex,
        sessionIndex: sessionIndex,
        groupIndex: groupIndex,
        weekProgressions: _weekProgressions,
      );
      notifyListeners();
    } catch (e) {
      _setError('Errore nella rimozione del gruppo serie: $e');
    }
  }

  /// Aggiorna una serie
  void updateSeries(SeriesUpdateParams params) {
    _clearError();

    try {
      ProgressionBusinessServiceOptimized.updateSeries(
        params: params,
        weekProgressions: _weekProgressions,
      );
      notifyListeners();
    } catch (e) {
      _setError('Errore nell\'aggiornamento della serie: $e');
    }
  }

  /// Valida le progressioni
  bool validateProgression(Exercise exercise) {
    try {
      return ProgressionBusinessServiceOptimized.validateProgression(
        exercise: exercise,
        weekProgressions: _weekProgressions,
      );
    } catch (e) {
      _setError('Errore nella validazione delle progressioni: $e');
      return false;
    }
  }

  /// Crea progressioni aggiornate dai controller
  List<List<WeekProgression>> createUpdatedWeekProgressions(
    List<List<List<dynamic>>> controllers,
  ) {
    _clearError();

    try {
      return ProgressionBusinessServiceOptimized.createUpdatedWeekProgressions(
        controllers,
        _parseInt,
        _parseDouble,
      );
    } catch (e) {
      _setError('Errore nella creazione delle progressioni aggiornate: $e');
      return [];
    }
  }

  /// Ottiene la serie rappresentativa per un gruppo
  Series? getRepresentativeSeries(List<Series> group, int groupIndex) {
    try {
      if (group.isEmpty) return null;
      return ProgressionBusinessServiceOptimized.getRepresentativeSeries(
          group, groupIndex);
    } catch (e) {
      _setError('Errore nell\'ottenimento della serie rappresentativa: $e');
      return null;
    }
  }

  /// Resetta le progressioni
  void resetProgressions() {
    _weekProgressions = [];
    _clearError();
    notifyListeners();
  }

  /// Esporta le progressioni in formato JSON per debug
  Map<String, dynamic> exportProgressionsForDebug() {
    try {
      final export = <String, dynamic>{};

      for (int weekIndex = 0;
          weekIndex < _weekProgressions.length;
          weekIndex++) {
        final weekData = <String, dynamic>{};

        for (int sessionIndex = 0;
            sessionIndex < _weekProgressions[weekIndex].length;
            sessionIndex++) {
          final session = _weekProgressions[weekIndex][sessionIndex];
          weekData['session_${sessionIndex + 1}'] = {
            'weekNumber': session.weekNumber,
            'sessionNumber': session.sessionNumber,
            'seriesCount': session.series.length,
            'series': session.series
                .map((s) => {
                      'reps': s.reps,
                      'sets': s.sets,
                      'weight': s.weight,
                      'intensity': s.intensity,
                      'rpe': s.rpe,
                    })
                .toList(),
          };
        }

        export['week_${weekIndex + 1}'] = weekData;
      }

      return export;
    } catch (e) {
      _setError('Errore nell\'esportazione delle progressioni: $e');
      return {};
    }
  }

  /// Importa progressioni da dati JSON
  void importProgressionsFromData(Map<String, dynamic> data) {
    _clearError();

    try {
      _setLoading(true);
      final newProgressions = <List<WeekProgression>>[];

      for (final weekKey in data.keys) {
        if (!weekKey.startsWith('week_')) continue;

        final weekData = data[weekKey] as Map<String, dynamic>;
        final weekProgressions = <WeekProgression>[];

        for (final sessionKey in weekData.keys) {
          if (!sessionKey.startsWith('session_')) continue;

          final sessionData = weekData[sessionKey] as Map<String, dynamic>;
          final seriesData = sessionData['series'] as List<dynamic>;

          final series = seriesData.map((s) {
            final seriesMap = s as Map<String, dynamic>;
            return Series(
              serieId: DateTime.now().millisecondsSinceEpoch.toString(),
              reps: seriesMap['reps'] ?? 0,
              sets: seriesMap['sets'] ?? 1,
              weight: (seriesMap['weight'] ?? 0.0).toDouble(),
              intensity: seriesMap['intensity'] ?? '',
              rpe: seriesMap['rpe'] ?? '',
              order: 1,
              done: false,
              reps_done: 0,
              weight_done: 0.0,
            );
          }).toList();

          weekProgressions.add(WeekProgression(
            weekNumber: sessionData['weekNumber'] ?? 1,
            sessionNumber: sessionData['sessionNumber'] ?? 1,
            series: series,
          ));
        }

        newProgressions.add(weekProgressions);
      }

      _weekProgressions = newProgressions;
      notifyListeners();
    } catch (e) {
      _setError('Errore nell\'importazione delle progressioni: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Mostra dialog di conferma reset
  Future<bool> showResetProgressionsConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Conferma Reset'),
          content: const Text(
              'Sei sicuro di voler resettare tutte le progressioni?\n\n'
              'Questa azione non può essere annullata.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reset'),
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

  // Metodi privati helper

  int _parseInt(String value) {
    return int.tryParse(value.trim()) ?? 0;
  }

  double _parseDouble(String value) {
    return double.tryParse(value.trim()) ?? 0.0;
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
