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

  Future<String> processTrainingQuery(String query, {
    Map<String, dynamic>? userProfile,
    List<Map<String, dynamic>>? chatHistory,
    List<Map<String, dynamic>>? exercises,
    Map<String, dynamic>? trainingProgram,
  }) async {
    try {
      final url = Uri.parse('$baseUrl?key=$apiKey');
      
      // Convert chat history to Gemini format
      final List<Map<String, dynamic>> contents = [];
      
      // Add chat history if available
      if (chatHistory != null) {
        for (final message in chatHistory) {
          contents.add({
            'role': message['role'],
            'parts': [{'text': message['content']}],
          });
        }
      }
      
      // Add current query with context
      contents.add({
        'role': 'user',
        'parts': [{
          'text': '''
Context:
${userProfile != null ? 'User Profile: ${jsonEncode(userProfile)}' : ''}
${exercises != null ? 'Exercises: ${jsonEncode(exercises)}' : ''}
${trainingProgram != null ? 'Training Program: ${jsonEncode(trainingProgram)}' : ''}

Query: $query
'''
        }],
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': contents,
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
