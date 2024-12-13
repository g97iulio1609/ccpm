// lib/services/ai/ai_settings_service.dart
import 'package:alphanessone/services/ai/ai_providers.dart';
import 'package:alphanessone/services/ai/ai_service.dart';
import 'package:alphanessone/services/ai/gemini_service.dart';
import 'package:alphanessone/services/ai/openai_service.dart';
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
  gpt4o('gpt-4o', AIProvider.openAI),
  geminiPro('gemini-pro', AIProvider.gemini),
  geminiFlash('gemini-2.0-flash-exp', AIProvider.gemini),
  claude3Sonnet('claude-3-sonnet-20240229', AIProvider.claude),
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
