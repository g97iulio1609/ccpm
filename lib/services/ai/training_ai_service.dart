import 'dart:convert';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
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

  Future<String> processNaturalLanguageQuery(String query,
      {Map<String, dynamic>? context}) async {
    return aiService.processNaturalLanguageQuery(query, context: context);
  }

  /// Interpreta il messaggio e determina il tipo di funzionalità richiesta.
  ///
  /// Per maxrm ora aggiungiamo anche "calculate":
  /// {
  ///   "featureType": "maxrm",
  ///   "action": "calculate",
  ///   "weight": numero,
  ///   "reps": numero
  /// }
  ///
  Future<Map<String, dynamic>?> interpretMessage(String message) async {
    _logger.i('Interpreting message: $message');

    final systemPrompt = '''
Sei un assistente fitness. Devi classificare il messaggio dell'utente per capire di quale funzionalità si tratta.
Devi SEMPRE restituire un oggetto JSON valido senza testo aggiuntivo.

Funzionalità:
- "maxrm": richieste sui massimali (aggiornamento, query singola, lista, calcolo 1RM da un dato peso e reps)
- "profile": richieste sul profilo utente (aggiornamento dati personali, query dati)
- "other": altro (nessuna funzionalità speciale)
- "error": se non capisci la richiesta

Per "maxrm":
Possibili azioni:
- "update" se l'utente vuole aggiornare un massimale
- "query" se chiede il massimale di un esercizio specifico
- "list" se chiede la lista di tutti i massimali
- "calculate" se chiede di calcolare il 1RM partendo da peso e reps

Per "profile":
Possibili azioni:
- "update_profile"
- "query_profile"

Se non rientra in maxrm o profile, "featureType" = "other".

Se non capisci, "featureType" = "error" e fornisci "error_message".

Esempi:
{
  "featureType": "maxrm",
  "action": "calculate",
  "weight": 190,
  "reps": 3
}

{
  "featureType": "maxrm",
  "action": "update",
  "exercise": "panca piana",
  "weight": 100,
  "reps": 5
}

{
  "featureType": "profile",
  "action": "update_profile",
  "phoneNumber": "+391234567890"
}

{
  "featureType": "other"
}

{
  "featureType": "error",
  "error_message": "Non ho capito la richiesta"
}

Query: $message
''';

    try {
      final response =
          await aiService.processNaturalLanguageQuery(systemPrompt);
      _logger.d('interpretMessage response: $response');

      final result = json.decode(response) as Map<String, dynamic>;
      return result;
    } catch (e, stackTrace) {
      _logger.e('Error in interpretMessage', error: e, stackTrace: stackTrace);
      return {'featureType': 'error', 'error_message': 'Errore interno'};
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
