import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'ai_service.dart';

class GeminiService implements AIService {
  final String apiKey;
  final String model;
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
    ),
  );

  GeminiService({
    required this.apiKey,
    required this.model,
  });

  String get baseUrl =>
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';

  @override
  Future<String> processNaturalLanguageQuery(String query,
      {Map<String, dynamic>? context}) async {
    _logger.i('Processing query with Gemini: $query');
    if (context != null) {
      _logger.d('Full Context: $context');
      if (context['userProfile'] != null) {
        _logger.d('UserProfile from context: ${context['userProfile']}');
        _logger.d('User ID from context: ${context['userProfile']['id']}');
      } else {
        _logger.w('UserProfile is null in context');
      }
    } else {
      _logger.w('Context is null');
    }

    final url = Uri.parse('$baseUrl?key=$apiKey');
    final prompt = _buildJsonPrompt(query, context);

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
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

    _logger.d('Response status code: ${response.statusCode}');
    _logger.d('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      var text = data['candidates'][0]['content']['parts'][0]['text'].trim();

      // Rimozione dei blocchi di codice e backtick
      text = text
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll('```', '')
          .trim();

      try {
        final jsonResponse = json.decode(text);
        if (jsonResponse is Map<String, dynamic>) {
          // Se c'è responseText, restituiamo direttamente il testo finale
          if (jsonResponse.containsKey('responseText')) {
            return jsonResponse['responseText'] ?? 'Risposta non disponibile.';
          }

          // Altrimenti restituiamo il JSON re-encodato, permettendo al trainingAIService di gestire l'azione
          return json.encode(jsonResponse);
        } else {
          _logger.e('Gemini: la risposta non è un oggetto JSON valido.');
          return 'Mi dispiace, si è verificato un errore nell\'elaborazione della risposta.';
        }
      } catch (e) {
        _logger.e('Gemini: Invalid JSON response: $e\nResponse text: $text');
        return 'Mi dispiace, si è verificato un errore nell\'elaborazione della risposta.';
      }
    } else {
      _logger.e('Gemini Error response: ${response.body}');
      return "Si è verificato un errore durante la richiesta. Riprova più tardi.";
    }
  }

  String _buildJsonPrompt(String query, Map<String, dynamic>? context) {
    final userProfile = context?['userProfile'];
    final userId = userProfile?['id']?.toString();
    final contextInfo = userProfile != null
        ? '\nContesto utente: ${json.encode({
                'id': userId,
                'name': userProfile['name'],
                'role': userProfile['role'],
              })}'
        : '';

    return '''
Rispondi alla seguente domanda e restituisci il risultato SOLO come un oggetto JSON puro, senza markdown o altri delimitatori.
Per le richieste di tipo "training" con action "query_program", devi SEMPRE includere il campo "userId" preso dal contesto utente id.

$contextInfo

Esempio di formato richiesto:
{
  "featureType": "training",
  "action": "query_program",
  "userId": "$userId"
}

oppure:

{
  "featureType": "other",
  "responseText": "La tua risposta dettagliata in un formato leggibile dall'utente finale."
}

Domanda:
$query
''';
  }
}
