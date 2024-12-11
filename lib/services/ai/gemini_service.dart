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
      _logger.i('Processing query: $query');
      if (context != null) {
        _logger.d('Context: $context');
      }

      final url = Uri.parse('$baseUrl?key=$apiKey');
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
                {'text': query}
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
        final text = data['candidates'][0]['content']['parts'][0]['text'];

        // Pulizia della risposta per assicurare che sia JSON valido
        final cleanText = text
            .trim()
            .replaceAll(RegExp(r'```json\s*'), '')
            .replaceAll(RegExp(r'\s*```'), '')
            .replaceAll(RegExp(r'^\s*\{'), '{')
            .replaceAll(RegExp(r'\}\s*$'), '}');

        _logger.d('Cleaned response text: $cleanText');

        // Validazione del JSON
        try {
          json.decode(cleanText); // Test se è JSON valido
          _logger.i('Successfully parsed JSON response');
          return cleanText;
        } catch (e) {
          _logger.e('Invalid JSON response: $cleanText', error: e);
          return jsonEncode({
            "type": "error",
            "error_message": "Risposta non valida: formato JSON non corretto"
          });
        }
      } else {
        _logger.e('Error response: ${response.body}');
        return jsonEncode({
          "type": "error",
          "error_message": "Errore nella richiesta: ${response.statusCode}"
        });
      }
    } catch (e, stackTrace) {
      _logger.e('Exception in processNaturalLanguageQuery',
          error: e, stackTrace: stackTrace);
      return jsonEncode(
          {"type": "error", "error_message": "Errore interno del servizio"});
    }
  }

  Future<String> processTrainingQuery(
    String query, {
    Map<String, dynamic>? userProfile,
    List<Map<String, dynamic>>? chatHistory,
    List<Map<String, dynamic>>? exercises,
    Map<String, dynamic>? trainingProgram,
  }) async {
    try {
      _logger.i('Processing training query: $query');
      if (userProfile != null) {
        _logger.d('User Profile: $userProfile');
      }
      if (chatHistory != null) {
        _logger.d('Chat History: $chatHistory');
      }
      if (exercises != null) {
        _logger.d('Exercises: $exercises');
      }
      if (trainingProgram != null) {
        _logger.d('Training Program: $trainingProgram');
      }

      final url = Uri.parse('$baseUrl?key=$apiKey');

      final List<Map<String, dynamic>> contents = [];

      if (chatHistory != null) {
        for (final message in chatHistory) {
          contents.add({
            'role': message['role'],
            'parts': [
              {'text': message['content']}
            ],
          });
        }
      }

      contents.add({
        'role': 'user',
        'parts': [
          {
            'text': '''
Context:
${userProfile != null ? 'User Profile: ${jsonEncode(userProfile)}' : ''}
${exercises != null ? 'Exercises: ${jsonEncode(exercises)}' : ''}
${trainingProgram != null ? 'Training Program: ${jsonEncode(trainingProgram)}' : ''}

Query: $query
'''
          }
        ],
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': contents,
          'safetySettings': [
            {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'}
          ]
        }),
      );

      _logger.d('Response status code: ${response.statusCode}');
      _logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];

        final cleanText = text
            .trim()
            .replaceAll(RegExp(r'```json\s*'), '')
            .replaceAll(RegExp(r'\s*```'), '')
            .replaceAll(RegExp(r'^\s*\{'), '{')
            .replaceAll(RegExp(r'\}\s*$'), '}');

        _logger.d('Cleaned response text: $cleanText');

        try {
          json.decode(cleanText);
          _logger.i('Successfully parsed JSON response');
          return cleanText;
        } catch (e) {
          _logger.e('Invalid JSON response: $cleanText', error: e);
          return jsonEncode({
            "type": "error",
            "error_message": "Risposta non valida: formato JSON non corretto"
          });
        }
      } else {
        _logger.e('Error response: ${response.body}');
        return jsonEncode({
          "type": "error",
          "error_message": "Errore nella richiesta: ${response.statusCode}"
        });
      }
    } catch (e, stackTrace) {
      _logger.e('Exception in processTrainingQuery',
          error: e, stackTrace: stackTrace);
      return jsonEncode(
          {"type": "error", "error_message": "Errore interno del servizio"});
    }
  }
}
