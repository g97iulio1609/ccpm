// lib/services/ai/ai_providers.dart
import 'package:alphanessone/providers/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:alphanessone/services/ai/openai_service.dart';
import 'package:alphanessone/services/ai/gemini_service.dart';
import 'package:logger/logger.dart';
import 'ai_service.dart';
import 'ai_settings_service.dart';
import 'AIServices.dart';

final aiSettingsServiceProvider = Provider<AISettingsService>((ref) {
  final sharedPreferencesAsync = ref.watch(sharedPreferencesProvider);
  return sharedPreferencesAsync.when(
    data: (sharedPreferences) => AISettingsService(sharedPreferences),
    loading: () =>
        AISettingsService(null), // Provide a default or handle loading state
    error: (error, stackTrace) {
      print('Error loading shared preferences: $error');
      return AISettingsService(null); // Handle error state
    },
  );
});

final aiSettingsProvider =
    StateNotifierProvider<AISettingsNotifier, AISettings>((ref) {
  final service = ref.watch(aiSettingsServiceProvider);
  return AISettingsNotifier(service);
});

// Provider per OpenAIService
final openaiServiceProvider =
    Provider.family<AIService, String>((ref, modelId) {
  final aiSettings = ref.watch(aiSettingsProvider);
  final apiKey = aiSettings.openAIKey;
  if (apiKey == null || apiKey.isEmpty) {
    throw Exception('OpenAI API key is not set');
  }
  return OpenAIService(apiKey: apiKey, model: modelId);
});

// Provider per GeminiService
final geminiServiceProvider = Provider.family<AIService, String>((ref, apiKey) {
  final aiSettings = ref.watch(aiSettingsProvider);
  final modelId = aiSettings.selectedModel.modelId;
  return GeminiService(apiKey: apiKey, model: modelId);
});

// Provider per AIServiceManager
final aiServiceManagerProvider = Provider<AIServiceManager>((ref) {
  final aiSettings = ref.watch(aiSettingsProvider);
  final selectedModel = aiSettings.selectedModel;
  final usersService = ref.watch(usersServiceProvider);

  late AIService primaryAIService;
  late AIService fallbackAIService;

  switch (aiSettings.selectedProvider) {
    case AIProvider.openAI:
      if (aiSettings.openAIKey == null || aiSettings.openAIKey!.isEmpty) {
        throw Exception('OpenAI API key is not set');
      }
      primaryAIService =
          ref.watch(openaiServiceProvider(selectedModel.modelId));
      if (aiSettings.geminiKey != null && aiSettings.geminiKey!.isNotEmpty) {
        fallbackAIService =
            ref.watch(geminiServiceProvider(aiSettings.geminiKey!));
      } else {
        if (aiSettings.openAIKey == null || aiSettings.openAIKey!.isEmpty) {
          throw Exception('OpenAI API key is not set');
        }
        fallbackAIService =
            ref.watch(openaiServiceProvider(selectedModel.modelId));
      }
      break;
    case AIProvider.gemini:
      if (aiSettings.geminiKey == null || aiSettings.geminiKey!.isEmpty) {
        throw Exception('Gemini API key is not set');
      }
      primaryAIService =
          ref.watch(geminiServiceProvider(aiSettings.geminiKey!));
      // Use OpenAI as fallback if available
      if (aiSettings.openAIKey != null && aiSettings.openAIKey!.isNotEmpty) {
        fallbackAIService =
            ref.watch(openaiServiceProvider(selectedModel.modelId));
      } else {
        fallbackAIService =
            primaryAIService; // Use Gemini as fallback if no OpenAI key
      }
      break;
    default:
      throw Exception('No AI provider selected');
  }

  final logger = Logger();
  logger.d(
      'AIServiceManager initialized with primary: ${primaryAIService.runtimeType}, fallback: ${fallbackAIService.runtimeType}');

  return AIServiceManager(primaryAIService, fallbackAIService, usersService);
});
