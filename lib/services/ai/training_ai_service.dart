import 'dart:convert';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ai_service.dart';
import 'openai_service.dart';
import 'gemini_service.dart';
import 'package:alphanessone/services/ai/ai_settings_service.dart';

class TrainingAIService {
  final AIService aiService;
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  TrainingAIService(this.aiService);

  Future<String> processTrainingQuery(
    String query, {
    required Map<String, dynamic> userProfile,
    required List<Map<String, dynamic>> exercises,
    required Map<String, dynamic> trainingProgram,
  }) async {
    final context = {
      'userProfile': userProfile,
      'exercises': exercises,
      'trainingProgram': trainingProgram,
    };

    return aiService.processNaturalLanguageQuery(query, context: context);
  }

  Future<String> processNaturalLanguageQuery(String query,
      {Map<String, dynamic>? context}) async {
    return aiService.processNaturalLanguageQuery(query, context: context);
  }

  Future<Map<String, dynamic>> analyzeExercise(
      String exerciseName, Map<String, dynamic> exerciseData) async {
    final query = '''
      Analyze this exercise: $exerciseName
      Exercise data: ${exerciseData.toString()}
      Provide insights about proper form, common mistakes, and progression recommendations.
    ''';

    final response = await processNaturalLanguageQuery(query);
    return {
      'exercise': exerciseName,
      'analysis': response,
    };
  }

  Future<String> suggestWorkoutModifications(
      String currentProgram, Map<String, dynamic> userGoals) async {
    final query = '''
      Current program: $currentProgram
      User goals: ${userGoals.toString()}
      Suggest modifications to optimize this workout program for the user's goals.
    ''';

    return processNaturalLanguageQuery(query);
  }

  Future<Map<String, dynamic>?> interpretMaxRMMessage(String message) async {
    _logger.i('Interpreting max RM message: $message');

    final systemPrompt = '''
    Sei un assistente specializzato nell'interpretazione di messaggi relativi ai massimali (PR) di allenamento.

    IMPORTANTE: Devi SEMPRE rispondere SOLO con un oggetto JSON valido, anche in caso di errori o mancanza di dati.
    NON aggiungere MAI testo esplicativo o commenti fuori dal JSON.
    NON usare markdown o backticks nel JSON.

    Se l'utente sta:
    1. Aggiornando un massimale → type: "update"
    2. Chiedendo info su un massimale → type: "query"
    3. Chiedendo la lista dei massimali → type: "list"
    4. Altro o errori → type: "error"

    Formato JSON richiesto:
    {
      "type": "update" | "query" | "list" | "error",
      "exercise": "nome esercizio" (opzionale per error e list),
      "weight": numero (solo per update),
      "reps": numero (solo per update),
      "error_message": "messaggio di errore" (solo per error)
    }

    Se non hai accesso ai dati o non puoi determinare l'esercizio, rispondi con:
    {
      "type": "error",
      "error_message": "Dati non disponibili"
    }

    Query: $message
    ''';

    try {
      _logger.d('Sending query to AI service');
      final response = await aiService.processNaturalLanguageQuery(systemPrompt,
          context: {'systemPrompt': systemPrompt});

      _logger.d('Received response from AI service: $response');

      try {
        final Map<String, dynamic> result = json.decode(response);
        _logger.d('Parsed JSON result: $result');

        if (!['update', 'query', 'error', 'list'].contains(result['type'])) {
          _logger.w('Invalid response type: ${result['type']}');
          return null;
        }

        // Non eseguiamo più query qui stesse come in passato,
        // lasciamo che sia il widget (AIChatService) a gestire le query effettive.
        // Questa funzione si limita a interpretare il messaggio.

        return result;
      } catch (e, stackTrace) {
        _logger.e('Error parsing AI response',
            error: e, stackTrace: stackTrace);
        return {
          'type': 'error',
          'error_message': 'Errore nell\'interpretazione della risposta'
        };
      }
    } catch (e, stackTrace) {
      _logger.e('Error in interpretMaxRMMessage',
          error: e, stackTrace: stackTrace);
      return {'type': 'error', 'error_message': 'Errore interno del servizio'};
    }
  }
}

final trainingAIServiceProvider = Provider<TrainingAIService>((ref) {
  final aiSettings = ref.watch(aiSettingsProvider);
  final selectedModel = aiSettings.selectedModel;

  AIService aiService;
  switch (aiSettings.selectedProvider) {
    case AIProvider.openAI:
      aiService = ref.watch(openaiServiceProvider(selectedModel.modelId));
      break;
    case AIProvider.gemini:
      aiService = ref.watch(geminiServiceProvider(aiSettings.geminiKey!));
      break;
    default:
      throw Exception('No AI provider selected');
  }

  return TrainingAIService(aiService);
});

final openaiServiceProvider = Provider.family<OpenAIService, String>(
    (ref, model) => OpenAIService(model: model));
final geminiServiceProvider = Provider.family<GeminiService, String>(
    (ref, apiKey) => GeminiService(apiKey: apiKey));

final openAIModelProvider = StateProvider<String>((ref) => 'gpt4o');
