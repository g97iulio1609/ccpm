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
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
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
    try {
      _logger.i('Processing query with Gemini: $query');
      if (context != null) {
        _logger.d('Context: $context');
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
        final text =
            data['candidates'][0]['content']['parts'][0]['text'].trim();

        try {
          final jsonResponse = json.decode(text);
          if (jsonResponse is Map<String, dynamic>) {
            // Se è una query di training, assicuriamoci che l'userId sia corretto
            if (jsonResponse['featureType'] == 'training' &&
                jsonResponse['action'] == 'query_program') {
              if (context != null &&
                  context['userProfile'] != null &&
                  context['userProfile']['uniqueNumber'] != null) {
                jsonResponse['userId'] =
                    context['userProfile']['uniqueNumber'].toString();
              } else {
                _logger.w(
                    'Context or userProfile.uniqueNumber is missing for training query');
                return 'Mi dispiace, non riesco a identificare il tuo profilo. Prova ad effettuare nuovamente il login.';
              }
              return json.encode(jsonResponse);
            }

            // Per altre risposte JSON
            if (jsonResponse.containsKey('responseText')) {
              return jsonResponse['responseText'];
            }
            return json.encode(jsonResponse);
          }
        } catch (e) {
          _logger.e('Gemini: Invalid JSON response: $e\nResponse text: $text');
          return 'Mi dispiace, si è verificato un errore nell\'elaborazione della risposta.';
        }
        return text;
      } else {
        _logger.e('Gemini Error response: ${response.body}');
        return "Si è verificato un errore durante la richiesta. Riprova più tardi.";
      }
    } catch (e, stackTrace) {
      _logger.e('Gemini Exception in processNaturalLanguageQuery',
          error: e, stackTrace: stackTrace);
      return "Si è verificato un errore interno. Per favore, contatta il supporto tecnico.";
    }
  }

  String _buildJsonPrompt(String query, Map<String, dynamic>? context) {
    final userProfile = context?['userProfile'];
    final contextInfo = userProfile != null
        ? '\nContesto utente: ${json.encode({
                'uniqueNumber': userProfile['uniqueNumber'],
                'name': userProfile['name'],
                'role': userProfile['role'],
              })}'
        : '';

    return '''
Rispondi alla seguente domanda e restituisci il risultato solo come un oggetto JSON. Non aggiungere testo fuori dal JSON.
Per le richieste di tipo "training" con action "query_program", devi SEMPRE includere il campo "userId" preso dal contesto utente uniqueNumber.

$contextInfo

Esempio di formato richiesto:
{
  "featureType": "training",
  "action": "query_program",
  "userId": "12345"
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
