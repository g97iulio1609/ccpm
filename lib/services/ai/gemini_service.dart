// lib/services/ai/gemini_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'ai_service.dart';

class GeminiService implements AIService {
  final String apiKey;
  final String model;
  final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 2, errorMethodCount: 8),
  );

  GeminiService({required this.apiKey, required this.model});

  String get baseUrl =>
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';

  @override
  Future<String> processNaturalLanguageQuery(
    String query, {
    Map<String, dynamic>? context,
  }) async {
    _logger.i('Elaborazione query con Gemini: "$query"');

    final url = Uri.parse('$baseUrl?key=$apiKey');
    final prompt = _buildPrompt(query, context);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'safetySettings': [
            {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
          ],
          'generationConfig': {'temperature': 0.7, 'topP': 0.8, 'topK': 40},
        }),
      );

      _logger.d('Gemini response status code: ${response.statusCode}');
      _logger.d('Gemini response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text']
            .trim();
        _logger.d('Gemini raw response content: $text');

        try {
          // Rimuovi i delimitatori markdown se presenti
          String jsonText = text;
          if (text.startsWith('```')) {
            final matches = RegExp(
              r'```(?:json)?\n([\s\S]*?)\n```',
            ).firstMatch(text);
            if (matches != null && matches.groupCount >= 1) {
              jsonText = matches.group(1)!.trim();
            }
          }

          // Prova a parsare il JSON
          final jsonResponse = jsonDecode(jsonText);

          // Valida la risposta
          if (!_isValidResponse(jsonResponse)) {
            _logger.w('Risposta non valida da Gemini: $jsonResponse');
            return jsonEncode({
              'featureType': 'other',
              'actions': [],
              'responseText':
                  'Mi dispiace, non sono riuscito a interpretare la richiesta correttamente.',
            });
          }

          return jsonText;
        } catch (e) {
          _logger.w('Failed to parse JSON response: $e');
          return jsonEncode({
            'featureType': 'other',
            'actions': [],
            'responseText': text,
          });
        }
      }

      throw Exception(
        'Failed to get response from Gemini API: ${response.statusCode}',
      );
    } catch (e) {
      _logger.e('Error calling Gemini API', error: e);
      throw Exception('Failed to process query: $e');
    }
  }

  String _buildPrompt(String query, Map<String, dynamic>? context) {
    final userId = context?['userProfile']?['id'] ?? 'default_user';
    final currentProgram = context?['userProfile']?['currentProgram'];
    final features = context?['features'] ?? {};

    return '''
Sei un assistente fitness intelligente che deve interpretare le richieste dell'utente e pianificare le azioni necessarie.
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
      "params": {
        "weekNumber": 1
      },
      "priority": 1
    },
    {
      "type": "add_workout",
      "params": {
        "weekNumber": 1
      },
      "priority": 2,
      "dependencies": ["add_week"]
    },
    {
      "type": "add_exercise",
      "params": {
        "weekNumber": 1,
        "workoutNumber": 1,
        "exercise": "Panca Piana"
      },
      "priority": 3,
      "dependencies": ["add_workout"]
    },
    {
      "type": "add_series",
      "params": {
        "weekNumber": 1,
        "workoutOrder": 1,
        "exerciseName": "Panca Piana",
        "sets": 5,
        "reps": 4,
        "intensity": "80",
        "maxIntensity": "85",
        "rpe": "0",
        "maxRpe": "0",
        "weight": 100.0,
        "maxWeight": 120.0
      },
      "priority": 4,
      "dependencies": ["add_exercise"]
    }
  ],
  "context": {
    "userId": "$userId"
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

IMPORTANTE:
1. Rispondi SEMPRE con un JSON valido
2. Includi SEMPRE un responseText appropriato
3. Per domande sui programmi usa SEMPRE featureType "training"
4. Per domande sui massimali usa SEMPRE featureType "maxrm"
5. Per domande sul profilo usa SEMPRE featureType "profile"
6. L'utente ha già un programma corrente: ${currentProgram != null ? 'Sì' : 'No'}
7. I campi weekNumber e workoutNumber devono SEMPRE essere numeri interi, MAI stringhe
8. Per aggiungere serie a un esercizio usa SEMPRE l'azione add_series separata
9. Per i range di peso (es. "100-120"), usa il valore minimo per weight e il massimo per maxWeight
10. Per i range di intensità (es. "80-85%"), usa il valore minimo per intensity e il massimo per maxIntensity, rimuovendo il simbolo %
11. I campi weight e maxWeight devono SEMPRE essere numeri decimali (double)
12. I campi intensity, maxIntensity, rpe e maxRpe devono SEMPRE essere stringhe
13. Se non specificati, usa "0" per rpe e maxRpe

Funzionalità disponibili:
${features['training'] == true ? '- Training' : ''}
${features['maxrm'] == true ? '- MaxRM' : ''}
${features['profile'] == true ? '- Profile' : ''}

Se non riesci a interpretare la richiesta, restituisci:
{
  "featureType": "other",
  "actions": [],
  "responseText": "Mi dispiace, non ho capito cosa vuoi fare. Puoi essere più specifico?"
}

Richiesta dell'utente: $query
''';
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
