// lib/services/ai/ai_settings_service.dart
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/services/ai/ai_keys_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alphanessone/models/ai_keys_model.dart';
import 'package:logger/logger.dart';

enum AIProvider {
  openAI('OpenAI'),
  gemini('Google Gemini'),
  claude('Claude'),
  azureOpenAI('Azure OpenAI');

  final String displayName;
  const AIProvider(this.displayName);
}

enum AIModel {
  gpt4o('gpt-4o', AIProvider.openAI),
  geminiPro('gemini-pro', AIProvider.gemini),
  geminiFlash('gemini-2.0-flash-exp', AIProvider.gemini),
  geminiThinking('gemini-2.0-flash-thinking-exp-1219', AIProvider.gemini),
  claude3Sonnet('claude-3-sonnet-20240229', AIProvider.claude),
  azureGPT4('gpt-4', AIProvider.azureOpenAI),
  azureGPT35('gpt-35-turbo', AIProvider.azureOpenAI);

  final String modelId;
  final AIProvider provider;
  const AIModel(this.modelId, this.provider);
}

class AISettings {
  final AIKeysModel? keys;
  final AIModel selectedModel;
  final AIProvider selectedProvider;

  AISettings({
    this.keys,
    required this.selectedModel,
    required this.selectedProvider,
  });

  bool hasKeyForProvider(AIProvider provider) {
    if (keys == null) return false;

    switch (provider) {
      case AIProvider.openAI:
        return keys!.getEffectiveKey('openai') != null;
      case AIProvider.gemini:
        return keys!.getEffectiveKey('gemini') != null;
      case AIProvider.claude:
        return keys!.getEffectiveKey('claude') != null;
      case AIProvider.azureOpenAI:
        return keys!.getEffectiveKey('azure') != null &&
            keys!.getEffectiveKey('azure_endpoint') != null;
    }
  }

  List<AIProvider> get availableProviders => AIProvider.values
      .where((provider) => hasKeyForProvider(provider))
      .toList();

  List<AIModel> get availableModels => AIModel.values
      .where((model) => hasKeyForProvider(model.provider))
      .toList();

  String? getKeyForProvider(AIProvider provider) {
    if (keys == null) return null;

    switch (provider) {
      case AIProvider.openAI:
        return keys!.getEffectiveKey('openai');
      case AIProvider.gemini:
        return keys!.getEffectiveKey('gemini');
      case AIProvider.claude:
        return keys!.getEffectiveKey('claude');
      case AIProvider.azureOpenAI:
        return keys!.getEffectiveKey('azure');
    }
  }

  String? get azureEndpoint => keys?.getEffectiveKey('azure_endpoint');

  AISettings copyWith({
    AIKeysModel? keys,
    AIModel? selectedModel,
    AIProvider? selectedProvider,
  }) {
    return AISettings(
      keys: keys ?? this.keys,
      selectedModel: selectedModel ?? this.selectedModel,
      selectedProvider: selectedProvider ?? this.selectedProvider,
    );
  }
}

class AISettingsService {
  static const _keyPrefix = 'ai_settings_';
  final SharedPreferences? _prefs;

  AISettingsService(this._prefs);

  Future<void> saveSettings(AISettings settings) async {
    if (_prefs == null) return;
    await _prefs.setString(
        '${_keyPrefix}selected_model', settings.selectedModel.name);
    await _prefs.setString(
        '${_keyPrefix}selected_provider', settings.selectedProvider.name);
  }

  AISettings loadSettings({AIKeysModel? keys}) {
    if (_prefs == null) {
      return AISettings(
        keys: keys,
        selectedModel: AIModel.gpt4o,
        selectedProvider: AIProvider.openAI,
      );
    }

    final settings = AISettings(
      keys: keys,
      selectedModel: AIModel.values.firstWhere(
        (model) =>
            model.name == _prefs.getString('${_keyPrefix}selected_model'),
        orElse: () => AIModel.gpt4o,
      ),
      selectedProvider: AIProvider.values.firstWhere(
        (provider) =>
            provider.name == _prefs.getString('${_keyPrefix}selected_provider'),
        orElse: () => AIProvider.openAI,
      ),
    );

    // Validate and adjust selected provider and model
    final availableProviders = settings.availableProviders;
    AIProvider provider = settings.selectedProvider;
    if (!availableProviders.contains(provider)) {
      provider = availableProviders.isNotEmpty
          ? availableProviders.first
          : AIProvider.openAI;
    }

    final availableModels =
        AIModel.values.where((model) => model.provider == provider).toList();
    AIModel model;
    final savedModelName = _prefs.getString('${_keyPrefix}selected_model');
    if (availableModels.any((m) => m.name == savedModelName)) {
      model = availableModels.firstWhere((m) => m.name == savedModelName);
    } else {
      model =
          availableModels.isNotEmpty ? availableModels.first : AIModel.gpt4o;
    }

    return settings.copyWith(
      selectedProvider: provider,
      selectedModel: model,
    );
  }
}

final aiSettingsServiceProvider = Provider<AISettingsService>((ref) {
  final sharedPreferencesAsync = ref.watch(sharedPreferencesProvider);
  return sharedPreferencesAsync.when(
    data: (sharedPreferences) => AISettingsService(sharedPreferences),
    loading: () =>
        AISettingsService(null), // Provide a default or handle loading state
    error: (error, stackTrace) {
      Logger().e('Error loading shared preferences: $error');
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

class AISettingsNotifier extends StateNotifier<AISettings> {
  final AISettingsService _service;

  AISettingsNotifier(this._service, AIKeysModel? keys)
      : super(_service.loadSettings(keys: keys));

  Future<void> updateSelectedModel(AIModel model) async {
    state = state.copyWith(
      selectedModel: model,
      selectedProvider: model.provider,
    );
    await _service.saveSettings(state);
  }

  Future<void> updateSelectedProvider(AIProvider provider) async {
    // Trova il primo modello disponibile per il nuovo provider
    final availableModels =
        AIModel.values.where((model) => model.provider == provider).toList();

    if (availableModels.isNotEmpty) {
      state = state.copyWith(
        selectedProvider: provider,
        selectedModel: availableModels.first,
      );
      await _service.saveSettings(state);
    }
  }

  void updateKeys(AIKeysModel? keys) {
    final availableProviders = AIProvider.values
        .where(
            (provider) => keys?.getEffectiveKey(_getKeyType(provider)) != null)
        .toList();

    if (availableProviders.isNotEmpty) {
      // Se il provider corrente non è disponibile, seleziona il primo disponibile
      if (!availableProviders.contains(state.selectedProvider)) {
        final newProvider = availableProviders.first;
        final availableModels = AIModel.values
            .where((model) => model.provider == newProvider)
            .toList();

        state = state.copyWith(
          keys: keys,
          selectedProvider: newProvider,
          selectedModel: availableModels.isNotEmpty
              ? availableModels.first
              : state.selectedModel,
        );
      } else {
        state = state.copyWith(keys: keys);
      }
    } else {
      state = state.copyWith(
        keys: keys,
        selectedProvider: AIProvider.openAI,
        selectedModel: AIModel.gpt4o,
      );
    }
  }

  String _getKeyType(AIProvider provider) {
    switch (provider) {
      case AIProvider.openAI:
        return 'openai';
      case AIProvider.gemini:
        return 'gemini';
      case AIProvider.claude:
        return 'claude';
      case AIProvider.azureOpenAI:
        return 'azure';
    }
  }
}
