import 'package:logger/logger.dart';
import 'package:alphanessone/models/user_model.dart';
import 'llm_service.dart';
import 'extensions_manager.dart';

class AIAgent {
  final Logger _logger = Logger();
  final LLMService _llm;
  final ExtensionsManager _extensionsManager;

  AIAgent({required LLMService llm, required ExtensionsManager extensionsManager})
    : _llm = llm,
      _extensionsManager = extensionsManager;

  Future<String?> executeTask(String text, UserModel user) async {
    try {
      _logger.i('Avvio esecuzione task: $text');

      // 1. Analisi iniziale del testo
      final analysis = await _llm.analyzeText(text);
      _logger.d('Analisi del testo completata:', error: analysis);

      // 2. Creazione del piano d'azione iniziale
      final plan = await _llm.createActionPlan(analysis);
      _logger.d('Piano d\'azione creato:', error: plan.actions);

      // 3. Esecuzione iterativa delle azioni
      final results = <String>[];
      var currentContext = Map<String, dynamic>.from(plan.context);
      var remainingActions = List<Map<String, dynamic>>.from(plan.actions);

      while (remainingActions.isNotEmpty) {
        final currentAction = remainingActions.removeAt(0);
        currentAction.addAll(currentContext);

        // Esegui l'azione corrente
        final result = await _executeAction(currentAction, user);

        // Aggiorna il contesto con i risultati
        if (result.data != null) {
          currentContext.addAll(result.data!);
        }

        // Se l'azione è fallita, prova ad adattare il piano
        if (!result.isSuccess) {
          _logger.w('Azione fallita:', error: result.message);

          // Richiedi un piano alternativo
          final adjustedPlan = await _llm.adjustPlan(
            ActionPlan(actions: remainingActions, context: currentContext),
            result,
          );

          // Se ci sono azioni alternative, sostituisci quelle rimanenti
          if (adjustedPlan.actions.isNotEmpty) {
            _logger.i('Piano adattato, proseguo con le azioni corrette');
            remainingActions = adjustedPlan.actions;
            currentContext.addAll(adjustedPlan.context);
            continue;
          }
        }

        // Aggiungi il risultato alla lista dei risultati
        if (result.message != null) {
          results.add(result.message!);
        }

        // Verifica se sono necessarie azioni aggiuntive basate sul risultato
        final additionalActions = await _checkForAdditionalActions(result, currentContext, user);

        if (additionalActions.isNotEmpty) {
          remainingActions.insertAll(0, additionalActions);
        }
      }

      // 4. Genera una risposta coerente basata su tutti i risultati
      return await _generateFinalResponse(results, currentContext);
    } catch (e) {
      _logger.e('Errore durante l\'esecuzione del task', error: e);
      return 'Mi dispiace, si è verificato un errore durante l\'esecuzione del task: ${e.toString()}';
    }
  }

  Future<ActionResult> _executeAction(Map<String, dynamic> action, UserModel user) async {
    try {
      final result = await _extensionsManager.executeAction(action, user);

      if (result == null) {
        return ActionResult(
          isSuccess: false,
          message: 'Azione non supportata',
          errorType: 'unsupported_action',
          errorContext: {'failedFeatureType': action['featureType']},
        );
      }

      // Analizza il risultato in modo più dettagliato
      final analysisResult = await _analyzeActionResult(result, action);
      return analysisResult;
    } catch (e) {
      _logger.e('Errore durante l\'esecuzione dell\'azione', error: e);
      return ActionResult(
        isSuccess: false,
        message: 'Errore nell\'esecuzione dell\'azione: ${e.toString()}',
        errorType: 'execution_error',
        errorContext: {'failedFeatureType': action['featureType']},
      );
    }
  }

  Future<ActionResult> _analyzeActionResult(String result, Map<String, dynamic> action) async {
    // Analizza il risultato per determinare il successo e il contesto
    final isSuccess =
        !result.toLowerCase().contains('errore') &&
        !result.toLowerCase().contains('non trovato') &&
        !result.toLowerCase().contains('non valido');

    final data = isSuccess ? await _extractDataFromResult(result, action) : null;
    String? errorType;
    Map<String, dynamic>? errorContext;

    if (!isSuccess) {
      // Analizza il tipo di errore
      if (result.toLowerCase().contains('non trovato')) {
        errorType = 'not_found';
      } else if (result.toLowerCase().contains('non valido')) {
        errorType = 'invalid_input';
      } else if (result.toLowerCase().contains('errore')) {
        errorType = 'general_error';
      }

      errorContext = {'originalAction': action, 'errorMessage': result};
    }

    return ActionResult(
      isSuccess: isSuccess,
      message: result,
      data: data,
      errorType: errorType,
      errorContext: errorContext,
    );
  }

  Future<Map<String, dynamic>> _extractDataFromResult(
    String result,
    Map<String, dynamic> action,
  ) async {
    final data = <String, dynamic>{};

    // Estrai informazioni specifiche in base al tipo di azione
    switch (action['featureType']) {
      case 'training':
        _extractTrainingData(result, data);
        break;
      case 'maxrm':
        _extractMaxRMData(result, data);
        break;
      case 'profile':
        _extractProfileData(result, data);
        break;
    }

    return data;
  }

  void _extractTrainingData(String result, Map<String, dynamic> data) {
    // Estrai informazioni relative all'allenamento
    if (result.contains('settimana')) {
      final weekMatch = RegExp(r'settimana (\d+)').firstMatch(result);
      if (weekMatch != null) {
        data['weekNumber'] = int.parse(weekMatch.group(1)!);
      }
    }

    if (result.contains('allenamento')) {
      final workoutMatch = RegExp(r'allenamento (\d+)').firstMatch(result);
      if (workoutMatch != null) {
        data['workoutOrder'] = int.parse(workoutMatch.group(1)!);
      }
    }
  }

  void _extractMaxRMData(String result, Map<String, dynamic> data) {
    // Estrai informazioni relative ai massimali
    if (result.contains('kg')) {
      final weightMatch = RegExp(r'(\d+(?:\.\d+)?)\s*kg').firstMatch(result);
      if (weightMatch != null) {
        data['weight'] = double.parse(weightMatch.group(1)!);
      }
    }
  }

  void _extractProfileData(String result, Map<String, dynamic> data) {
    // Estrai informazioni relative al profilo
    // Implementa la logica specifica per il profilo
  }

  Future<List<Map<String, dynamic>>> _checkForAdditionalActions(
    ActionResult result,
    Map<String, dynamic> context,
    UserModel user,
  ) async {
    // Verifica se sono necessarie azioni aggiuntive basate sul risultato
    // e sul contesto corrente
    return [];
  }

  Future<String> _generateFinalResponse(List<String> results, Map<String, dynamic> context) async {
    // Genera una risposta coerente basata su tutti i risultati
    // e sul contesto finale
    if (results.isEmpty) {
      return 'Non sono riuscito a completare nessuna azione.';
    }

    // Se c'è un solo risultato, restituiscilo direttamente
    if (results.length == 1) {
      return results.first;
    }

    // Altrimenti, crea un riassunto delle azioni completate
    final buffer = StringBuffer();
    buffer.writeln('Ho completato le seguenti azioni:');

    for (var i = 0; i < results.length; i++) {
      buffer.writeln('${i + 1}. ${results[i]}');
    }

    return buffer.toString();
  }
}
