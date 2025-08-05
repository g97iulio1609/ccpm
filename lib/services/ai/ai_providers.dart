// lib/services/ai/ai_providers.dart
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/services/ai/ai_keys_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:alphanessone/services/ai/openai_service.dart';
import 'package:alphanessone/services/ai/gemini_service.dart';
import 'ai_service.dart';
import 'ai_settings_service.dart';
import 'ai_services.dart';

final aiSettingsServiceProvider = Provider<AISettingsService>((ref) {
  final sharedPreferencesAsync = ref.watch(sharedPreferencesProvider);
  return sharedPreferencesAsync.when(
    data: (sharedPreferences) => AISettingsService(sharedPreferences),
    loading: () =>
        AISettingsService(null), // Provide a default or handle loading state
    error: (error, stackTrace) {
      return AISettingsService(null); // Handle error state
    },
  );
});

final aiSettingsProvider =
    StateNotifierProvider<AISettingsNotifier, AISettings>((ref) {
  final service = ref.watch(aiSettingsServiceProvider);
  final keys = ref.watch(aiKeysStreamProvider).value;
  return AISettingsNotifier(service, keys);
});

// Provider per OpenAIService
final openaiServiceProvider =
    Provider.family<AIService, String>((ref, modelId) {
  final aiSettings = ref.watch(aiSettingsProvider);
  final apiKey = aiSettings.getKeyForProvider(AIProvider.openAI);
  if (apiKey == null || apiKey.isEmpty) {
    throw Exception('OpenAI API key is not set');
  }
  return OpenAIService(apiKey: apiKey, model: modelId);
});

// Provider per GeminiService
final geminiServiceProvider =
    Provider.family<AIService, String>((ref, modelId) {
  final aiSettings = ref.watch(aiSettingsProvider);
  final apiKey = aiSettings.getKeyForProvider(AIProvider.gemini);
  if (apiKey == null) {
    throw Exception('Gemini API key is not set');
  }
  return GeminiService(apiKey: apiKey, model: modelId);
});

// Provider per AIServiceManager
final aiServiceManagerProvider = Provider<AIServiceManager?>((ref) {
  final aiSettings = ref.watch(aiSettingsProvider);

  // Se non ci sono provider disponibili, restituisci null
  if (aiSettings.availableProviders.isEmpty) {
    return null;
  }

  final selectedModel = aiSettings.selectedModel;
  final usersService = ref.watch(usersServiceProvider);

  late AIService primaryAIService;
  late AIService fallbackAIService;

  try {
    switch (aiSettings.selectedProvider) {
      case AIProvider.openAI:
        final openAIKey = aiSettings.getKeyForProvider(AIProvider.openAI);
        if (openAIKey == null) {
          throw Exception('OpenAI API key is not set');
        }
        primaryAIService =
            ref.watch(openaiServiceProvider(selectedModel.modelId));

        final geminiKey = aiSettings.getKeyForProvider(AIProvider.gemini);
        fallbackAIService = geminiKey != null
            ? ref.watch(geminiServiceProvider(selectedModel.modelId))
            : primaryAIService;
        break;
      case AIProvider.gemini:
        final geminiKey = aiSettings.getKeyForProvider(AIProvider.gemini);
        if (geminiKey == null) {
          throw Exception('Gemini API key is not set');
        }
        primaryAIService =
            ref.watch(geminiServiceProvider(selectedModel.modelId));

        final openAIKey = aiSettings.getKeyForProvider(AIProvider.openAI);
        fallbackAIService = openAIKey != null
            ? ref.watch(openaiServiceProvider(selectedModel.modelId))
            : primaryAIService;
        break;
      default:
        throw Exception('No AI provider selected');
    }

    return AIServiceManager(primaryAIService, fallbackAIService, usersService);
  } catch (e) {
    return null;
  }
});
