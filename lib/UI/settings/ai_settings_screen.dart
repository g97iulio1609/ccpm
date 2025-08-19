import 'package:alphanessone/models/ai_keys_model.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:alphanessone/providers/theme_provider.dart';
import '../../services/ai/ai_settings_service.dart';
import '../../services/ai/ai_keys_service.dart';
import '../../providers/auth_providers.dart';
import 'package:alphanessone/providers/ui_settings_provider.dart';

class AISettingsScreen extends HookConsumerWidget {
  const AISettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(aiSettingsProvider);
    final settingsNotifier = ref.read(aiSettingsProvider.notifier);
    final aiKeysService = ref.watch(aiKeysServiceProvider);
    final aiKeys = ref.watch(aiKeysStreamProvider).value;
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThemeSection(context, ref),
            const SizedBox(height: 16),
            _buildGlassToggle(context, ref),
            const SizedBox(height: 24),
            _buildModelSelection(context, settings, settingsNotifier),
            const SizedBox(height: 24),
            _buildAPIKeySection(
              context,
              settings,
              aiKeysService,
              aiKeys,
              isAdmin,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appThemeModeProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tema', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SegmentedButton<ThemeMode>(
              segments: const <ButtonSegment<ThemeMode>>[
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('Sistema'),
                  icon: Icon(Icons.brightness_auto),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Chiaro'),
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Scuro'),
                  icon: Icon(Icons.dark_mode),
                ),
              ],
              selected: <ThemeMode>{themeMode},
              onSelectionChanged: (values) {
                final selected = values.first;
                ref.read(appThemeModeProvider.notifier).setThemeMode(selected);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassToggle(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(uiGlassEnabledProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.blur_on),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tema Glass “lite”',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Abilita un effetto vetro leggero su superfici selezionate',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Switch(
              value: enabled,
              onChanged: (v) =>
                  ref.read(uiGlassEnabledProvider.notifier).setEnabled(v),
            ),
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
            Text('Modello AI', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<AIProvider>(
              value: settings.selectedProvider,
              decoration: const InputDecoration(
                labelText: 'Provider AI',
                border: OutlineInputBorder(),
              ),
              items: settings.availableProviders.map((provider) {
                return DropdownMenuItem(
                  value: provider,
                  child: Text(provider.displayName),
                );
              }).toList(),
              onChanged: (provider) {
                if (provider != null) {
                  notifier.updateSelectedProvider(provider);
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AIModel>(
              value: settings.selectedModel,
              decoration: const InputDecoration(
                labelText: 'Modello',
                border: OutlineInputBorder(),
              ),
              items: AIModel.values
                  .where((model) => model.provider == settings.selectedProvider)
                  .map((model) {
                    return DropdownMenuItem(
                      value: model,
                      child: Text(model.modelId),
                    );
                  })
                  .toList(),
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
    AIKeysService aiKeysService,
    AIKeysModel? aiKeys,
    bool isAdmin,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chiavi API', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (isAdmin) ...[
              Text(
                'Chiavi di Default',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _buildAPIKeyField(
                label: 'OpenAI API Key (Default)',
                value: aiKeys?.defaultOpenAIKey,
                onChanged: (value) =>
                    aiKeysService.updateDefaultKeys(openAIKey: value),
                context: context,
                helpText:
                    'Ottieni la tua API key da https://platform.openai.com/api-keys',
              ),
              const SizedBox(height: 16),
              _buildAPIKeyField(
                label: 'Google Gemini API Key (Default)',
                value: aiKeys?.defaultGeminiKey,
                onChanged: (value) =>
                    aiKeysService.updateDefaultKeys(geminiKey: value),
                context: context,
                helpText: 'Ottieni la tua API key da https://ai.google.dev/',
              ),
              const SizedBox(height: 16),
              _buildAPIKeyField(
                label: 'Claude API Key (Default)',
                value: aiKeys?.defaultClaudeKey,
                onChanged: (value) =>
                    aiKeysService.updateDefaultKeys(claudeKey: value),
                context: context,
                helpText:
                    'Ottieni la tua API key da https://console.anthropic.com/settings/keys',
              ),
              const SizedBox(height: 16),
              _buildAPIKeyField(
                label: 'Azure OpenAI API Key (Default)',
                value: aiKeys?.defaultAzureKey,
                onChanged: (value) =>
                    aiKeysService.updateDefaultKeys(azureKey: value),
                context: context,
                helpText: 'Ottieni la tua API key dal portale Azure OpenAI.',
              ),
              const SizedBox(height: 16),
              _buildAPIKeyField(
                label: 'Azure OpenAI Endpoint (Default)',
                value: aiKeys?.defaultAzureEndpoint,
                onChanged: (value) =>
                    aiKeysService.updateDefaultKeys(azureEndpoint: value),
                context: context,
                isEndpoint: true,
                helpText: 'Ottieni il tuo endpoint dal portale Azure OpenAI.',
              ),
              const Divider(height: 32),
            ],
            Text(
              'Chiavi Personali',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildAPIKeyField(
              label: 'OpenAI API Key (Personale)',
              value: aiKeys?.personalOpenAIKey,
              onChanged: (value) =>
                  aiKeysService.updatePersonalKeys(openAIKey: value),
              context: context,
              helpText:
                  'Ottieni la tua API key da https://platform.openai.com/api-keys',
            ),
            const SizedBox(height: 16),
            _buildAPIKeyField(
              label: 'Google Gemini API Key (Personale)',
              value: aiKeys?.personalGeminiKey,
              onChanged: (value) =>
                  aiKeysService.updatePersonalKeys(geminiKey: value),
              context: context,
              helpText: 'Ottieni la tua API key da https://ai.google.dev/',
            ),
            const SizedBox(height: 16),
            _buildAPIKeyField(
              label: 'Claude API Key (Personale)',
              value: aiKeys?.personalClaudeKey,
              onChanged: (value) =>
                  aiKeysService.updatePersonalKeys(claudeKey: value),
              context: context,
              helpText:
                  'Ottieni la tua API key da https://console.anthropic.com/settings/keys',
            ),
            const SizedBox(height: 16),
            _buildAPIKeyField(
              label: 'Azure OpenAI API Key (Personale)',
              value: aiKeys?.personalAzureKey,
              onChanged: (value) =>
                  aiKeysService.updatePersonalKeys(azureKey: value),
              context: context,
              helpText: 'Ottieni la tua API key dal portale Azure OpenAI.',
            ),
            const SizedBox(height: 16),
            _buildAPIKeyField(
              label: 'Azure OpenAI Endpoint (Personale)',
              value: aiKeys?.personalAzureEndpoint,
              onChanged: (value) =>
                  aiKeysService.updatePersonalKeys(azureEndpoint: value),
              context: context,
              isEndpoint: true,
              helpText: 'Ottieni il tuo endpoint dal portale Azure OpenAI.',
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
          scrollable: true,
          insetPadding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
          ),
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
