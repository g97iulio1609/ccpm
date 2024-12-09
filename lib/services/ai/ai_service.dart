import 'package:alphanessone/services/ai/openai_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:alphanessone/services/ai/gemini_service.dart';
import 'ai_settings_service.dart';

abstract class AIService {
  Future<String> processNaturalLanguageQuery(String query, {Map<String, dynamic>? context});
}

final aiServiceProvider = Provider<AIService>((ref) {
  final settings = ref.watch(aiSettingsProvider);
  
  switch (settings.selectedProvider) {
    case AIProvider.openAI:
      return OpenAIService(apiKey: settings.openAIKey, model: settings.selectedModel.modelId);
    case AIProvider.gemini:
      return GeminiService(apiKey: settings.geminiKey);
    case AIProvider.claude:
      // TODO: Implement Claude service
      throw UnimplementedError('Claude service not implemented yet');
    case AIProvider.azureOpenAI:
      // TODO: Implement Azure OpenAI service
      throw UnimplementedError('Azure OpenAI service not implemented yet');
    default:
      throw UnsupportedError('Unsupported AI provider: ${settings.selectedProvider}');
  }
});

class AIResponse {
  final String text;
  final Map<String, dynamic>? data;
  final String? error;

  AIResponse({
    required this.text,
    this.data,
    this.error,
  });
}
