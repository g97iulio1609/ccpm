// /lib/providers/ai_providers.dart
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/services/ai/ai_service.dart';
import 'package:alphanessone/services/ai/ai_settings_service.dart';
import 'package:alphanessone/services/ai/gemini_service.dart';
import 'package:alphanessone/services/ai/openai_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alphanessone/services/ai/AIServices.dart';

// Provider per SharedPreferences (se non già definito in providers.dart)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
      'sharedPreferencesProvider needs to be overridden in main.dart');
});

// Provider per AISettingsService
final aiSettingsServiceProvider = Provider<AISettingsService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AISettingsService(prefs);
});

// Provider per AISettingsNotifier e AISettings
final aiSettingsProvider =
    StateNotifierProvider<AISettingsNotifier, AISettings>((ref) {
  final service = ref.watch(aiSettingsServiceProvider);
  return AISettingsNotifier(service);
});

// Provider famiglia per OpenAIService
final openaiServiceProvider =
    Provider.family<OpenAIService, String>((ref, modelId) {
  final aiSettings = ref.watch(aiSettingsProvider);
  final openAIKey = aiSettings.openAIKey;
  if (openAIKey == null || openAIKey.isEmpty) {
    throw Exception('OpenAI API key is not set');
  }
  return OpenAIService(
    apiKey: openAIKey,
    model: modelId,
  );
});

// Provider famiglia per GeminiService
final geminiServiceProvider =
    Provider.family<GeminiService, String>((ref, apiKey) {
  final aiSettings = ref.watch(aiSettingsProvider);
  final selectedModel = aiSettings.selectedModel.modelId;
  if (apiKey.isEmpty) {
    throw Exception('Gemini API key is not set');
  }
  return GeminiService(
    model: selectedModel,
    apiKey: apiKey,
  );
});

// Provider per AIServiceManager
final aiServiceManagerProvider = Provider<AIServiceManager>((ref) {
  final aiSettings = ref.watch(aiSettingsProvider);
  final usersService = ref.watch(usersServiceProvider);

  final logger = Logger();

  AIService primaryAIService;
  AIService fallbackAIService;

  logger.i('Selected Provider: ${aiSettings.selectedProvider}');
  logger.i('Available Providers: ${aiSettings.availableProviders}');
  logger.i('Selected Model: ${aiSettings.selectedModel}');
  switch (aiSettings.selectedProvider) {
    case AIProvider.openAI:
      // Check for OpenAI API key
      if (aiSettings.openAIKey == null || aiSettings.openAIKey!.isEmpty) {
        throw Exception('OpenAI API key is not set');
      }
      primaryAIService =
          ref.watch(openaiServiceProvider(aiSettings.selectedModel.modelId));

      // Use Gemini as fallback if available
      if (aiSettings.geminiKey != null && aiSettings.geminiKey!.isNotEmpty) {
        fallbackAIService =
            ref.watch(geminiServiceProvider(aiSettings.geminiKey!));
      } else {
        fallbackAIService = primaryAIService;
      }
      break;

    case AIProvider.gemini:
      // Check for Gemini API key
      if (aiSettings.geminiKey == null || aiSettings.geminiKey!.isEmpty) {
        throw Exception('Gemini API key is not set');
      }
      primaryAIService =
          ref.watch(geminiServiceProvider(aiSettings.geminiKey!));

      // Use OpenAI as fallback if available
      if (aiSettings.openAIKey != null && aiSettings.openAIKey!.isNotEmpty) {
        fallbackAIService =
            ref.watch(openaiServiceProvider('gpt4o')); // Use a valid model ID
      } else {
        fallbackAIService = primaryAIService;
      }
      break;

    // Implement other providers similarly
    case AIProvider.claude:
      throw UnimplementedError('ClaudeService is not implemented yet');

    case AIProvider.azureOpenAI:
      throw UnimplementedError('AzureOpenAIService is not implemented yet');

    default:
      throw Exception('AI provider not implemented');
  }

  return AIServiceManager(primaryAIService, fallbackAIService, usersService);
});
