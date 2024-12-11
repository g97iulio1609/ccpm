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

  // Regex precompilate
  static final RegExp _phoneRegex = RegExp(
    r'(?:telefono|numero|phone|number)[:\s]*(?:in\s)?(?:3\d{8,9}|\+39\d{10}|\d{10})',
    caseSensitive: false,
  );

  static final RegExp _dateRegex = RegExp(
    r'(?:birth(?:day|date)|nascita|compleanno|dob)\s*[:|=]\s*(\d{4}-\d{2}-\d{2})',
    caseSensitive: false,
  );

  static final RegExp _heightRegex = RegExp(
    r'(?:height|altezza)\s*[:|=]\s*(\d+(?:\.\d+)?)\s*(?:cm)?',
    caseSensitive: false,
  );

  static final RegExp _activityRegex = RegExp(
    r'(?:activity|attività)\s*(?:level|livello)?\s*[:|=]\s*(sedentary|light|moderate|very active|extremely active|sedentario|leggero|moderato|molto attivo|estremamente attivo)',
    caseSensitive: false,
  );

  // Altre regex per massimali
  static final List<RegExp> _maxRMUpdatePatterns = [
    RegExp(
      r'(?:aggiorna|update|set|imposta).*?massimale.*?(?:di|per|of)?\s*[:-]?\s*([\w\s]+?)(?:\s*[-:])?\s*(?:a|to)?\s*(\d+)\s*(?:kg|kgs|chili)?\s*(?:x|per|con|reps?|ripetizioni)?\s*(\d+)',
      caseSensitive: false,
    ),
    RegExp(
      r'([\w\s]+?)\s*[:]\s*(\d+)\s*(?:kg|kgs|chili)?\s*(?:x|per|con)\s*(\d+)',
      caseSensitive: false,
    ),
    RegExp(
      r'(?:ho fatto|faccio|fatto)\s+([\w\s]+?)\s+(?:con|a|per|di)\s+(\d+)\s*(?:kg|kgs|chili)?\s*(?:x|per|con|reps?|ripetizioni)?\s*(\d+)',
      caseSensitive: false,
    ),
    RegExp(
      r'(?:il mio|nuovo|)\s*massimale\s+(?:di|per|del)?\s*([\w\s]+?)\s+(?:è|e|a)?\s*(\d+)\s*(?:kg|kgs|chili)?\s*(?:x|per|con|reps?|ripetizioni)?\s*(\d+)',
      caseSensitive: false,
    ),
  ];

  static final List<RegExp> _maxRMQueryPatterns = [
    RegExp(r'qual[ie] .*massimal[ei] .*(?:di|per)? (.*?)\??$',
        caseSensitive: false),
    RegExp(r'massimal[ei] (?:di|per|del) ([\w\s]+)', caseSensitive: false),
    RegExp(r'dimmi (?:il|i) massimal[ei] (?:di|per|del) ([\w\s]+)',
        caseSensitive: false),
    RegExp(
        r'(?:voglio|vorrei) sapere (?:il|i) massimal[ei] (?:di|per|del) ([\w\s]+)',
        caseSensitive: false),
  ];

  static final RegExp _updateMassimalRegex = RegExp(
    r'modifica massimale (?:di|per) (.*?) a (\d+)kg(?: x| con) (\d+) (?:rep|reps|ripetizioni)',
    caseSensitive: false,
  );

  static final RegExp _deleteMassimalRegex = RegExp(
    r'elimina (?:il )?massimale (?:di|per) (.*)',
    caseSensitive: false,
  );

  /// Estrae le informazioni dell'utente per visualizzazione
  String getUserInfo(UserModel user, String field) {
    switch (field.toLowerCase()) {
      case 'phone':
      case 'phonenumber':
      case 'telefono':
      case 'numero di telefono':
        return user.phoneNumber ?? 'Numero di telefono non impostato';
      case 'height':
      case 'altezza':
        return user.height != null
            ? '${user.height} cm'
            : 'Altezza non impostata';
      case 'birthdate':
      case 'data di nascita':
      case 'compleanno':
        return user.birthdate?.toString().split(' ')[0] ??
            'Data di nascita non impostata';
      case 'activity':
      case 'activitylevel':
      case 'livello di attività':
        return user.activityLevel != null
            ? _activityLevelToString(user.activityLevel!)
            : 'Livello di attività non impostato';
      default:
        return 'Informazione non disponibile';
    }
  }

  String _activityLevelToString(double level) {
    if (level < 1.5) return 'Sedentario';
    if (level < 3.0) return 'Leggero';
    if (level < 4.5) return 'Moderato';
    if (level < 6.0) return 'Molto attivo';
    return 'Estremamente attivo';
  }

  /// Analizza gli aggiornamenti del profilo dalla risposta dell'AI
  Map<String, dynamic>? parseProfileUpdates(String aiResponse) {
    final updates = <String, dynamic>{};
    bool hasUpdates = false;

    // Numero di telefono
    final phoneMatch = _phoneRegex.firstMatch(aiResponse);
    if (phoneMatch != null) {
      String phone = phoneMatch.group(0)!.replaceAll(RegExp(r'[^\d+]'), '');
      if (!phone.startsWith('+39') && phone.startsWith('3')) {
        phone = '+39$phone';
      } else if (phone.startsWith('3')) {
        phone = '+39$phone';
      }
      updates['phoneNumber'] = phone;
      hasUpdates = true;
    }

    // Data di nascita
    final dateMatch = _dateRegex.firstMatch(aiResponse);
    if (dateMatch != null) {
      final dateStr = dateMatch.group(1)?.trim();
      if (dateStr != null) {
        try {
          final date = DateTime.parse(dateStr);
          updates['birthdate'] = Timestamp.fromDate(date);
          hasUpdates = true;
        } catch (e) {
          throw Exception('Formato data non valido. Usa YYYY-MM-DD');
        }
      }
    }

    // Altezza
    final heightMatch = _heightRegex.firstMatch(aiResponse);
    if (heightMatch != null) {
      final heightStr = heightMatch.group(1)?.trim();
      if (heightStr != null) {
        final height = double.tryParse(heightStr);
        if (height == null || height < 50 || height > 250) {
          throw Exception(
              'Altezza non valida. Inserisci un valore tra 50 e 250 cm');
        }
        updates['height'] = height;
        hasUpdates = true;
      }
    }

    // Livello di attività
    final activityMatch = _activityRegex.firstMatch(aiResponse);
    if (activityMatch != null) {
      updates['activityLevel'] =
          _stringToActivityLevel(activityMatch.group(1)!);
      hasUpdates = true;
    }

    return hasUpdates ? updates : null;
  }

  double _stringToActivityLevel(String level) {
    switch (level.toLowerCase()) {
      case 'sedentary':
      case 'sedentario':
        return 1.0;
      case 'light':
      case 'leggero':
        return 2.5;
      case 'moderate':
      case 'moderato':
        return 3.5;
      case 'very active':
      case 'molto attivo':
        return 5.0;
      case 'extremely active':
      case 'estremamente attivo':
        return 6.0;
      default:
        return 3.0; // Default a moderato
    }
  }

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

  /// Gestisce le query sui massimali
  Future<String?> handleMaxRMQuery(String message, String userId) async {
    for (var regex in _maxRMQueryPatterns) {
      final match = regex.firstMatch(message.toLowerCase());
      if (match != null) {
        final exerciseName = match.group(1)?.trim();
        if (exerciseName != null && exerciseName.isNotEmpty) {
          // Ottieni il massimale dell'esercizio
          final maxRM = await getExerciseMaxRM(exerciseName, userId);
          if (maxRM != null) {
            return maxRM['message'] as String?;
          } else {
            return 'Non ho trovato nessun massimale per l\'esercizio "$exerciseName".';
          }
        }
      }
    }

    return 'La tua richiesta non è chiara. Per favore, riformula la domanda.';
  }

  /// Gestisce le operazioni sui massimali come lista, modifica ed eliminazione
  Future<String?> handleMaxRMOperations(String message, String userId) async {
    final lowerMessage = message.toLowerCase();

    // Lista di tutti i massimali
    if (lowerMessage.contains('lista dei massimali') ||
        lowerMessage.contains('tutti i massimali')) {
      // Recupera tutti i record dall'utente
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

    // Modifica massimale
    final updateMatch = _updateMassimalRegex.firstMatch(message);
    if (updateMatch != null) {
      final exerciseName = updateMatch.group(1)!.trim();
      final newWeight = int.parse(updateMatch.group(2)!);
      final newReps = int.parse(updateMatch.group(3)!);

      final exerciseId = await findExerciseId(exerciseName);
      if (exerciseId == null) return 'Esercizio non trovato: $exerciseName';

      final recordsQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('exercises')
          .doc(exerciseId)
          .collection('records')
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (recordsQuery.docs.isEmpty) {
        return 'Nessun massimale trovato da modificare per $exerciseName';
      }

      final latestRecord =
          ExerciseRecord.fromFirestore(recordsQuery.docs.first);
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('exercises')
          .doc(exerciseId)
          .collection('records')
          .doc(latestRecord.id)
          .update({
        'maxWeight': newWeight,
        'repetitions': newReps,
        'date': Timestamp.fromDate(DateTime.now()),
      });

      return 'Ho aggiornato il massimale di $exerciseName a ${newWeight}kg x $newReps reps';
    }

    // Elimina massimale
    final deleteMatch = _deleteMassimalRegex.firstMatch(message);
    if (deleteMatch != null) {
      final exerciseName = deleteMatch.group(1)!.trim();

      final exerciseId = await findExerciseId(exerciseName);
      if (exerciseId == null) return 'Esercizio non trovato: $exerciseName';

      final recordsQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('exercises')
          .doc(exerciseId)
          .collection('records')
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (recordsQuery.docs.isEmpty) {
        return 'Nessun massimale trovato da eliminare per $exerciseName';
      }

      final latestRecord =
          ExerciseRecord.fromFirestore(recordsQuery.docs.first);
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('exercises')
          .doc(exerciseId)
          .collection('records')
          .doc(latestRecord.id)
          .delete();

      return 'Ho eliminato il massimale più recente di $exerciseName';
    }

    // Query singolo massimale
    return await handleMaxRMQuery(message, userId);
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
    final exerciseRecordService = ref.watch(exerciseRecordServiceProvider);
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

        // Interpreta il messaggio usando l'AI
        final interpretation =
            await aiService.interpretMaxRMMessage(messageText);
        if (interpretation != null) {
          switch (interpretation['type']) {
            case 'update':
              final exerciseName = interpretation['exercise'] as String;
              final maxWeight = interpretation['weight'] as num;
              final repetitions = interpretation['reps'] as int;

              final exerciseId =
                  await aiChatService.findExerciseId(exerciseName);
              if (exerciseId == null) {
                chatNotifier.addMessage(ChatMessage(
                  role: 'assistant',
                  content:
                      'Non ho trovato l\'esercizio "$exerciseName" nel database. Verifica il nome e riprova.',
                ));
                final result =
                    await aiChatService.getExerciseMaxRM(exerciseName, userId);
                _logger.d('Exercise record result: $result');

                if (result != null) {
                  chatNotifier.addMessage(ChatMessage(
                    role: 'assistant',
                    content: result['message'] as String,
                  ));
                  return;
                } else {
                  _logger.w('No exercise record found for: $exerciseName');
                  chatNotifier.addMessage(ChatMessage(
                    role: 'assistant',
                    content:
                        'Non ho trovato nessun record per l\'esercizio "$exerciseName".',
                  ));
                  return;
                }
              }

              // Se l'esercizio esiste, aggiorna il massimale aggiungendo un nuovo record
              final newRecord = ExerciseRecord(
                id: '', // L'ID verrà assegnato automaticamente da Firestore
                exerciseId: exerciseId,
                maxWeight: maxWeight,
                repetitions: repetitions,
                date: DateTime.now(),
              );

              final newRecordRef = await aiChatService._firestore
                  .collection('users')
                  .doc(userId)
                  .collection('exercises')
                  .doc(exerciseId)
                  .collection('records')
                  .add(newRecord.toMap());

              if (newRecordRef.id.isNotEmpty) {
                chatNotifier.addMessage(ChatMessage(
                  role: 'assistant',
                  content:
                      'Ho aggiornato il massimale di $exerciseName a ${maxWeight}kg x $repetitions reps.',
                ));
              } else {
                chatNotifier.addMessage(ChatMessage(
                  role: 'assistant',
                  content:
                      'C\'è stato un problema nell\'aggiornamento del massimale.',
                ));
              }
              isProcessing.value = false;
              return;

            case 'query':
              final exerciseName = interpretation['exercise'] as String;
              _logger.d('Processing query for exercise: $exerciseName');

              // Recupera il massimale dal database
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
              final records = interpretation['records'] as List<dynamic>;
              final formattedRecords = records.map((record) {
                final recordMap = record as Map<String, dynamic>;
                return '**${recordMap['exercise']}**: ${recordMap['weight']}kg x ${recordMap['reps']} reps _(${recordMap['date']})_';
              }).join('\n');
              chatNotifier.addMessage(ChatMessage(
                role: 'assistant',
                content:
                    '**Ecco i tuoi massimali più recenti:**\n$formattedRecords',
              ));
              isProcessing.value = false;
              return;

            case 'error':
              final errorMessage = interpretation['error_message'] as String;
              chatNotifier.addMessage(ChatMessage(
                role: 'assistant',
                content: errorMessage,
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
