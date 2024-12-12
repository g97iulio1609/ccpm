import 'dart:convert';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:alphanessone/models/user_model.dart';
import 'ai_service.dart';
import 'openai_service.dart';
import 'gemini_service.dart';
import 'package:alphanessone/services/ai/ai_settings_service.dart';

class TrainingAIService {
  final AIService primaryAIService;
  final AIService fallbackAIService;
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

  TrainingAIService(this.primaryAIService, this.fallbackAIService);

  Future<String> processNaturalLanguageQuery(String query,
      {Map<String, dynamic>? context}) async {
    final result = await _tryWithFallback(
      (service) => service.processNaturalLanguageQuery(query, context: context),
    );
    return result;
  }

  Future<String> processNaturalLanguageQueryWithFallback(String query,
      {Map<String, dynamic>? context}) async {
    return await fallbackAIService.processNaturalLanguageQuery(query,
        context: context);
  }

  Future<Map<String, dynamic>?> interpretMessage(String message) async {
    _logger.i('Interpreting message: $message');
    return await _tryInterpretWithFallback((service) async {
      final response = await service
          .processNaturalLanguageQuery(_interpretationPrompt(message));
      final result = _parseJson(response);
      return result;
    });
  }

  Future<Map<String, dynamic>?> interpretMessageWithFallback(
      String message) async {
    _logger.i('Interpreting message with fallback: $message');
    final response = await fallbackAIService
        .processNaturalLanguageQuery(_interpretationPrompt(message));
    return _parseJson(response);
  }

  Future<Map<String, dynamic>?> handleNonStandardQuery(
    String message,
    UserModel user,
    List<dynamic> chatHistory,
  ) async {
    _logger.i('Handling non-standard query: $message');

    final prompt = _nonStandardQueryPrompt(message, user, chatHistory);
    return await _tryInterpretWithFallback((service) async {
      final response = await service.processNaturalLanguageQuery(prompt);
      return _parseJson(response);
    });
  }

  Future<Map<String, dynamic>?> handleNonStandardQueryWithFallback(
      String message, UserModel user, List<dynamic> chatHistory) async {
    _logger.i('Handling non-standard query with fallback: $message');
    final prompt = _nonStandardQueryPrompt(message, user, chatHistory);
    final response =
        await fallbackAIService.processNaturalLanguageQuery(prompt);
    return _parseJson(response);
  }

  Future<T> _tryWithFallback<T>(Future<T> Function(AIService) action) async {
    try {
      return await action(primaryAIService);
    } catch (e) {
      _logger.w('Primary provider failed, trying fallback: $e');
      return await action(fallbackAIService);
    }
  }

  Future<Map<String, dynamic>?> _tryInterpretWithFallback(
      Future<Map<String, dynamic>?> Function(AIService) action) async {
    try {
      final result = await action(primaryAIService);
      if (result == null || result['featureType'] == 'error') {
        _logger.w('Primary interpretation failed, trying fallback');
        return await action(fallbackAIService);
      }
      return result;
    } catch (e) {
      _logger.w('Primary interpretation exception: $e. Trying fallback...');
      try {
        return await action(fallbackAIService);
      } catch (e2) {
        _logger.e('Fallback interpretation also failed: $e2');
        return {
          'featureType': 'error',
          'error_message': 'Errore interno di interpretazione'
        };
      }
    }
  }

  String _interpretationPrompt(String message) {
    return '''
Sei un assistente fitness. Devi classificare il messaggio dell'utente per capire di quale funzionalità si tratta.
Devi SEMPRE restituire un oggetto JSON valido senza testo aggiuntivo.

Funzionalità:
- "maxrm": richieste sui massimali (update, query, list, calculate)
- "profile": richieste sul profilo (update_profile, query_profile)
- "training": richieste sui programmi di allenamento (create_program, query_program)
- "other": altro (nessuna funzionalità speciale)
- "error": se non capisci

Esempi:
{
  "featureType": "maxrm",
  "action": "calculate",
  "weight": 190,
  "reps": 3
}

{
  "featureType": "training",
  "action": "create_program",
  "name": "Programma Squat",
  "description": "Programma di allenamento focalizzato sullo squat",
  "weeks": [
    {
      "number": 1,
      "workouts": [
        {
          "order": 1,
          "name": "Allenamento 1",
          "exercises": [
            {
              "name": "Squat",
              "type": "compound",
              "variant": "back",
              "order": 1,
              "series": [
                {
                  "reps": 5,
                  "weight": 100,
                  "intensity": "75",
                  "order": 1
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}

{
  "featureType": "training",
  "action": "query_program",
  "userId": userProfile['id']
}

{
  "featureType": "other"
}

{
  "featureType": "error",
  "error_message": "Non ho capito"
}

Query: $message
''';
  }

