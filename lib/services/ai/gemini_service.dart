import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_service.dart';

class GeminiService implements AIService {
  final String apiKey;
  final String baseUrl;

  GeminiService({
    String? apiKey,
    this.baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent',
  }) : apiKey = apiKey ?? const String.fromEnvironment('GEMINI_API_KEY');

  @override
  Future<String> processNaturalLanguageQuery(String query, {Map<String, dynamic>? context}) async {
    try {
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
                {
                  'text': context != null 
                      ? 'Context: ${jsonEncode(context)}\nQuery: $query'
                      : query
                }
              ]
            }
          ],
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_NONE'
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        print('Error response: ${response.body}');  
        throw Exception('Failed to process query: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error processing query: $e');
    }
  }
}
