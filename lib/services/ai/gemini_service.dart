import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'ai_service.dart';

class GeminiService implements AIService {
  final String apiKey;
  final String baseUrl;
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
    this.baseUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent',
  });
  @override
  Future<String> processNaturalLanguageQuery(String query,
      {Map<String, dynamic>? context}) async {
    try {
      _logger.i('Processing query with Gemini: $query');
      if (context != null) {
        _logger.d('Context: $context');
      }

      final url = Uri.parse('$baseUrl?key=$apiKey');
      final prompt =
          _buildJsonPrompt(query); // Costruisce il prompt per il formato JSON

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
          // Prova a interpretare il testo come JSON
          final jsonResponse = json.decode(text);
          if (jsonResponse is Map<String, dynamic>) {
            return jsonResponse[
                'responseText']; // Restituisci solo la risposta formattata
          }
        } catch (e) {
          // Non è un JSON valido
          _logger.e('Gemini: Invalid JSON response, returning raw text: $text');
          return text;
        }
        return text; // Aggiungi questo return per il caso in cui il JSON non abbia il formato atteso
      } else {
        _logger.e('Gemini Error response: ${response.body}');
        return "Errore durante la richiesta. Riprovare.";
      }
    } catch (e, stackTrace) {
      _logger.e('Gemini Exception in processNaturalLanguageQuery',
          error: e, stackTrace: stackTrace);
      return "Errore interno del servizio AI. Contattare il supporto.";
    }
  }

  // Costruisce un prompt per ottenere una risposta JSON ben formattata
  String _buildJsonPrompt(String query) {
    return '''
Rispondi alla seguente domanda e restituisci il risultato solo come un oggetto JSON. Non aggiungere testo fuori dal JSON.

Esempio di formato richiesto:
{
  "featureType": "other",
  "responseText": "La tua risposta dettagliata in un formato leggibile dall'utente finale."
}

Domanda:
$query
''';
  }
}