  String _nonStandardQueryPrompt(
      String message, UserModel user, List<dynamic> chatHistory) {
    final userProfile = user.toMap();
    userProfile.updateAll((key, value) {
      if (value is DateTime) {
        return value.toIso8601String();
      } else if (value.toString().contains('Timestamp')) {
        // Gestisce i Timestamp di Firestore
        return value.toDate().toIso8601String();
      }
      return value;
    });

    final serializedHistory = chatHistory.map((msg) {
      var content = msg.content;
      if (content is Map) {
        content = _makeSerializable(content);
      }
      return {'role': msg.role, 'content': content};
    }).toList();

    final context = {
      'userProfile': userProfile,
      'chatHistory': serializedHistory,
    };

    return '''
You are a fitness assistant. The user asked a non-standard or complex question.
You can think step-by-step. Use chain-of-thought reasoning inside special comments that will not be shown to the user.
At the end, output only the final JSON.

If you can interpret the question as a known featureType and action, output that JSON.
If not, but you can still provide a helpful answer, return:
{
  "featureType": "other",
  "responseText": "La tua risposta utile all'utente."
}

Context: ${jsonEncode(context)}
User question: $message
''';
  }

  // Metodo per rendere serializzabile il contesto
  dynamic _makeSerializable(dynamic value) {
    if (value is Map) {
      return value.map((key, value) => MapEntry(key, _makeSerializable(value)));
    } else if (value is List) {
      return value.map((e) => _makeSerializable(e)).toList();
    } else if (value is DateTime) {
      return value.toIso8601String();
    } else if (value.toString().contains('Timestamp')) {
      // Gestisce i Timestamp di Firestore
      return value.toDate().toIso8601String();
    }
    return value;
  }

  Map<String, dynamic>? _parseJson(String response) {
    try {
      final result = json.decode(response) as Map<String, dynamic>;
      return result;
    } catch (e) {
      return {
        "featureType": "error",
        "error_message": "Risposta non valida: formato JSON non corretto"
      };
    }
  }
}

final trainingAIServiceProvider = Provider<TrainingAIService>((ref) {
  final aiSettings = ref.watch(aiSettingsProvider);
  final selectedModel = aiSettings.selectedModel;

  AIService primaryAIService;
  AIService fallbackAIService;

  switch (aiSettings.selectedProvider) {
    case AIProvider.openAI:
      primaryAIService =
          ref.watch(openaiServiceProvider(selectedModel.modelId));
      if (aiSettings.geminiKey != null && aiSettings.geminiKey!.isNotEmpty) {
        fallbackAIService =
            ref.watch(geminiServiceProvider(aiSettings.geminiKey!));
      } else {
        fallbackAIService =
            ref.watch(openaiServiceProvider(selectedModel.modelId));
      }
      break;
    case AIProvider.gemini:
      primaryAIService =
          ref.watch(geminiServiceProvider(aiSettings.geminiKey!));
      fallbackAIService = ref.watch(openaiServiceProvider("gpt4o"));
      break;
    default:
      throw Exception('No AI provider selected');
  }

  return TrainingAIService(primaryAIService, fallbackAIService);
});

final openaiServiceProvider = Provider.family<OpenAIService, String>(
    (ref, model) => OpenAIService(model: model));
final geminiServiceProvider =
    Provider.family<GeminiService, String>((ref, apiKey) {
  final settings = ref.watch(aiSettingsProvider);
  final selectedModel = settings.selectedModel.modelId;
  return GeminiService(
    apiKey: apiKey,
    model: selectedModel,
  );
});

final selectedAIModelProvider = StateProvider<String>((ref) => 'gemini-pro');
final openAIModelProvider = StateProvider<String>((ref) => 'gpt4o');
