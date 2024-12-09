import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/ai/ai_settings_service.dart';
import '../services/ai/training_ai_service.dart';
import '../Main/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AIChatWidget extends HookConsumerWidget {
  const AIChatWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(aiSettingsProvider);
    final settingsNotifier = ref.read(aiSettingsProvider.notifier);
    final textController = TextEditingController();
    final messages = ValueNotifier<List<Map<String, String>>>([]);
    final aiService = ref.watch(trainingAIServiceProvider);

    void sendMessage() async {
      if (textController.text.isEmpty) return;

      final query = textController.text;
      messages.value = [
        ...messages.value,
        {'role': 'user', 'content': query}
      ];
      textController.clear();

      try {
        // Fetch current user's profile
        final currentUser = FirebaseAuth.instance.currentUser;
        Map<String, dynamic> userProfile = {};
        
        if (currentUser != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();
          
          userProfile = Map<String, dynamic>.from(userDoc.data() ?? {});
          
          // Convert Timestamp fields to ISO string format
          if (userProfile.containsKey('birthdate') && userProfile['birthdate'] is Timestamp) {
            userProfile['birthdate'] = (userProfile['birthdate'] as Timestamp).toDate().toIso8601String();
          }
          // Convert any other timestamp fields if present
          userProfile.forEach((key, value) {
            if (value is Timestamp) {
              userProfile[key] = value.toDate().toIso8601String();
            }
          });
        }

        final response = await aiService.processTrainingQuery(
          query,
          userProfile: userProfile,
          exercises: [], // TODO: Add actual exercises
          trainingProgram: {}, // TODO: Add actual training program
        );

        messages.value = [
          ...messages.value,
          {'role': 'assistant', 'content': response}
        ];
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings/ai'),
          ),
        ],
      ),
      body: Column(
        children: [
          // AI Provider and Model Selection
          if (settings.availableProviders.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<AIProvider>(
                      value: settings.selectedProvider,
                      decoration: const InputDecoration(
                        labelText: 'AI Provider',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: settings.availableProviders.map((provider) {
                        return DropdownMenuItem(
                          value: provider,
                          child: Text(provider.displayName),
                        );
                      }).toList(),
                      onChanged: (provider) {
                        if (provider != null) {
                          settingsNotifier.updateSelectedProvider(provider);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<AIModel>(
                      value: settings.selectedModel,
                      decoration: const InputDecoration(
                        labelText: 'Model',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: settings.availableModels
                          .where((model) => 
                              model.provider == settings.selectedProvider)
                          .map((model) {
                        return DropdownMenuItem(
                          value: model,
                          child: Text(model.modelId),
                        );
                      }).toList(),
                      onChanged: (model) {
                        if (model != null) {
                          settingsNotifier.updateSelectedModel(model);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'No API keys configured. Please add your API keys in the settings.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/settings/ai'),
                    child: const Text('Configure'),
                  ),
                ],
              ),
            ),
          ],
          
          // Chat Messages
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: messages,
              builder: (context, List<Map<String, String>> messageList, _) {
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messageList.length,
                  itemBuilder: (context, index) {
                    final message = messageList[messageList.length - 1 - index];
                    final isUser = message['role'] == 'user';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: isUser
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          Container(
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .shadow
                                      .withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              message['content'] ?? '',
                              style: TextStyle(
                                color: isUser
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message Input
          if (settings.availableProviders.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: textController,
                      decoration: InputDecoration(
                        hintText: 'Ask about your training...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => sendMessage(),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: sendMessage,
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
