// lib/services/ai/extensions_manager.dart
import 'package:alphanessone/models/user_model.dart';
import 'package:alphanessone/services/ai/extensions/ai_extension.dart';
import 'package:alphanessone/services/ai/extensions/maxrm_extension.dart';
import 'package:alphanessone/services/ai/extensions/profile_extension.dart';
import 'package:alphanessone/services/ai/extensions/training_extension.dart';
import 'package:alphanessone/services/ai/extensions/exercises_extension.dart';
import 'package:logger/logger.dart';

class ExtensionsManager {
  final Logger _logger = Logger();
  final List<AIExtension> _extensions = [
    MaxRMExtension(),
    ProfileExtension(),
    TrainingExtension(),
    ExercisesExtension(),
  ];

  Future<String?> executeAction(
      Map<String, dynamic> interpretation, UserModel user) async {
    try {
      // Se riceviamo un testo naturale, lo trattiamo come un'istruzione per l'agente
      if (interpretation['text'] != null) {
        final text = interpretation['text'] as String;

        // Qui l'AI dovrebbe analizzare il testo e identificare le azioni da eseguire
        // Per esempio, per "in settimana 4 aggiungi un allenamento, aggiungi un esercizio panca Piana, 5 series, 4 reps, 80-85 come intensità, peso 100-120"
        // L'AI dovrebbe identificare:
        // 1. Aggiunta di un allenamento nella settimana 4
        // 2. Aggiunta di un esercizio (panca piana)
        // 3. Aggiunta di serie con parametri specifici

        final actions = <Map<String, dynamic>>[];

        // Qui dovremmo avere la logica dell'AI per interpretare il testo
        // e generare le azioni appropriate

        // Per ora, come esempio, usiamo una logica semplificata
        if (text.contains('settimana') && text.contains('aggiungi')) {
          // Estrai il numero della settimana
          final weekNumber = int.parse(
              RegExp(r'settimana (\d+)').firstMatch(text)?.group(1) ?? '1');

          // Se menziona l'aggiunta di un allenamento
          if (text.contains('allenamento')) {
            actions.add({
              'featureType': 'training',
              'action': 'add_workout',
              'weekNumber': weekNumber
            });
          }

          // Se menziona l'aggiunta di un esercizio
          if (text.contains('esercizio')) {
            // Estrai il nome dell'esercizio
            final exerciseName =
                text.split('esercizio').last.split(',').first.trim();

            // Aggiungi l'azione per l'esercizio
            actions.add({
              'featureType': 'training',
              'action': 'add_exercise',
              'weekNumber': weekNumber,
              'workoutOrder': 1,
              'exerciseName': exerciseName
            });

            // Se ci sono dettagli sulle serie
            if (text.contains('series') && text.contains('reps')) {
              final sets = int.parse(
                  RegExp(r'(\d+)\s*series').firstMatch(text)?.group(1) ?? '0');
              final reps = int.parse(
                  RegExp(r'(\d+)\s*reps').firstMatch(text)?.group(1) ?? '0');
              final intensity = RegExp(r'(\d+)(?:-(\d+))?\s*come intensità')
                  .firstMatch(text)
                  ?.group(1);
              final weight =
                  RegExp(r'peso\s*(\d+)(?:-(\d+))?').firstMatch(text)?.group(1);

              actions.add({
                'featureType': 'training',
                'action': 'add_series',
                'weekNumber': weekNumber,
                'workoutOrder': 1,
                'exerciseName': exerciseName,
                'sets': sets,
                'reps': reps,
                'intensity': intensity,
                'weight': weight != null ? double.parse(weight) : null
              });
            }
          }
        }

        if (actions.isNotEmpty) {
          interpretation = {'multipleActions': actions};
        }
      }

      // Gestione delle azioni multiple
      if (interpretation['multipleActions'] != null) {
        final actions =
            interpretation['multipleActions'] as List<Map<String, dynamic>>;
        final results = <String>[];
        final userId = user.id;

        for (var action in actions) {
          final featureType = action['featureType'];
          if (featureType == null) continue;

          bool handled = false;
          for (var ext in _extensions) {
            if (await ext.canHandle(action)) {
              try {
                final result = await ext.handle(action, userId, user);
                if (result != null) {
                  results.add(result);
                }
                handled = true;
                break;
              } catch (e) {
                _logger.e('Error executing action', error: e);
                results.add(
                    'Errore nell\'esecuzione dell\'azione: ${e.toString()}');
              }
            }
          }
        }
        return results.join('\n');
      }

      // Gestione singola azione
      final featureType = interpretation['featureType'];
      if (featureType == null) return null;

      final userId = user.id;
      for (var ext in _extensions) {
        if (await ext.canHandle(interpretation)) {
          try {
            return await ext.handle(interpretation, userId, user);
          } catch (e) {
            _logger.e('Error executing action', error: e);
            return 'Errore nell\'esecuzione dell\'azione: ${e.toString()}';
          }
        }
      }

      return null;
    } catch (e) {
      _logger.e('Error in executeAction', error: e);
      return 'Si è verificato un errore durante l\'esecuzione delle azioni.';
    }
  }
}
