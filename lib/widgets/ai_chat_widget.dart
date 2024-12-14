// ai_chat_widget.dart
import 'package:alphanessone/services/users_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import 'dart:convert';

import '../services/ai/ai_settings_service.dart';
import '../services/ai/AIServices.dart';

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
  final Map<String, dynamic>? interpretation; // Per messaggi dell'assistente

  ChatMessage({
    required this.role,
    required this.content,
    this.interpretation,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}

class AIChatWidget extends HookConsumerWidget {
  const AIChatWidget({
    super.key,
    required this.userService,
  });

  final UsersService userService;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(aiSettingsProvider);
    final chatMessages = ref.watch(chatMessagesProvider);
    final chatNotifier = ref.watch(chatMessagesProvider.notifier);
    final aiService = ref.watch(aiServiceManagerProvider);
    final isProcessing = useState(false);
    final logger = useMemoized(() => Logger(
          printer: PrettyPrinter(
            methodCount: 0,
            errorMethodCount: 5,
            lineLength: 50,
            colors: true,
            printEmojis: true,
            dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
          ),
        ));

    if (settings.availableProviders.isEmpty) {
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
        body: const _APIKeyWarning(),
      );
    }

    /// Processa la risposta dell'AI e gestisce l'interpretazione
    Future<void> processAIResponse(String messageText) async {
      try {
        final userId = userService.getCurrentUserId();
        final user = await userService.getUserById(userId);
        if (user == null) throw Exception('Utente non trovato');

        // 1. Ottieni l'interpretazione dalla risposta AI
        Map<String, dynamic>? interpretation;
        try {
          interpretation = jsonDecode(messageText);
        } catch (e) {
          logger.w('Failed to parse AI response as JSON: $e');
        }

        String finalResponse;

        if (interpretation != null) {
          // 2. Se è un'interpretazione valida, esegui l'azione appropriata
          final featureType = interpretation['featureType'];
          if (featureType != null && featureType != 'other') {
            final result =
                await aiService.handleUserQuery(messageText, context: {
              'userProfile': user.toMap(),
              'chatHistory': chatMessages
                  .map((msg) => {'role': msg.role, 'content': msg.content})
                  .toList(),
            });
            finalResponse = result;
          } else {
            // Usa responseText se disponibile
            finalResponse = interpretation['responseText'] ?? messageText;
          }
        } else {
          // 3. Se non è un'interpretazione valida, usa il testo come risposta
          finalResponse = messageText;
        }

        // 4. Aggiungi il messaggio alla chat
        chatNotifier.addMessage(ChatMessage(
          role: 'assistant',
          content: finalResponse,
          interpretation: interpretation,
        ));
      } catch (e, stackTrace) {
        logger.e('Errore durante il processing della risposta AI',
            error: e, stackTrace: stackTrace);
        chatNotifier.addMessage(ChatMessage(
          role: 'assistant',
          content: 'Si è verificato un errore: ${e.toString()}',
        ));
      }
    }

    /// Invia un messaggio nella chat
    Future<void> sendMessage(String messageText) async {
      if (messageText.isEmpty || isProcessing.value) return;

      final settings = ref.read(aiSettingsProvider);
      if (settings.availableProviders.isEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Configurazione Richiesta'),
            content: const Text(
                'Per utilizzare l\'assistente AI, è necessario configurare almeno una chiave API nelle impostazioni.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annulla'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/settings/ai');
                },
                child: const Text('Configura'),
              ),
            ],
          ),
        );
        return;
      }

      isProcessing.value = true;
      try {
        // 1. Aggiungi il messaggio dell'utente
        chatNotifier.addMessage(ChatMessage(
          role: 'user',
          content: messageText,
        ));

        // 2. Ottieni il contesto
        final userId = userService.getCurrentUserId();
        final user = await userService.getUserById(userId);
        if (user == null) throw Exception('Utente non trovato');

        // 3. Ottieni la risposta dall'AI
        final response = await aiService.handleUserQuery(
          messageText,
          context: {
            'userProfile': user.toMap(),
            'chatHistory': chatMessages
                .map((msg) => {'role': msg.role, 'content': msg.content})
                .toList(),
          },
        );

        // 4. Processa la risposta
        await processAIResponse(response);
      } catch (e, stackTrace) {
        logger.e('Errore durante l\'invio del messaggio',
            error: e, stackTrace: stackTrace);
        chatNotifier.addMessage(ChatMessage(
          role: 'assistant',
          content: 'Si è verificato un errore: ${e.toString()}',
        ));
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
                ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: chatMessages.length,
                  itemBuilder: (context, index) {
                    final message = chatMessages[index];
                    return _ChatMessageBubble(message: message);
                  },
                ),
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

class _ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    // Estrai il testo naturale dal JSON se presente
    String displayText = message.content;
    if (message.isAssistant) {
      try {
        final Map<String, dynamic> jsonResponse = jsonDecode(message.content);
        displayText = jsonResponse['responseText'] ?? message.content;
      } catch (e) {
        // Se non è JSON valido, usa il testo originale
        displayText = message.content;
      }
    }

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        decoration: BoxDecoration(
          color: message.isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Text(
          displayText,
          style: TextStyle(
            color: message.isUser
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
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
    final availableProviders = settings.availableProviders;
    final availableModels = settings.availableModels
        .where((model) => model.provider == settings.selectedProvider)
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withAlpha(26),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<AIProvider>(
              value: availableProviders.contains(settings.selectedProvider)
                  ? settings.selectedProvider
                  : availableProviders.isNotEmpty
                      ? availableProviders.first
                      : null,
              decoration: const InputDecoration(
                labelText: 'AI Provider',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              items: availableProviders.map((provider) {
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
              value: availableModels.contains(settings.selectedModel)
                  ? settings.selectedModel
                  : availableModels.isNotEmpty
                      ? availableModels.first
                      : null,
              decoration: const InputDecoration(
                labelText: 'Model',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              items: availableModels.map((model) {
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
            color: Theme.of(context).colorScheme.outline.withAlpha(26),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withAlpha(26),
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
