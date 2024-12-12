import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../services/ai/ai_settings_service.dart';

class AISettingsScreen extends HookConsumerWidget {
  const AISettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(aiSettingsProvider);
    final settingsNotifier = ref.read(aiSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModelSelection(context, settings, settingsNotifier),
            const SizedBox(height: 24),
            _buildAPIKeySection(context, settings, settingsNotifier),
          ],
        ),
      ),
    );
  }

  Widget _buildModelSelection(
    BuildContext context,
    AISettings settings,
    AISettingsNotifier notifier,
  ) {
    if (settings.availableModels.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Model',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Text(
                  'Inserisci prima una chiave API valida per visualizzare i modelli disponibili'),
            ],
          ),
        ),
      );
    }

    final currentModel =
        settings.availableModels.contains(settings.selectedModel)
            ? settings.selectedModel
            : settings.availableModels.first;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Model',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AIModel>(
              value: currentModel,
              decoration: const InputDecoration(
                labelText: 'Select Model',
                border: OutlineInputBorder(),
              ),
              items: settings.availableModels.map((model) {
                return DropdownMenuItem(
                  value: model,
                  child:
                      Text('${model.modelId} (${model.provider.displayName})'),
                );
              }).toList(),
              onChanged: (model) {
                if (model != null) {
                  notifier.updateSelectedModel(model);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAPIKeySection(
    BuildContext context,
    AISettings settings,
    AISettingsNotifier notifier,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'API Keys',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildAPIKeyField(
              label: 'OpenAI API Key',
              value: settings.openAIKey,
              onChanged: notifier.updateOpenAIKey,
              context: context,
              helpText:
                  'Get your API key from https://platform.openai.com/api-keys',
            ),
            const SizedBox(height: 16),
            _buildAPIKeyField(
              label: 'Google Gemini API Key',
              value: settings.geminiKey,
              onChanged: notifier.updateGeminiKey,
              context: context,
              helpText: 'Get your API key from https://ai.google.dev/',
            ),
            const SizedBox(height: 16),
            _buildAPIKeyField(
              label: 'Claude API Key',
              value: settings.claudeKey,
              onChanged: notifier.updateClaudeKey,
              context: context,
              helpText:
                  'Get your API key from https://console.anthropic.com/settings/keys',
            ),
            const SizedBox(height: 16),
            _buildAPIKeyField(
              label: 'Azure OpenAI API Key',
              value: settings.azureKey,
              onChanged: notifier.updateAzureKey,
              context: context,
              helpText:
                  'Get your API key from your Azure OpenAI resource in the Azure Portal.',
            ),
            const SizedBox(height: 16),
            _buildAPIKeyField(
              label: 'Azure OpenAI Endpoint',
              value: settings.azureEndpoint,
              onChanged: notifier.updateAzureEndpoint,
              context: context,
              isEndpoint: true,
              helpText:
                  'Get your Endpoint from your Azure OpenAI resource in the Azure Portal.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAPIKeyField({
    required String label,
    required String? value,
    required Function(String) onChanged,
    required BuildContext context,
    bool isEndpoint = false,
    String? helpText,
  }) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.help_outline),
          onPressed: () {
            if (helpText != null) {
              _showHelpDialog(context, label, helpText);
            }
          },
        ),
      ),
      obscureText: !isEndpoint,
      onChanged: onChanged,
    );
  }

  void _showHelpDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
