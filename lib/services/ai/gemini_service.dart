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

      // Rimuovi markdown e caratteri non necessari
      text = text.replaceAll(RegExp(r'\n'), ' ').trim();

      return text;
    }
    throw Exception('Failed to get response from Gemini API');
  }

  String _buildJsonPrompt(String query, Map<String, dynamic>? context) {
    if (context != null) {
      return 'Context: ${jsonEncode(context)}\nQuery: $query';
    }
    return query;
  }
}
