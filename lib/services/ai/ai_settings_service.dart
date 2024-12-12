import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AIProvider {
  openAI('OpenAI'),
  gemini('Google Gemini'),
  claude('Claude'),
  azureOpenAI('Azure OpenAI');

  final String displayName;
  const AIProvider(this.displayName);
}

enum AIModel {
  // OpenAI Models
  gpt4o('gpt-4o', AIProvider.openAI),

  // Gemini Models
  geminiPro('gemini-pro', AIProvider.gemini),
  geminiFlash('gemini-2.0-flash-exp', AIProvider.gemini),

  // Claude Models
  claude3Sonnet('claude-3-sonnet-20240229', AIProvider.claude),

  // Azure OpenAI Models
  azureGPT4('gpt-4', AIProvider.azureOpenAI),
  azureGPT35('gpt-35-turbo', AIProvider.azureOpenAI);

  final String modelId;
  final AIProvider provider;
  const AIModel(this.modelId, this.provider);
}

class AISettings {
  final String? openAIKey;
  final String? geminiKey;
  final String? claudeKey;
  final String? azureKey;
  final String? azureEndpoint;
  final AIModel selectedModel;
  final AIProvider selectedProvider;

  AISettings({
    this.openAIKey,
    this.geminiKey,
    this.claudeKey,
    this.azureKey,
    this.azureEndpoint,
    required this.selectedModel,
    required this.selectedProvider,
  });

  bool hasKeyForProvider(AIProvider provider) {
    switch (provider) {
      case AIProvider.openAI:
        return openAIKey != null && openAIKey!.isNotEmpty;
      case AIProvider.gemini:
        return geminiKey != null && geminiKey!.isNotEmpty;
      case AIProvider.claude:
        return claudeKey != null && claudeKey!.isNotEmpty;
      case AIProvider.azureOpenAI:
        return azureKey != null &&
            azureKey!.isNotEmpty &&
            azureEndpoint != null &&
            azureEndpoint!.isNotEmpty;
    }
  }

  List<AIProvider> get availableProviders => AIProvider.values
      .where((provider) => hasKeyForProvider(provider))
      .toList();

  List<AIModel> get availableModels => AIModel.values
      .where((model) => hasKeyForProvider(model.provider))
      .toList();

  AISettings copyWith({
    String? openAIKey,
    String? geminiKey,
    String? claudeKey,
    String? azureKey,
    String? azureEndpoint,
    AIModel? selectedModel,
    AIProvider? selectedProvider,
  }) {
    return AISettings(
      openAIKey: openAIKey ?? this.openAIKey,
      geminiKey: geminiKey ?? this.geminiKey,
      claudeKey: claudeKey ?? this.claudeKey,
      azureKey: azureKey ?? this.azureKey,
      azureEndpoint: azureEndpoint ?? this.azureEndpoint,
      selectedModel: selectedModel ?? this.selectedModel,
      selectedProvider: selectedProvider ?? this.selectedProvider,
    );
  }
}

class AISettingsService {
  static const _keyPrefix = 'ai_settings_';
  final SharedPreferences _prefs;

  AISettingsService(this._prefs);

  Future<void> saveSettings(AISettings settings) async {
    await _prefs.setString('${_keyPrefix}openai_key', settings.openAIKey ?? '');
    await _prefs.setString('${_keyPrefix}gemini_key', settings.geminiKey ?? '');
    await _prefs.setString('${_keyPrefix}claude_key', settings.claudeKey ?? '');
    await _prefs.setString('${_keyPrefix}azure_key', settings.azureKey ?? '');
    await _prefs.setString(
        '${_keyPrefix}azure_endpoint', settings.azureEndpoint ?? '');
    await _prefs.setString(
        '${_keyPrefix}selected_model', settings.selectedModel.name);
    await _prefs.setString(
        '${_keyPrefix}selected_provider', settings.selectedProvider.name);
  }

  AISettings loadSettings() {
    final settings = AISettings(
      openAIKey: _prefs.getString('${_keyPrefix}openai_key'),
      geminiKey: _prefs.getString('${_keyPrefix}gemini_key'),
      claudeKey: _prefs.getString('${_keyPrefix}claude_key'),
      azureKey: _prefs.getString('${_keyPrefix}azure_key'),
      azureEndpoint: _prefs.getString('${_keyPrefix}azure_endpoint'),
      selectedModel: AIModel.gpt4o, // Default value, will be updated below
      selectedProvider:
          AIProvider.openAI, // Default value, will be updated below
    );

    // Find the first available provider
    final availableProviders = settings.availableProviders;
    if (availableProviders.isNotEmpty) {
      final savedProvider = _prefs.getString('${_keyPrefix}selected_provider');
      final provider = savedProvider != null
          ? AIProvider.values.firstWhere(
              (p) => p.name == savedProvider,
              orElse: () => availableProviders.first,
            )
          : availableProviders.first;

      // Find available models for the selected provider
      final availableModels =
          AIModel.values.where((model) => model.provider == provider).toList();

      if (availableModels.isNotEmpty) {
        final savedModel = _prefs.getString('${_keyPrefix}selected_model');
        final model = savedModel != null
            ? AIModel.values.firstWhere(
                (m) => m.name == savedModel && m.provider == provider,
                orElse: () => availableModels.first,
              )
            : availableModels.first;

        return settings.copyWith(
          selectedProvider: provider,
          selectedModel: model,
        );
      }
    }

    return settings;
  }
}

final aiSettingsServiceProvider = Provider<AISettingsService>((ref) {
  throw UnimplementedError();
});

final aiSettingsProvider =
    StateNotifierProvider<AISettingsNotifier, AISettings>((ref) {
  final service = ref.watch(aiSettingsServiceProvider);
  return AISettingsNotifier(service);
});

class AISettingsNotifier extends StateNotifier<AISettings> {
  final AISettingsService _service;

  AISettingsNotifier(this._service) : super(_service.loadSettings());

  Future<void> updateOpenAIKey(String key) async {
    state = state.copyWith(openAIKey: key);
    await _service.saveSettings(state);
  }

  Future<void> updateGeminiKey(String key) async {
    state = state.copyWith(geminiKey: key);
    await _service.saveSettings(state);
  }

  Future<void> updateClaudeKey(String key) async {
    state = state.copyWith(claudeKey: key);
    await _service.saveSettings(state);
  }

  Future<void> updateAzureKey(String key) async {
    state = state.copyWith(azureKey: key);
    await _service.saveSettings(state);
  }

  Future<void> updateAzureEndpoint(String endpoint) async {
    state = state.copyWith(azureEndpoint: endpoint);
    await _service.saveSettings(state);
  }

  Future<void> updateSelectedModel(AIModel model) async {
    state = state.copyWith(
      selectedModel: model,
      selectedProvider: model.provider,
    );
    await _service.saveSettings(state);
  }

  Future<void> updateSelectedProvider(AIProvider provider) async {
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
}
