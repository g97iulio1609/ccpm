import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../services/ai/ai_settings_service.dart';

class AISettingsScreen extends HookConsumerWidget {
  const AISettingsScreen({Key? key}) : super(key: key);

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
              value: settings.selectedModel,
              decoration: const InputDecoration(
                labelText: 'Select Model',
                border: OutlineInputBorder(),
              ),
              items: AIModel.values.map((model) {
                return DropdownMenuItem(
                  value: model,
                  child: Text(model.name),
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
            ),
            const SizedBox(height: 16),
            _buildAPIKeyField(
              label: 'Google Gemini API Key',
              value: settings.geminiKey,
              onChanged: notifier.updateGeminiKey,
            ),
            const SizedBox(height: 16),
            _buildAPIKeyField(
              label: 'Claude API Key',
              value: settings.claudeKey,
              onChanged: notifier.updateClaudeKey,
            ),
            const SizedBox(height: 16),
            _buildAPIKeyField(
              label: 'Azure OpenAI API Key',
              value: settings.azureKey,
              onChanged: notifier.updateAzureKey,
            ),
            const SizedBox(height: 16),
            _buildAPIKeyField(
              label: 'Azure OpenAI Endpoint',
              value: settings.azureEndpoint,
              onChanged: notifier.updateAzureEndpoint,
              isEndpoint: true,
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
    bool isEndpoint = false,
  }) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.help_outline),
          onPressed: () {
            // TODO: Show help dialog with information about where to get the API key
          },
        ),
      ),
      obscureText: !isEndpoint,
      onChanged: onChanged,
    );
  }
}
