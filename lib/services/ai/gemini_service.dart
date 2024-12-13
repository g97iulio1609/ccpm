// lib/services/ai/gemini_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'ai_service.dart';

class GeminiService implements AIService {
  final String apiKey;
  final String model;
  final Logger _logger =
      Logger(printer: PrettyPrinter(methodCount: 2, errorMethodCount: 8));

  GeminiService({required this.apiKey, required this.model});

  String get baseUrl =>
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';

  @override
  Future<String> processNaturalLanguageQuery(String query,
      {Map<String, dynamic>? context}) async {
    _logger.i('Processing query with Gemini: "$query"');

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
                {'text': prompt}
              ]
            }
          ],
          'safetySettings': [
            {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'}
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text =
            data['candidates'][0]['content']['parts'][0]['text'].trim();
        return text;
      }

      throw Exception(
          'Failed to get response from Gemini API: ${response.statusCode}');
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
Sei un assistente fitness specializzato. Analizza la richiesta e genera una risposta appropriata.
Rispondi SEMPRE con un JSON che descrive l'azione richiesta.

Funzionalità disponibili:
${features['training'] == true ? '''
1. TRAINING - Gestione programmi di allenamento:
   {
     "featureType": "training",
     "action": "query_program" | "create_program" | "update_program" | "delete_program",
     "current": true/false, // solo per query_program
     "responseText": "Messaggio per l'utente"
   }
''' : ''}

${features['maxrm'] == true ? '''
2. MAXRM - Gestione massimali:
   {
     "featureType": "maxrm",
     "action": "query" | "update" | "calculate",
     "exercise": "nome_esercizio", // obbligatorio per query/update
     "weight": numero, // per update/calculate
     "reps": numero, // per calculate
     "responseText": "Messaggio per l'utente"
   }
''' : ''}

${features['profile'] == true ? '''
3. PROFILE - Gestione profilo:
   {
     "featureType": "profile",
     "action": "query_profile" | "update_profile",
     "fields": ["campo1", "campo2"], // opzionale per query
     "updates": {}, // per update
     "responseText": "Messaggio per l'utente"
   }
''' : ''}

Per altre domande usa:
{
  "featureType": "other",
  "responseText": "Una risposta naturale e completa"
}

IMPORTANTE:
1. Rispondi SEMPRE con un JSON valido
2. Includi SEMPRE un responseText appropriato
3. Per domande sui programmi usa SEMPRE featureType "training"
4. Per domande sui massimali usa SEMPRE featureType "maxrm"
5. Per domande sul profilo usa SEMPRE featureType "profile"
6. L'utente ha già un programma corrente: ${currentProgram != null ? 'Sì' : 'No'}

Richiesta dell'utente: $query
''';
  }
}
