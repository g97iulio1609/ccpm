// ai_chat_widget.dart
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/services/users_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import 'dart:convert';

import '../services/ai/ai_settings_service.dart';
import '../services/ai/ai_services.dart';

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

  ChatMessage({required this.role, required this.content, this.interpretation});

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}

class AIChatWidget extends HookConsumerWidget {
  const AIChatWidget({super.key, required this.userService});

  final UsersService userService;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(aiSettingsProvider);
    final chatMessages = ref.watch(chatMessagesProvider);
    final chatNotifier = ref.watch(chatMessagesProvider.notifier);
    final aiServiceAsync = ref.watch(aiServiceManagerProvider);
    final isProcessing = useState(false);
    final logger = useMemoized(
      () => Logger(
        printer: PrettyPrinter(
          methodCount: 0,
          errorMethodCount: 5,
          lineLength: 50,
          colors: true,
          printEmojis: true,
          dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
        ),
      ),
    );

    if (settings.availableProviders.isEmpty) {
      return const Scaffold(body: _APIKeyWarning());
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
            final result = await aiServiceAsync.handleUserQuery(
              messageText,
              context: {
                'userProfile': user.toMap(),
                'chatHistory': chatMessages
                    .map((msg) => {'role': msg.role, 'content': msg.content})
                    .toList(),
              },
            );
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
        chatNotifier.addMessage(
          ChatMessage(
            role: 'assistant',
            content: finalResponse,
            interpretation: interpretation,
          ),
        );
      } catch (e, stackTrace) {
        logger.e(
          'Errore durante il processing della risposta AI',
          error: e,
          stackTrace: stackTrace,
        );
        chatNotifier.addMessage(
          ChatMessage(
            role: 'assistant',
            content: 'Si è verificato un errore: ${e.toString()}',
          ),
        );
      }
    }

    /// Invia un messaggio nella chat
    Future<void> sendMessage(String messageText) async {
      if (messageText.isEmpty || isProcessing.value) return;

      if (settings.availableProviders.isEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Configurazione Richiesta'),
            content: const Text(
              'Per utilizzare l\'assistente AI, è necessario configurare almeno una chiave API nelle impostazioni.',
            ),
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
        chatNotifier.addMessage(
          ChatMessage(role: 'user', content: messageText),
        );

        // 2. Ottieni il contesto
        final userId = userService.getCurrentUserId();
        final user = await userService.getUserById(userId);
        if (user == null) throw Exception('Utente non trovato');
        final response = await aiServiceAsync.handleUserQuery(
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
        logger.e(
          'Errore durante l\'invio del messaggio',
          error: e,
          stackTrace: stackTrace,
        );
        chatNotifier.addMessage(
          ChatMessage(
            role: 'assistant',
            content: 'Si è verificato un errore: ${e.toString()}',
          ),
        );
      } finally {
        isProcessing.value = false;
      }
    }

    return Scaffold(
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
                  padding: EdgeInsets.symmetric(
                    vertical: AppTheme.spacing.lg,
                    horizontal: AppTheme.spacing.sm,
                  ),
                  itemCount: chatMessages.length,
                  itemBuilder: (context, index) {
                    final message = chatMessages[index];
                    return _ChatMessageBubble(message: message);
                  },
                ),
                if (isProcessing.value)
                  Positioned(
                    bottom: AppTheme.spacing.xl,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing.lg,
                          vertical: AppTheme.spacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radii.full,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).colorScheme.shadow.withAlpha(20),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            SizedBox(width: AppTheme.spacing.md),
                            Text(
                              'Elaborazione...',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                            ),
                          ],
                        ),
                      ),
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
    String displayText = message.content;
    if (message.isAssistant) {
      try {
        final Map<String, dynamic> jsonResponse = jsonDecode(message.content);
        displayText = jsonResponse['responseText'] ?? message.content;
      } catch (e) {
        displayText = message.content;
      }
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: EdgeInsets.symmetric(
          vertical: AppTheme.spacing.sm,
          horizontal: AppTheme.spacing.md,
        ),
        padding: EdgeInsets.all(AppTheme.spacing.md),
        decoration: BoxDecoration(
          color: message.isUser
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(
              message.isUser ? AppTheme.radii.lg : AppTheme.radii.sm,
            ),
            topRight: Radius.circular(
              message.isUser ? AppTheme.radii.sm : AppTheme.radii.lg,
            ),
            bottomLeft: Radius.circular(AppTheme.radii.lg),
            bottomRight: Radius.circular(AppTheme.radii.lg),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withAlpha(26),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SelectableText(
          displayText,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: message.isUser
                ? colorScheme.onPrimary
                : colorScheme.onSurface,
            height: 1.4,
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

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppTheme.radii.xl),
          bottomRight: Radius.circular(AppTheme.radii.xl),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Settings',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppTheme.spacing.md),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  context: context,
                  label: 'Provider',
                  value: availableProviders.contains(settings.selectedProvider)
                      ? settings.selectedProvider
                      : availableProviders.isNotEmpty
                      ? availableProviders.first
                      : null,
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
              SizedBox(width: AppTheme.spacing.md),
              Expanded(
                child: _buildDropdown(
                  context: context,
                  label: 'Model',
                  value: availableModels.contains(settings.selectedModel)
                      ? settings.selectedModel
                      : availableModels.isNotEmpty
                      ? availableModels.first
                      : null,
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
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required BuildContext context,
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radii.md),
        border: Border.all(color: colorScheme.outline.withAlpha(51)),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.primary,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radii.md),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacing.md,
            vertical: AppTheme.spacing.sm,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
        items: items,
        onChanged: onChanged,
        dropdownColor: colorScheme.surfaceContainerHighest,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}

/// Widget per avviso mancanza chiavi API
class _APIKeyWarning extends StatelessWidget {
  const _APIKeyWarning();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.lg),
      margin: EdgeInsets.all(AppTheme.spacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withAlpha(38),
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(color: colorScheme.error.withAlpha(51)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppTheme.spacing.sm),
            decoration: BoxDecoration(
              color: colorScheme.error.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_rounded,
              color: colorScheme.error,
              size: 24,
            ),
          ),
          SizedBox(width: AppTheme.spacing.lg),
          Expanded(
            child: Text(
              'Nessuna chiave API configurata. Per favore, aggiungi le tue chiavi API nelle impostazioni.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.error,
                height: 1.4,
              ),
            ),
          ),
          SizedBox(width: AppTheme.spacing.md),
          FilledButton.tonal(
            onPressed: () => context.go('/settings/ai'),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error.withAlpha(26),
              foregroundColor: colorScheme.error,
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacing.lg,
                vertical: AppTheme.spacing.md,
              ),
            ),
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

  const _ChatInputField({required this.onSend});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textController = useTextEditingController();
    final focusNode = useFocusNode();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radii.xl),
          topRight: Radius.circular(AppTheme.radii.xl),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                border: Border.all(color: colorScheme.outline.withAlpha(51)),
              ),
              child: TextField(
                controller: textController,
                focusNode: focusNode,
                textInputAction: TextInputAction.send,
                maxLines: 4,
                minLines: 1,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Scrivi un messaggio...',
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing.lg,
                    vertical: AppTheme.spacing.md,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    onSend(value);
                    textController.clear();
                    focusNode.requestFocus();
                  }
                },
              ),
            ),
          ),
          SizedBox(width: AppTheme.spacing.md),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(51),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withAlpha(51),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded),
              color: colorScheme.onPrimary,
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  onSend(textController.text);
                  textController.clear();
                  focusNode.requestFocus();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
