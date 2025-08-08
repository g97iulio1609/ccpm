// lib/services/ai/openai_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_service.dart';
import 'package:logger/logger.dart';

class OpenAIService implements AIService {
  final String apiKey;
  final String model;
  final String baseUrl;
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 50,
      colors: true,
      printEmojis: true,
    ),
  );

  OpenAIService({
    required this.apiKey,
    required this.model,
    this.baseUrl = 'https://api.openai.com/v1/chat/completions',
  });

  @override
  Future<String> processNaturalLanguageQuery(
    String query, {
    Map<String, dynamic>? context,
  }) async {
    _logger.i('Elaborazione query con OpenAI: "$query"');
    final messages = [
      {
        'role': 'system',
        'content':
            '''Sei un assistente fitness intelligente che deve interpretare le richieste dell'utente e pianificare le azioni necessarie.
Analizza la richiesta e restituisci un JSON con l'interpretazione e le azioni da eseguire.

Il JSON deve seguire questo formato:
{
  "featureType": "training" | "maxrm" | "profile" | "other",
  "actions": [
    {
      "type": "string", // Tipo di azione
      "params": {}, // Parametri specifici dell'azione
      "priority": number, // Priorità di esecuzione (1-10)
      "dependencies": [], // ID di altre azioni da cui dipende
      "rollback": {} // Azioni da eseguire in caso di fallimento
    }
  ],
  "context": {}, // Contesto rilevante per l'esecuzione
  "responseText": "string" // Risposta naturale da mostrare all'utente
}

Esempi di azioni per ogni feature type:

1. TRAINING:
{
  "featureType": "training",
  "actions": [
    {
      "type": "add_week",
      "params": {},
      "priority": 1
    },
    {
      "type": "add_workout",
      "params": {
        "weekNumber": "last_added"
      },
      "priority": 2,
      "dependencies": ["add_week"]
    }
  ],
  "context": {
    "userId": "${context?['userProfile']?['id'] ?? 'default_user'}"
  },
  "responseText": "Creo una nuova settimana con un allenamento..."
}

2. MAXRM:
{
  "featureType": "maxrm",
  "actions": [
    {
      "type": "update",
      "params": {
        "exercise": "nome_esercizio",
        "weight": 100,
        "reps": 5
      },
      "priority": 1
    }
  ],
  "responseText": "Aggiorno il tuo massimale..."
}

3. PROFILE:
{
  "featureType": "profile",
  "actions": [
    {
      "type": "update_profile",
      "params": {
        "height": 180,
        "weight": 75,
        "activityLevel": "moderate"
      },
      "priority": 1
    }
  ],
  "responseText": "Aggiorno il tuo profilo..."
}

Se non riesci a interpretare la richiesta, restituisci:
{
  "featureType": "other",
  "actions": [],
  "responseText": "Mi dispiace, non ho capito cosa vuoi fare. Puoi essere più specifico?"
}''',
      },
      if (context != null) ...[
        {
          'role': 'system',
          'content': jsonEncode({
            'context': context,
            'availableFeatures': {
              'training': true,
              'maxrm': true,
              'profile': true,
            },
          }),
        },
      ],
      {'role': 'user', 'content': query},
    ];

    _logger.d('Invio richiesta a OpenAI con messaggi: $messages');

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': messages,
        'temperature': 0.7,
      }),
    );

    _logger.d('OpenAI response status code: ${response.statusCode}');
    _logger.d('OpenAI response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'] as String;
      _logger.d('OpenAI raw response content: $content');

      try {
        // Prova a parsare il JSON
        final jsonResponse = jsonDecode(content);

        // Valida la risposta
        if (!_isValidResponse(jsonResponse)) {
          _logger.w('Risposta non valida da OpenAI: $jsonResponse');
          return jsonEncode({
            'featureType': 'other',
            'actions': [],
            'responseText':
                'Mi dispiace, non sono riuscito a interpretare la richiesta correttamente.',
          });
        }

        return content;
      } catch (e) {
        _logger.w('Failed to parse JSON response: $e');
        return jsonEncode({
          'featureType': 'other',
          'actions': [],
          'responseText': content,
        });
      }
    } else {
      _logger.e(
        'Failed to process query with OpenAI: ${response.statusCode} - ${response.body}',
      );
      throw Exception(
        'Failed to process query: ${response.statusCode} - ${response.body}',
      );
    }
  }

  bool _isValidResponse(Map<String, dynamic> response) {
    // Verifica che la risposta contenga tutti i campi necessari
    if (!response.containsKey('featureType') ||
        !response.containsKey('actions') ||
        !response.containsKey('responseText')) {
      return false;
    }

    // Verifica che il featureType sia valido
    final validFeatureTypes = ['training', 'maxrm', 'profile', 'other'];
    if (!validFeatureTypes.contains(response['featureType'])) {
      return false;
    }

    // Verifica che actions sia una lista
    if (response['actions'] is! List) {
      return false;
    }

    // Verifica che ogni azione sia valida
    for (var action in response['actions']) {
      if (!_isValidAction(action)) {
        return false;
      }
    }

    return true;
  }

  bool _isValidAction(Map<String, dynamic> action) {
    // Verifica che l'azione contenga tutti i campi necessari
    if (!action.containsKey('type') ||
        !action.containsKey('params') ||
        !action.containsKey('priority')) {
      return false;
    }

    // Verifica che la priorità sia un numero valido
    final priority = action['priority'];
    if (priority is! num || priority < 1 || priority > 10) {
      return false;
    }

    // Verifica che params sia un oggetto
    if (action['params'] is! Map) {
      return false;
    }

    return true;
  }
}
