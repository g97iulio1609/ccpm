import 'dart:convert';
import 'package:alphanessone/services/ai/ai_providers.dart' as ai_providers;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:alphanessone/models/user_model.dart';
import 'ai_service.dart';
import 'package:alphanessone/services/ai/ai_settings_service.dart';
import 'package:alphanessone/services/users_services.dart';
import 'package:alphanessone/services/ai/extensions_manager.dart'; // Manager delle estensioni
import '../../providers/providers.dart';

class AIServiceManager {
  final AIService primaryAIService;
  final AIService fallbackAIService;
  final UsersService usersService;
  final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 0, errorMethodCount: 5),
  );

  final ExtensionsManager _extensionsManager = ExtensionsManager();

  AIServiceManager(
      this.primaryAIService, this.fallbackAIService, this.usersService);

  /// Metodo principale per elaborare una query dell'utente:
  /// - Interpreta il messaggio
  /// - Se identificata un'azione (ad es. query_program), esegue l'estensione corrispondente
  /// - Ritorna il risultato finale testuale all'utente
  Future<String> processQuery(String message,
      {Map<String, dynamic>? context}) async {
    _logger.i('Processing query: $message');

    final interpretation = await interpretMessage(message, context: context);
    if (interpretation == null) {
      return "Non ho capito la tua richiesta.";
    }

    final featureType = interpretation['featureType'] as String?;
    if (featureType == null) {
      return "Non ho capito la tua richiesta.";
    }

    final userId = usersService.getCurrentUserId();
    final user = await usersService.getUserById(userId);
    if (user == null) {
      return "Non riesco a recuperare il tuo profilo utente.";
    }

    _logger.d('Interpretation: $interpretation');

    try {
      if (featureType == 'error') {
        return interpretation['error_message'] ??
            "Non ho capito la tua richiesta.";
      } else if (featureType == 'other') {
        return interpretation['responseText'] ??
            await processNaturalLanguageQuery(message, context: context);
      } else {
        // Use the appropriate extension
        final result =
            await _extensionsManager.executeAction(interpretation, user);
        if (result != null && result.isNotEmpty) {
          return result;
        }
        // Se l'estensione non ha prodotto risultati, genera una risposta
        return "Mi dispiace, non ho trovato le informazioni richieste.";
      }
    } catch (e) {
      _logger.e('Error processing query', error: e);
      return "Si è verificato un errore durante l'elaborazione della richiesta.";
    }
  }

  Future<String> _formatExtensionResponse(
      String response, Map<String, dynamic> interpretation) async {
    // Se la risposta è già formattata, ritornala direttamente
    if (response.contains(':') || response.contains('\n')) {
      return response;
    }

    // Altrimenti, formatta la risposta in base al tipo di feature
    switch (interpretation['featureType']) {
      case 'training':
        if (interpretation['action'] == 'query_program') {
          if (response.toLowerCase().contains('non hai')) {
            return 'Al momento non hai programmi di allenamento attivi. Vuoi crearne uno nuovo?';
          }
          return 'Ecco i tuoi programmi di allenamento:\n$response';
        }
        break;
      // Aggiungi altri casi se necessario
    }

    return response;
  }

  Future<String> processNaturalLanguageQuery(String query,
      {Map<String, dynamic>? context}) async {
    context = _prepareContext(context);
    final result = await _tryWithFallback(
      (service) => service.processNaturalLanguageQuery(query, context: context),
    );
    return result;
  }

  Future<String> processNaturalLanguageQueryWithFallback(String query,
      {Map<String, dynamic>? context}) async {
    context = _prepareContext(context);
    return await fallbackAIService.processNaturalLanguageQuery(query,
        context: context);
  }

  Future<Map<String, dynamic>?> interpretMessage(String message,
      {Map<String, dynamic>? context}) async {
    _logger.i('Interpreting message: $message');
    context = _prepareContext(context);

    final response = await _tryInterpretWithFallback((service) async {
      final rawResponse = await service.processNaturalLanguageQuery(
          _interpretationPrompt(message),
          context: context);

      var result = _parseJson(rawResponse);

      // Se è una query di massimali ma manca l'exercise, estrai il nome dell'esercizio dal messaggio
      if (result != null &&
          result['featureType'] == 'maxrm' &&
          result['action'] == 'query' &&
          !result.containsKey('exercise')) {
        // Estrai il nome dell'esercizio dal messaggio originale
        final exerciseName = _extractExerciseName(message);
        if (exerciseName != null) {
          result['exercise'] = exerciseName;
        }
      }

      return result;
    });

    return response;
  }

  String _interpretationPrompt(String message) {
    return '''
Sei un assistente fitness specializzato. Analizza il messaggio e restituisci SOLO un oggetto JSON che descrive l'azione richiesta.

Funzionalità disponibili:
1. "maxrm": Per richieste sui massimali degli esercizi
   - action: "query" (per vedere i massimali)
   - action: "update" (per aggiornare i massimali)
   - action: "calculate" (per calcolare 1RM)
   - action: "list" (per elencare tutti i massimali)

2. "profile": Per informazioni sul profilo utente
3. "training": Per gestione programmi di allenamento
4. "other": Per domande generiche
5. "error": Per messaggi non comprensibili

Esempi di JSON validi:
{
  "featureType": "maxrm",
  "action": "query",
  "exercise": "Panca Piana"
}

{
  "featureType": "maxrm",
  "action": "calculate",
  "weight": 100,
  "reps": 5
}

{
  "featureType": "maxrm",
  "action": "list"
}

{
  "featureType": "other",
  "responseText": "La tua risposta qui"
}

Messaggio da interpretare: $message
''';
  }

  String? _extractExerciseName(String message) {
    // Lista di parole da rimuovere per isolare il nome dell'esercizio
    final wordsToRemove = [
      'qual è',
      'qual e',
      'quale',
      'dimmi',
      'il',
      'lo',
      'la',
      'i',
      'gli',
      'le',
      'mio',
      'mia',
      'miei',
      'mie',
      'massimale',
      'massimali',
      'record',
      'di',
      'per',
      'del',
      'dello',
      'della',
      'dei',
      'degli',
      'delle'
    ];

    String cleanMessage = message.toLowerCase();
    for (var word in wordsToRemove) {
      cleanMessage = cleanMessage.replaceAll(word, '');
    }

    // Rimuovi spazi multipli e trim
    cleanMessage = cleanMessage.replaceAll(RegExp(r'\s+'), ' ').trim();

    return cleanMessage.isEmpty ? null : cleanMessage;
  }

  Future<Map<String, dynamic>?> interpretMessageWithFallback(String message,
      {Map<String, dynamic>? context}) async {
    _logger.i('Interpreting message with fallback: $message');
    context = _prepareContext(context);

    final response = await fallbackAIService.processNaturalLanguageQuery(
        _interpretationPrompt(message),
        context: context);
    return _parseJson(response);
  }

  /// Gestisce una query non standard
  Future<Map<String, dynamic>?> handleNonStandardQuery(
    String message,
    UserModel user,
    List<dynamic> chatHistory,
  ) async {
    _logger.i('Handling non-standard query: $message');
    final prompt = _nonStandardQueryPrompt(message, user, chatHistory);
    final preparedContext = _prepareNonStandardContext(user, chatHistory);

    return await _tryInterpretWithFallback((service) async {
      final response = await service.processNaturalLanguageQuery(prompt,
          context: preparedContext);
      final result = _parseJson(response);

      if (result != null &&
          result['featureType'] != null &&
          result['featureType'] != 'error') {
        final extResult = await _extensionsManager.executeAction(result, user);
        if (extResult != null && extResult.isNotEmpty) {
          return {
            "featureType": result['featureType'],
            "action": result['action'],
            "responseText": extResult
          };
        }
      }

      return result;
    });
  }

  /// Versione fallback per query non standard
  Future<Map<String, dynamic>?> handleNonStandardQueryWithFallback(
      String message, UserModel user, List<dynamic> chatHistory) async {
    _logger.i('Handling non-standard query with fallback: $message');
    final prompt = _nonStandardQueryPrompt(message, user, chatHistory);
    final preparedContext = _prepareNonStandardContext(user, chatHistory);

    final response = await fallbackAIService.processNaturalLanguageQuery(prompt,
        context: preparedContext);
    final result = _parseJson(response);

    if (result != null &&
        result['featureType'] != null &&
        result['featureType'] != 'error') {
      final extResult = await _extensionsManager.executeAction(result, user);
      if (extResult != null && extResult.isNotEmpty) {
        return {
          "featureType": result['featureType'],
          "action": result['action'],
          "responseText": extResult
        };
      }
    }

    return result;
  }

  Map<String, dynamic>? _prepareContext(Map<String, dynamic>? context) {
    context ??= {};
    final userId = usersService.getCurrentUserId();

    var userProfile = context['userProfile'];
    if (userProfile is! Map) {
      userProfile = {};
    } else {
      userProfile = Map<String, dynamic>.from(userProfile);
    }

    userProfile['id'] = userId;

    userProfile.forEach((key, value) {
      if (value is DateTime) {
        userProfile[key] = value.toIso8601String();
      } else if (value.toString().contains('Timestamp')) {
        try {
          if (value is Timestamp) {
            userProfile[key] = value.toDate().toIso8601String();
          }
        } catch (_) {}
      }
    });

    context['userProfile'] = userProfile;
    _logger.d('Serialized context: $context');
    return _makeSerializable(context) as Map<String, dynamic>?;
  }

  Map<String, dynamic>? _prepareNonStandardContext(
      UserModel user, List<dynamic> chatHistory) {
    final userId = usersService.getCurrentUserId();
    final userProfile = user.toMap();

    userProfile['id'] = userId;
    userProfile.forEach((key, value) {
      if (value is DateTime) {
        userProfile[key] = value.toIso8601String();
      } else if (value.toString().contains('Timestamp')) {
        try {
          userProfile[key] = (value as Timestamp).toDate().toIso8601String();
        } catch (_) {}
      }
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

    return _makeSerializable(context) as Map<String, dynamic>?;
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

  String _nonStandardQueryPrompt(
      String message, UserModel user, List<dynamic> chatHistory) {
    final userId = usersService.getCurrentUserId();
    final userProfile = user.toMap();
    userProfile['id'] = userId;

    userProfile.forEach((key, value) {
      if (value is Timestamp) {
        userProfile[key] = value.toDate().toIso8601String();
      } else if (value is DateTime) {
        userProfile[key] = value.toIso8601String();
      }
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
Think step-by-step. At the end, output only the final JSON.

If you can interpret as a known featureType/action, output that JSON.
If not, return:
{
  "featureType": "other",
  "responseText": "La tua risposta utile."
}

Context: ${jsonEncode(context)}
User question: $message
''';
  }

  dynamic _makeSerializable(dynamic value) {
    if (value == null) return null;

    if (value is Map) {
      return Map<String, dynamic>.fromEntries(
        value.entries.map((entry) {
          var serializedValue = _makeSerializable(entry.value);
          return MapEntry(entry.key.toString(), serializedValue);
        }),
      );
    } else if (value is List) {
      return value.map((e) => _makeSerializable(e)).toList();
    } else if (value is Timestamp) {
      return value.toDate().toIso8601String();
    } else if (value is DateTime) {
      return value.toIso8601String();
    }
    return value;
  }

  Map<String, dynamic>? _parseJson(String response) {
    try {
      final result = json.decode(response) as Map<String, dynamic>;
      return result;
    } catch (_) {
      return {
        "featureType": "error",
        "error_message": "Risposta non valida: formato JSON non corretto"
      };
    }
  }
}

final aiServiceManagerProvider = Provider<AIServiceManager>((ref) {
  final aiSettings = ref.watch(ai_providers.aiSettingsProvider);
  final selectedModel = aiSettings.selectedModel;
  final usersService = ref.watch(usersServiceProvider);

  late AIService primaryAIService;
  late AIService fallbackAIService;

  switch (aiSettings.selectedProvider) {
    case AIProvider.openAI:
      if (aiSettings.openAIKey == null || aiSettings.openAIKey!.isEmpty) {
        throw Exception('OpenAI API key is not set');
      }
      primaryAIService =
          ref.watch(ai_providers.openaiServiceProvider(selectedModel.modelId));
      if (aiSettings.geminiKey != null && aiSettings.geminiKey!.isNotEmpty) {
        fallbackAIService = ref
            .watch(ai_providers.geminiServiceProvider(aiSettings.geminiKey!));
      } else {
        if (aiSettings.openAIKey == null || aiSettings.openAIKey!.isEmpty) {
          throw Exception('OpenAI API key is not set');
        }
        fallbackAIService = ref
            .watch(ai_providers.openaiServiceProvider(selectedModel.modelId));
      }
      break;
    case AIProvider.gemini:
      if (aiSettings.geminiKey == null || aiSettings.geminiKey!.isEmpty) {
        throw Exception('Gemini API key is not set');
      }
      primaryAIService =
          ref.watch(ai_providers.geminiServiceProvider(aiSettings.geminiKey!));
      // Use same Gemini service as fallback if OpenAI key is not available
      if (aiSettings.openAIKey != null && aiSettings.openAIKey!.isNotEmpty) {
        fallbackAIService = ref
            .watch(ai_providers.openaiServiceProvider(selectedModel.modelId));
      } else {
        fallbackAIService =
            primaryAIService; // Use Gemini as fallback if no OpenAI key
      }
      break;
    default:
      throw Exception('No AI provider selected');
  }

  return AIServiceManager(primaryAIService, fallbackAIService, usersService);
});
