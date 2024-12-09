import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_service.dart';

class OpenAIService implements AIService {
  final String apiKey;
  final String model;
  final String baseUrl;

  OpenAIService({
    String? apiKey,
    this.model = 'gpt-4-turbo-preview',
    this.baseUrl = 'https://api.openai.com/v1/chat/completions',
  }) : apiKey = apiKey ?? const String.fromEnvironment('OPENAI_API_KEY');

  @override
  Future<String> processNaturalLanguageQuery(String query, {Map<String, dynamic>? context}) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful assistant for a fitness training application. '
                  'You can help with exercises, training programs, and fitness-related queries.',
            },
            if (context != null)
              {
                'role': 'system',
                'content': jsonEncode(context),
              },
            {
              'role': 'user',
              'content': query,
            },
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('Failed to process query: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error processing query: $e');
    }
  }
}
