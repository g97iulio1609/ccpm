// lib/services/ai/ai_service.dart
abstract class AIService {
  Future<String> processNaturalLanguageQuery(String query,
      {Map<String, dynamic>? context});
}
