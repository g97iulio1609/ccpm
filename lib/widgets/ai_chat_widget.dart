// ai_chat_widget.dart
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/services/users_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

import '../models/user_model.dart';
import '../services/ai/ai_settings_service.dart';
import '../services/ai/training_ai_service.dart';
import '../services/ai/extensions/ai_extension.dart';
import '../services/ai/extensions/maxrm_extension.dart';
import '../services/ai/extensions/profile_extension.dart';

/// Stato dei messaggi di chat
final chatMessagesProvider =
    StateNotifierProvider<ChatMessagesNotifier, List<ChatMessage>>(
  (ref) => ChatMessagesNotifier(),
);

/// Notifier per gestire i messaggi di chat
class ChatMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  ChatMessagesNotifier() : super([]);

  void addMessage(ChatMessage message) {
    state = [...state, message];
  }

  void clearMessages() {
    state = [];
  }
}

/// Modello per un messaggio di chat
class ChatMessage {
  final String role; // 'user' o 'assistant'
  final String content;

  ChatMessage({required this.role, required this.content});
}

class AIChatWidget extends HookConsumerWidget {
  AIChatWidget({
    super.key,
    required this.userService,
  });

  final UsersService userService;
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  // Estensioni caricate
  final List<AIExtension> _extensions = [
    MaxRMExtension(),
    ProfileExtension(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(aiSettingsProvider);
    final chatMessages = ref.watch(chatMessagesProvider);
    final chatNotifier = ref.read(chatMessagesProvider.notifier);
    final aiService = ref.watch(trainingAIServiceProvider);
    final isProcessing = useState(false);

    /// Funzione ausiliaria per gestire un'interpretazione
    Future<bool> tryHandleInterpretation(Map<String, dynamic>? interpretation,
        String userId, UserModel user) async {
      if (interpretation == null) {
        return false;
      }

      final featureType = interpretation['featureType'];
      if (featureType == null) return false;

      for (final ext in _extensions) {
        if (await ext.canHandle(interpretation)) {
          final response = await ext.handle(interpretation, userId, user);
          if (response == null) {
            // Non gestito dall'estensione, fallback all'AI
            return false;
          }
          chatNotifier
              .addMessage(ChatMessage(role: 'assistant', content: response));
          return true;
        }
      }

      return false;
    }

    /// Invia un messaggio nella chat
    Future<void> sendMessage(String messageText) async {
      if (messageText.isEmpty || isProcessing.value) return;

      isProcessing.value = true;
      try {
        chatNotifier
            .addMessage(ChatMessage(role: 'user', content: messageText));

        final userId = userService.getCurrentUserId();
        final user = await userService.getUserById(userId);
        if (user == null) throw Exception('Utente non trovato');

        // 1. Interpretazione della domanda
        Map<String, dynamic>? interpretation =
            await aiService.interpretMessage(messageText, context: {
          'userProfile': user.toMap(),
          'chatHistory': chatMessages
              .map((msg) => {'role': msg.role, 'content': msg.content})
              .toList(),
        });

        // Se non riesce, prova con l'altro provider (fallback)
        if (interpretation == null ||
            interpretation['featureType'] == 'error') {
          interpretation = await aiService
              .interpretMessageWithFallback(messageText, context: {
            'userProfile': user.toMap(),
            'chatHistory': chatMessages
                .map((msg) => {'role': msg.role, 'content': msg.content})
                .toList(),
          });
        }

        bool handled = false;
        final featureType = interpretation?['featureType'];

        // 2. Verifica caso noto
        if (interpretation != null &&
            featureType != null &&
            featureType != 'other' &&
            featureType != 'error') {
          handled = await tryHandleInterpretation(interpretation, userId, user);
        } else {
          // Non caso noto
          Map<String, dynamic>? fallbackInterpretation = await aiService
              .handleNonStandardQuery(messageText, user, chatMessages);

          // Se non riesce prova con l'altro provider
          if (fallbackInterpretation == null ||
              fallbackInterpretation['featureType'] == 'error') {
            fallbackInterpretation =
                await aiService.handleNonStandardQueryWithFallback(
                    messageText, user, chatMessages);
          }

          if (fallbackInterpretation != null) {
            handled = await tryHandleInterpretation(
                fallbackInterpretation, userId, user);

            if (!handled) {
              final response = fallbackInterpretation['responseText'];
              if (response != null && response is String) {
                chatNotifier.addMessage(
                    ChatMessage(role: 'assistant', content: response));
                handled = true;
              }
            }
          }
        }

        // 3. Se ancora non gestito, fallback su risposta generica
        if (!handled) {
          Map<String, dynamic> profileData = user.toMap();
          // Converti i campi Timestamp in stringhe ISO
          profileData.updateAll((key, value) {
            if (value is Timestamp) {
              return value.toDate().toIso8601String();
            }
            return value;
          });

          String response = await aiService
              .processNaturalLanguageQuery(messageText, context: {
            'userProfile': profileData,
            'chatHistory': chatMessages
                .map((msg) => {'role': msg.role, 'content': msg.content})
                .toList(),
          });

          // Se la risposta è nulla o in errore, prova con il fallback
          if (response.isEmpty || response.contains('"featureType":"error"')) {
            response = await aiService.processNaturalLanguageQueryWithFallback(
              messageText,
              context: {
                'userProfile': profileData,
                'chatHistory': chatMessages
                    .map((msg) => {'role': msg.role, 'content': msg.content})
                    .toList(),
              },
            );
          }

          chatNotifier
              .addMessage(ChatMessage(role: 'assistant', content: response));
        }
      } catch (e, stackTrace) {
        _logger.e('Errore durante l\'invio del messaggio',
            error: e, stackTrace: stackTrace);
        chatNotifier.addMessage(ChatMessage(
          role: 'assistant',
          content: '**Errore:** ${e.toString()}',
        ));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: ${e.toString()}')),
        );
      } finally {
        isProcessing.value = false;
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
          if (settings.availableProviders.isNotEmpty) ...[
            const _AISettingsSelector(),
          ] else ...[
            const _APIKeyWarning(),
          ],
          Expanded(
            child: Stack(
              children: [
                const _ChatMessagesList(),
                if (isProcessing.value)
                  const Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
          if (settings.availableProviders.isNotEmpty)
            _ChatInputField(onSend: sendMessage),
        ],
      ),
    );
  }
}

/// Widget per la selezione del provider e del modello AI
class _AISettingsSelector extends ConsumerWidget {
  const _AISettingsSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(aiSettingsProvider);

    return Container(
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
                  ref
                      .read(aiSettingsProvider.notifier)
                      .updateSelectedProvider(provider);
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
                  .where((model) => model.provider == settings.selectedProvider)
                  .map((model) {
                return DropdownMenuItem(
                  value: model,
                  child: Text(model.modelId),
                );
              }).toList(),
              onChanged: (model) {
                if (model != null) {
                  ref
                      .read(aiSettingsProvider.notifier)
                      .updateSelectedModel(model);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget per avviso mancanza chiavi API
class _APIKeyWarning extends StatelessWidget {
  const _APIKeyWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
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
              'Nessuna chiave API configurata. Per favore, aggiungi le tue chiavi API nelle impostazioni.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.go('/settings/ai'),
            child: const Text('Configura'),
          ),
        ],
      ),
    );
  }
}

/// Widget per la lista dei messaggi di chat
class _ChatMessagesList extends ConsumerWidget {
  const _ChatMessagesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatMessages = ref.watch(chatMessagesProvider);

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.all(16),
      itemCount: chatMessages.length,
      itemBuilder: (context, index) {
        final message = chatMessages[chatMessages.length - 1 - index];
        final isUser = message.role == 'user';

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
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
                      color:
                          Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Markdown(
                  data: message.content,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      color: isUser
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                    ),
                    listBullet: TextStyle(
                      color: isUser
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    code: TextStyle(
                      backgroundColor: isUser
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      color: isUser
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: isUser
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Widget per il campo di input dei messaggi
class _ChatInputField extends HookConsumerWidget {
  final Function(String) onSend;

  const _ChatInputField({
    required this.onSend,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textController = useTextEditingController();
    final focusNode = useFocusNode();

    return Container(
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
              focusNode: focusNode,
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: 'Scrivi un messaggio...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onSubmitted: (value) {
                onSend(value);
                textController.clear();
                focusNode.requestFocus();
              },
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              onSend(textController.text);
              textController.clear();
              focusNode.requestFocus();
            },
          ),
        ],
      ),
    );
  }
}
