// lib/services/ai/extensions_manager.dart
import 'package:alphanessone/models/user_model.dart';
import 'package:alphanessone/services/ai/extensions/ai_extension.dart';
import 'package:alphanessone/services/ai/extensions/maxrm_extension.dart';
import 'package:alphanessone/services/ai/extensions/profile_extension.dart';
import 'package:alphanessone/services/ai/extensions/training_extension.dart';
import 'package:alphanessone/services/ai/extensions/exercises_extension.dart';
import 'package:logger/logger.dart';
import 'ai_agent.dart';
import 'llm_service.dart';

class ExtensionsManager {
  final Logger _logger = Logger();
  final List<AIExtension> _extensions = [
    MaxRMExtension(),
    ProfileExtension(),
    TrainingExtension(),
    ExercisesExtension(),
  ];

  late final AIAgent _agent;
  late final LLMService _llm;

  ExtensionsManager() {
    _llm = LLMService();
    _agent = AIAgent(llm: _llm, extensionsManager: this);
  }

  Future<String?> executeAction(
    Map<String, dynamic> interpretation,
    UserModel user,
  ) async {
    try {
      // Se riceviamo un testo naturale, lo passiamo all'agente
      if (interpretation['text'] != null) {
        return await _agent.executeTask(interpretation['text'] as String, user);
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

          for (var ext in _extensions) {
            if (await ext.canHandle(action)) {
              try {
                final result = await ext.handle(action, userId, user);
                if (result != null) {
                  results.add(result);
                }
                break;
              } catch (e) {
                _logger.e('Error executing action', error: e);
                results.add(
                  'Errore nell\'esecuzione dell\'azione: ${e.toString()}',
                );
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
