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
  Future<String> processNaturalLanguageQuery(String query,
      {Map<String, dynamic>? context}) async {
    _logger.i('Processing query with OpenAI: "$query"');
    final messages = [
      {
        'role': 'system',
        'content':
            '''Sei un assistente fitness che deve interpretare le richieste dell'utente e fornire risposte naturali.
Analizza la richiesta e restituisci un JSON con l'interpretazione E una risposta naturale.

Esempio di risposta per domande sui programmi di allenamento:
{
  "featureType": "training",
  "action": "query_program",
  "current": true,
  "responseText": "Ecco il tuo programma di allenamento attuale..."
}

Esempio di risposta per domande sui programmi disponibili:
{
  "featureType": "training",
  "action": "query_program",
  "userId": "${context?['userProfile']?['id'] ?? 'default_user'}",
  "responseText": "Ecco tutti i tuoi programmi di allenamento..."
}

Se non riesci a interpretare la richiesta, restituisci:
{
  "featureType": "other",
  "responseText": "La tua risposta naturale qui..."
}'''
      },
      if (context != null) ...[
        {
          'role': 'system',
          'content': jsonEncode(context),
        },
      ],
      {'role': 'user', 'content': query},
    ];

    _logger.d('Sending request to OpenAI with messages: $messages');

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

        // Se c'è un responseText, restituiscilo
        if (jsonResponse['responseText'] != null) {
          return jsonResponse['responseText'];
        }

        // Altrimenti restituisci il JSON completo per essere processato da AIServices
        return content;
      } catch (e) {
        _logger.w('Failed to parse JSON response: $e');
        // Se non è un JSON valido, restituisci il testo originale
        return content;
      }
    } else {
      _logger.e(
          'Failed to process query with OpenAI: ${response.statusCode} - ${response.body}');
      throw Exception(
          'Failed to process query: ${response.statusCode} - ${response.body}');
    }
  }
}
