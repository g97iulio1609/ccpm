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
import '../models/exercise_record.dart'; // Importa il modello ExerciseRecord
import '../services/ai/ai_settings_service.dart';
import '../services/ai/training_ai_service.dart';

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

/// Servizio per la logica di chat AI
class AIChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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

  /// Trova l'ID dell'esercizio dato il nome
  Future<String?> findExerciseId(String exerciseName) async {
    // Converti il nome dell'esercizio nel formato corretto
    final formattedName = exerciseName
        .split(' ')
        .map((word) => word.isEmpty
            ? ''
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');

    _logger.d('Searching for exercise: $formattedName');

    try {
      final exerciseQuery = await _firestore
          .collection('exercises')
          .where('name', isEqualTo: formattedName)
          .get();

      _logger.d('Exercise query result size: ${exerciseQuery.docs.length}');

      if (exerciseQuery.docs.isEmpty) {
        _logger.w('Exercise not found: $exerciseName');
        return null;
      }

      final exerciseId = exerciseQuery.docs.first.id;
      _logger.d('Found exercise ID: $exerciseId');
      return exerciseId;
    } catch (e) {
      _logger.e('Error finding exercise: $e');
      return null;
    }
  }

  /// Ottiene il massimale più recente per un esercizio dal percorso users/userId/exercises/exerciseId/records
  Future<Map<String, dynamic>?> getExerciseMaxRM(
      String exerciseName, String userId) async {
    // Converti il nome dell'esercizio nel formato corretto
    final formattedName = exerciseName
        .split(' ')
        .map((word) => word.isEmpty
            ? ''
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');

    final exerciseId = await findExerciseId(formattedName);
    if (exerciseId == null) return null;

    _logger
        .d('Querying records for exercise: $formattedName (ID: $exerciseId)');

    try {
      final recordsQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('exercises')
          .doc(exerciseId)
          .collection('records')
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      _logger.d('Found ${recordsQuery.docs.length} records');

      if (recordsQuery.docs.isEmpty) {
        return {
          'message':
              'Non ho trovato nessun massimale registrato per $formattedName'
        };
      }

      final record = ExerciseRecord.fromFirestore(recordsQuery.docs.first);
      _logger.d('Record data: ${record.toMap()}');

      return {
        'message':
            'Il tuo massimale più recente per $formattedName è: ${record.maxWeight}kg x ${record.repetitions} ripetizioni (${record.date.toIso8601String()})'
      };
    } catch (e) {
      _logger.e('Error querying records: $e');
      return {'message': 'Errore durante la ricerca dei massimali: $e'};
    }
  }

  /// Recupera la lista dei massimali di tutti gli esercizi dell'utente
  Future<String> listAllMaxRMs(String userId) async {
    final exercisesRef =
        _firestore.collection('users').doc(userId).collection('exercises');

    final exercisesSnapshot = await exercisesRef.get();
    if (exercisesSnapshot.docs.isEmpty) {
      return 'Non hai ancora registrato nessun massimale.';
    }

    final buffer = StringBuffer('# I tuoi massimali più recenti\n\n');

    for (var exerciseDoc in exercisesSnapshot.docs) {
      final exerciseId = exerciseDoc.id;
      final exerciseData = exerciseDoc.data();
      final exerciseName = exerciseData['name'] as String;

      // Prendiamo il record più recente
      final recordsQuery = await exercisesRef
          .doc(exerciseId)
          .collection('records')
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (recordsQuery.docs.isNotEmpty) {
        final record = ExerciseRecord.fromFirestore(recordsQuery.docs.first);
        buffer.writeln(
            '- **$exerciseName**: ${record.maxWeight}kg x ${record.repetitions} reps _(${record.date.toIso8601String()})_');
      }
    }

    return buffer.toString();
  }

  /// Aggiunge o aggiorna il massimale di un esercizio
  Future<String> updateExerciseMaxRM(String exerciseName, num maxWeight,
      int repetitions, String userId) async {
    final exerciseId = await findExerciseId(exerciseName);
    if (exerciseId == null) {
      return 'Non ho trovato l\'esercizio "$exerciseName" nel database. Verifica il nome e riprova.';
    }

    final recordId = '${userId}_${DateTime.now().millisecondsSinceEpoch}';
    final recordData = {
      'id': recordId,
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'maxWeight': maxWeight,
      'repetitions': repetitions,
      'date': Timestamp.fromDate(DateTime.now()),
      'userId': userId,
    };

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('exercises')
          .doc(exerciseId)
          .collection('records')
          .doc(recordId)
          .set(recordData);

      return 'Ho aggiornato il massimale di $exerciseName a ${maxWeight}kg x $repetitions reps.';
    } catch (e) {
      return 'C\'è stato un problema nell\'aggiornamento del massimale: $e';
    }
  }
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(aiSettingsProvider);
    final chatMessages = ref.watch(chatMessagesProvider);
    final chatNotifier = ref.read(chatMessagesProvider.notifier);
    final aiService = ref.watch(trainingAIServiceProvider);
    final aiChatService = AIChatService();
    final isProcessing =
        useState(false); // Stato per indicare se è in corso una richiesta

    /// Invia un messaggio nella chat
    Future<void> sendMessage(String messageText) async {
      if (messageText.isEmpty || isProcessing.value) return;

      isProcessing.value = true; // Imposta lo stato di elaborazione

      try {
        // Aggiungi il messaggio dell'utente
        chatNotifier
            .addMessage(ChatMessage(role: 'user', content: messageText));

        // Ottieni i dati dell'utente corrente
        final userId = await userService.getCurrentUserId();
        if (userId == null) throw Exception('Utente non autenticato');
        final user = await userService.getUserById(userId);
        if (user == null) throw Exception('Utente non trovato');

        // Interpreta il messaggio usando l'AI per i massimali
        final interpretation =
            await aiService.interpretMaxRMMessage(messageText);
        if (interpretation != null) {
          switch (interpretation['type']) {
            case 'update':
              final exerciseName = interpretation['exercise'] as String?;
              final maxWeight = interpretation['weight'] as num?;
              final repetitions = interpretation['reps'] as int?;

              if (exerciseName == null ||
                  maxWeight == null ||
                  repetitions == null) {
                chatNotifier.addMessage(ChatMessage(
                  role: 'assistant',
                  content:
                      'Non sono riuscito a determinare i dettagli per l\'aggiornamento del massimale.',
                ));
                isProcessing.value = false;
                return;
              }

              final result = await aiChatService.updateExerciseMaxRM(
                  exerciseName, maxWeight, repetitions, userId);

              chatNotifier.addMessage(ChatMessage(
                role: 'assistant',
                content: result,
              ));
              isProcessing.value = false;
              return;

            case 'query':
              final exerciseName = interpretation['exercise'] as String?;
              if (exerciseName == null) {
                chatNotifier.addMessage(ChatMessage(
                  role: 'assistant',
                  content:
                      'Non sono riuscito a capire di quale esercizio vuoi conoscere il massimale.',
                ));
                isProcessing.value = false;
                return;
              }

              final result =
                  await aiChatService.getExerciseMaxRM(exerciseName, userId);

              if (result == null) {
                chatNotifier.addMessage(ChatMessage(
                  role: 'assistant',
                  content:
                      'Non ho trovato l\'esercizio "$exerciseName" nel database.',
                ));
              } else {
                chatNotifier.addMessage(ChatMessage(
                  role: 'assistant',
                  content: result['message'],
                ));
              }
              isProcessing.value = false;
              return;

            case 'list':
              // Mostra la lista di tutti i massimali dell'utente
              final listResponse = await aiChatService.listAllMaxRMs(userId);
              chatNotifier.addMessage(ChatMessage(
                role: 'assistant',
                content: listResponse,
              ));
              isProcessing.value = false;
              return;

            case 'error':
              final errorMessage = interpretation['error_message'] as String?;
              chatNotifier.addMessage(ChatMessage(
                role: 'assistant',
                content:
                    errorMessage ?? 'Si è verificato un errore sconosciuto.',
              ));
              isProcessing.value = false;
              return;

            default:
              break;
          }
        }

        // Se non è un messaggio sui massimali, procedi con la normale elaborazione
        Map<String, dynamic> profileData = user.toMap();

        // Converti i campi Timestamp in stringhe ISO
        profileData.updateAll((key, value) {
          if (value is Timestamp) {
            return value.toDate().toIso8601String();
          }
          return value;
        });

        final response = await aiService.processNaturalLanguageQuery(
          messageText,
          context: {
            'userProfile': profileData,
            'chatHistory': chatMessages
                .map((msg) => {'role': msg.role, 'content': msg.content})
                .toList(),
          },
        );

        chatNotifier
            .addMessage(ChatMessage(role: 'assistant', content: response));
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
        isProcessing.value = false; // Resetta lo stato di elaborazione
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
          // Selezione del provider e del modello AI
          if (settings.availableProviders.isNotEmpty) ...[
            const _AISettingsSelector(),
          ] else ...[
            const _APIKeyWarning(),
          ],

          // Messaggi di chat
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

          // Input per i messaggi
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
    Key? key,
  }) : super(key: key);

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
