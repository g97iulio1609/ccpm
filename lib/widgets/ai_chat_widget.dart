import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/services/profile/profile_update_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/ai/ai_settings_service.dart';
import '../services/ai/training_ai_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../ExerciseRecords/exercise_record_services.dart';
import 'package:alphanessone/services/users_services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AIChatWidget extends HookConsumerWidget {
  const AIChatWidget({
    super.key,
    required this.userService,
  });

  final UsersService userService;

  // Helper method to extract user info for display
  String _getUserInfo(UserModel user, String field) {
    switch (field.toLowerCase()) {
      case 'phone':
      case 'phonenumber':
      case 'telefono':
      case 'numero di telefono':
        return user.phoneNumber ?? 'Numero di telefono non impostato';
      case 'height':
      case 'altezza':
        return user.height != null ? '${user.height} cm' : 'Altezza non impostata';
      case 'birthdate':
      case 'data di nascita':
      case 'compleanno':
        return user.birthdate?.toString().split(' ')[0] ?? 'Data di nascita non impostata';
      case 'activity':
      case 'activitylevel':
      case 'livello di attività':
        return user.activityLevel != null ? user.activityLevel!.toStringAsFixed(2) : 'Livello di attività non impostato';
      default:
        return 'Informazione non disponibile';
    }
  }

  // Helper method to parse profile updates from AI response
  Map<String, dynamic>? _parseProfileUpdates(String aiResponse) {
    final updates = <String, dynamic>{};
    bool hasUpdates = false;

    // Parse phone number - improved regex to catch more variations
    final phoneMatch = RegExp(r'(?:telefono|numero|phone|number)[:\s]*(?:in\s)?(?:3\d{8,9}|\+39\d{10}|\d{10})').firstMatch(aiResponse);
    if (phoneMatch != null) {
      String phone = phoneMatch.group(0)!.replaceAll(RegExp(r'[^\d+]'), '');
      if (!phone.startsWith('+39') && !phone.startsWith('3')) {
        phone = '+39$phone';
      } else if (phone.startsWith('3')) {
        phone = '+39$phone';
      }
      updates['phoneNumber'] = phone;
      hasUpdates = true;
    }

    // Parse birthdate
    final dateMatch = RegExp(r'(?:birth(?:day|date)|nascita|compleanno|dob)\s*[:|=]\s*(\d{4}-\d{2}-\d{2})').firstMatch(aiResponse);
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

    // Parse height
    final heightMatch = RegExp(r'(?:height|altezza)\s*[:|=]\s*(\d+(?:\.\d+)?)\s*(?:cm)?').firstMatch(aiResponse);
    if (heightMatch != null) {
      final heightStr = heightMatch.group(1)?.trim();
      if (heightStr != null) {
        final height = double.tryParse(heightStr);
        if (height == null || height < 50 || height > 250) {
          throw Exception('Altezza non valida. Inserisci un valore tra 50 e 250 cm');
        }
        updates['height'] = height;
        hasUpdates = true;
      }
    }

    // Parse activity level
    final activityMatch = RegExp(r'(?:activity|attività)\s*(?:level|livello)?\s*[:|=]\s*(sedentary|light|moderate|very active|extremely active|sedentario|leggero|moderato|molto attivo|estremamente attivo)', 
      caseSensitive: false).firstMatch(aiResponse);
    if (activityMatch != null) {
      updates['activityLevel'] = activityMatch.group(1)?.toLowerCase().trim();
      hasUpdates = true;
    }

    return hasUpdates ? updates : null;
  }

  // Helper method to parse max RM updates from AI response
  Future<Map<String, Map<String, dynamic>>?> _parseMaxRMUpdates(String message) async {
    debugPrint('Parsing message: $message');
    final regex = RegExp(r'Aggiorna il mio massimale - exercise: (.*?) - max weight: (\d+)kg, reps: (\d+)');
    final match = regex.firstMatch(message);
    
    if (match != null) {
      final exerciseName = match.group(1)!;
      final maxWeight = int.parse(match.group(2)!);
      final repetitions = int.parse(match.group(3)!);
      
      debugPrint('Parsed values - name: $exerciseName, weight: $maxWeight, reps: $repetitions');
      
      // Query Firestore to get the exercise ID
      final exerciseQuery = await FirebaseFirestore.instance
          .collection('exercises')
          .where('name', isEqualTo: exerciseName)
          .get();
          
      debugPrint('Query result size: ${exerciseQuery.docs.length}');
          
      if (exerciseQuery.docs.isEmpty) {
        debugPrint('Exercise not found: $exerciseName');
        return null;
      }
      
      final exerciseDoc = exerciseQuery.docs.first;
      final exerciseId = exerciseDoc.id;
      debugPrint('Found exercise - ID: $exerciseId, Name: ${exerciseDoc.data()['name']}');
      
      final result = {
        exerciseId: {
          'maxWeight': maxWeight,
          'repetitions': repetitions,
          'date': DateTime.now().toIso8601String(),
          'exerciseName': exerciseName,
        }
      };
      
      debugPrint('Returning result: $result');
      return result;
    }
    
    debugPrint('No match found in message');
    return null;
  }

  Future<String?> _findExerciseId(String exerciseName) async {
    final exerciseQuery = await FirebaseFirestore.instance
        .collection('exercises')
        .where('name', isEqualTo: exerciseName)
        .get();
        
    if (exerciseQuery.docs.isEmpty) {
      debugPrint('Exercise not found: $exerciseName');
      return null;
    }
    
    return exerciseQuery.docs.first.id;
  }

  Future<Map<String, dynamic>?> _getExerciseMaxRM(String exerciseName) async {
    final exerciseId = await _findExerciseId(exerciseName);
    if (exerciseId == null) return null;

    final userId = await userService.getCurrentUserId();
    if (userId == null) return null;

    final recordsQuery = await FirebaseFirestore.instance
        .collection('records')
        .where('userId', isEqualTo: userId)
        .where('exerciseId', isEqualTo: exerciseId)
        .orderBy('date', descending: true)
        .limit(1)
        .get();

    if (recordsQuery.docs.isEmpty) {
      return {'message': 'Non ho trovato nessun massimale registrato per $exerciseName'};
    }

    final record = recordsQuery.docs.first.data();
    return {
      'message': 'Il tuo massimale più recente per $exerciseName è: ${record['maxWeight']}kg x ${record['repetitions']} ripetizioni (${record['date']})'
    };
  }

  Future<String?> _handleMaxRMQuery(String message) async {
    final regex = RegExp(r'qual[ie] .*massimal[ei] .*(?:di|per)? (.*?)\??$', caseSensitive: false);
    final match = regex.firstMatch(message);
    
    if (match != null) {
      final exerciseName = match.group(1)?.trim();
      if (exerciseName != null) {
        debugPrint('Cercando massimale per: $exerciseName');
        final result = await _getExerciseMaxRM(exerciseName);
        return result?['message'];
      }
    }
    return null;
  }

  Future<String?> _handleMaxRMOperations(String message) async {
    // Lista di tutti i massimali
    if (message.toLowerCase().contains('lista dei massimali') || 
        message.toLowerCase().contains('tutti i massimali')) {
      final userId = await userService.getCurrentUserId();
      if (userId == null) return null;

      final recordsQuery = await FirebaseFirestore.instance
          .collection('records')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();

      if (recordsQuery.docs.isEmpty) {
        return 'Non hai ancora registrato nessun massimale.';
      }

      // Raggruppa i record per esercizio
      final recordsByExercise = <String, List<Map<String, dynamic>>>{};
      for (var doc in recordsQuery.docs) {
        final data = doc.data();
        final exerciseName = data['exerciseName'] as String;
        recordsByExercise.putIfAbsent(exerciseName, () => []).add({
          ...data,
          'id': doc.id,
        });
      }

      // Crea il messaggio di risposta
      final buffer = StringBuffer('Ecco i tuoi massimali più recenti:\n\n');
      for (var entry in recordsByExercise.entries) {
        final latestRecord = entry.value.first;
        buffer.writeln('${entry.key}: ${latestRecord['maxWeight']}kg x ${latestRecord['repetitions']} reps (${latestRecord['date']})');
      }
      return buffer.toString();
    }

    // Modifica massimale
    final updateRegex = RegExp(r'modifica massimale (?:di|per) (.*?) a (\d+)kg(?: x| con) (\d+) (?:rep|reps|ripetizioni)', caseSensitive: false);
    final updateMatch = updateRegex.firstMatch(message);
    if (updateMatch != null) {
      final exerciseName = updateMatch.group(1)!;
      final newWeight = int.parse(updateMatch.group(2)!);
      final newReps = int.parse(updateMatch.group(3)!);

      // Trova l'ultimo record
      final exerciseId = await _findExerciseId(exerciseName);
      if (exerciseId == null) return 'Esercizio non trovato: $exerciseName';

      final userId = await userService.getCurrentUserId();
      if (userId == null) return null;

      final latestRecord = await FirebaseFirestore.instance
          .collection('records')
          .where('userId', isEqualTo: userId)
          .where('exerciseId', isEqualTo: exerciseId)
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (latestRecord.docs.isEmpty) {
        return 'Nessun massimale trovato da modificare per $exerciseName';
      }

      // Aggiorna il record
      await FirebaseFirestore.instance
          .collection('records')
          .doc(latestRecord.docs.first.id)
          .update({
            'maxWeight': newWeight,
            'repetitions': newReps,
            'date': DateTime.now().toIso8601String(),
          });

      return 'Ho aggiornato il massimale di $exerciseName a ${newWeight}kg x $newReps reps';
    }

    // Elimina massimale
    final deleteRegex = RegExp(r'elimina (?:il )?massimale (?:di|per) (.*)', caseSensitive: false);
    final deleteMatch = deleteRegex.firstMatch(message);
    if (deleteMatch != null) {
      final exerciseName = deleteMatch.group(1)!;
      
      final exerciseId = await _findExerciseId(exerciseName);
      if (exerciseId == null) return 'Esercizio non trovato: $exerciseName';

      final userId = await userService.getCurrentUserId();
      if (userId == null) return null;

      final latestRecord = await FirebaseFirestore.instance
          .collection('records')
          .where('userId', isEqualTo: userId)
          .where('exerciseId', isEqualTo: exerciseId)
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (latestRecord.docs.isEmpty) {
        return 'Nessun massimale trovato da eliminare per $exerciseName';
      }

      // Elimina il record
      await FirebaseFirestore.instance
          .collection('records')
          .doc(latestRecord.docs.first.id)
          .delete();

      return 'Ho eliminato il massimale più recente di $exerciseName';
    }

    // Query singolo massimale (già implementato)
    return _handleMaxRMQuery(message);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(aiSettingsProvider);
    final textController = TextEditingController();
    final messages = ValueNotifier<List<Map<String, String>>>([]);
    final aiService = ref.watch(trainingAIServiceProvider);
    final exerciseRecordService = ref.watch(exerciseRecordServiceProvider);

    Future<void> sendMessage(String messageText) async {
      try {
        // First check for max RM operations
        final maxRMResponse = await _handleMaxRMOperations(messageText);
        if (maxRMResponse != null) {
          messages.value = [
            ...messages.value,
            {'role': 'assistant', 'content': maxRMResponse}
          ];
          return;
        }

        // Then check for max RM updates
        final maxRMUpdates = await _parseMaxRMUpdates(messageText);
        debugPrint('Parsed max RM updates: $maxRMUpdates');
        if (maxRMUpdates != null && maxRMUpdates.isNotEmpty) {
          // Get current user data
          final userId = userService.getCurrentUserId();
          debugPrint('User ID from service: $userId');
          
          if (userId.isEmpty) {
            throw Exception('User ID is empty');
          }
          
          // Update each exercise max RM
          final List<String> updatesList = [];
          for (final entry in maxRMUpdates.entries) {
            final exerciseId = entry.key;
            final data = entry.value as Map<String, dynamic>;
            
            debugPrint('Processing exercise: $exerciseId with data: $data');
            
            await exerciseRecordService.addExerciseRecord(
              userId: userId,
              exerciseId: exerciseId,
              exerciseName: data['exerciseName'] as String,
              maxWeight: data['maxWeight'] as num,
              repetitions: data['repetitions'] as int,
              date: data['date'] as String,
            );
            
            updatesList.add('- ${data['exerciseName']}: ${data['maxWeight']}kg x ${data['repetitions']} reps');
          }
          
          final updateMessage = 'Ho aggiornato i seguenti massimali:\n${updatesList.join('\n')}';
          messages.value = [
            ...messages.value,
            {'role': 'assistant', 'content': updateMessage.trim()}
          ];
          return;
        }

        // Add user message to chat
        messages.value = [
          ...messages.value,
          {'role': 'user', 'content': messageText}
        ];
        textController.clear();

        // Get current user data
        final userId = userService.getCurrentUserId();
        final user = await userService.getUserById(userId);
        if (user == null) throw Exception('Utente non trovato');

        // Check for profile update intent
        final updates = _parseProfileUpdates(messageText);
        if (updates != null && updates.isNotEmpty) {
          // Use ProfileUpdateService to update the profile
          final profileService = ref.read(profileUpdateServiceProvider);
          await profileService.updateProfile(updates);
          
          // Format the update message based on what was changed
          final List<String> updatesList = [];
          if (updates.containsKey('phoneNumber')) {
            updatesList.add('- Numero di telefono: ${updates['phoneNumber']}');
          }
          if (updates.containsKey('height')) {
            updatesList.add('- Altezza: ${updates['height']} cm');
          }
          if (updates.containsKey('birthdate')) {
            updatesList.add('- Data di nascita: ${updates['birthdate']}');
          }
          if (updates.containsKey('activityLevel')) {
            updatesList.add('- Livello di attività: ${updates['activityLevel']}');
          }
          
          final updateMessage = 'Ho aggiornato i seguenti dati:\n${updatesList.join('\n')}';
          messages.value = [
            ...messages.value,
            {'role': 'assistant', 'content': updateMessage.trim()}
          ];
          return;
        }

        // Process user query about profile info
        if (messageText.toLowerCase().contains('numero') || 
            messageText.toLowerCase().contains('telefono')) {
          final phoneInfo = _getUserInfo(user, 'phone');
          messages.value = [
            ...messages.value,
            {'role': 'assistant', 'content': 'Il tuo numero di telefono è: $phoneInfo'}
          ];
          return;
        }

        // Get current user's profile
        final userProfile = await userService.getUserById(userId);
        if (userProfile == null) {
          throw Exception('Profilo utente non trovato');
        }

        // Check if this is an info request
        if (messageText.contains('qual è') || messageText.contains('qual e') || messageText.contains('dimmi') || 
            messageText.contains('mostrami') || messageText.contains('visualizza')) {
          // Extract the requested field
          String? requestedField;
          if (messageText.contains('telefono')) requestedField = 'telefono';
          else if (messageText.contains('altezza')) requestedField = 'altezza';
          else if (messageText.contains('nascita')) requestedField = 'data di nascita';
          else if (messageText.contains('attività')) requestedField = 'livello di attività';

          if (requestedField != null) {
            final info = _getUserInfo(userProfile, requestedField);
            messages.value = [
              ...messages.value,
              {'role': 'assistant', 'content': info}
            ];
            return;
          }
        }

        Map<String, dynamic> profileData = userProfile.toMap();
        
        // Convert Timestamp fields to ISO string format for AI processing
        if (profileData.containsKey('birthdate') && profileData['birthdate'] is Timestamp) {
          profileData['birthdate'] = (profileData['birthdate'] as Timestamp).toDate().toIso8601String();
        }
        profileData.forEach((key, value) {
          if (value is Timestamp) {
            profileData[key] = value.toDate().toIso8601String();
          }
        });

        // Include chat history in the context
        final chatHistory = messages.value.map((m) => {
          'role': m['role'],
          'content': m['content'],
        }).toList();

        final response = await aiService.processNaturalLanguageQuery(
          messageText,
          context: {
            'userProfile': profileData,
            'chatHistory': chatHistory,
            'exercises': [], // Actual exercises will be fetched from Firestore
            'trainingProgram': {}, // TODO: Add actual training program
          },
        );

        final aiMaxRMUpdates = await _parseMaxRMUpdates(response);
        if (aiMaxRMUpdates != null && aiMaxRMUpdates.isNotEmpty) {
          final userId = profileData['id'] as String?;
          debugPrint('User ID: $userId');
          
          if (userId == null) {
            throw Exception('User ID is null');
          }
          
          // Update each exercise max RM
          final List<String> updatesList = [];
          for (final entry in aiMaxRMUpdates.entries) {
            final exerciseId = entry.key;
            final data = entry.value as Map<String, dynamic>;
            
            debugPrint('Processing exercise: $exerciseId with data: $data');
            
            await exerciseRecordService.addExerciseRecord(
              userId: userId,
              exerciseId: exerciseId,
              exerciseName: data['exerciseName'] as String,
              maxWeight: data['maxWeight'] as num,
              repetitions: data['repetitions'] as int,
              date: data['date'] as String,
            );
            
            updatesList.add('- ${data['exerciseName']}: ${data['maxWeight']}kg x ${data['repetitions']} reps');
          }
          
          final updateMessage = 'Ho aggiornato i seguenti massimali:\n${updatesList.join('\n')}';
          messages.value = [
            ...messages.value,
            {'role': 'assistant', 'content': updateMessage.trim()}
          ];
          return;
        }
        
        // Then check for profile updates in the AI response
        final profileUpdates = _parseProfileUpdates(response);
        if (profileUpdates != null && profileUpdates.isNotEmpty) {
          final profileService = ref.read(profileUpdateServiceProvider);
          await profileService.updateProfile(profileUpdates);
          
          // Format the update message based on what was changed
          final List<String> updatesList = [];
          if (profileUpdates.containsKey('phoneNumber')) {
            updatesList.add('- Numero di telefono: ${profileUpdates['phoneNumber']}');
          }
          if (profileUpdates.containsKey('height')) {
            updatesList.add('- Altezza: ${profileUpdates['height']} cm');
          }
          if (profileUpdates.containsKey('birthdate')) {
            updatesList.add('- Data di nascita: ${profileUpdates['birthdate']}');
          }
          if (profileUpdates.containsKey('activityLevel')) {
            updatesList.add('- Livello di attività: ${profileUpdates['activityLevel']}');
          }
          
          final updateMessage = 'Ho aggiornato i seguenti dati:\n${updatesList.join('\n')}';
          messages.value = [
            ...messages.value,
            {'role': 'assistant', 'content': updateMessage.trim()}
          ];
          return;
        } else {
          messages.value = [
            ...messages.value,
            {'role': 'assistant', 'content': response}
          ];
        }
      } catch (e) {
        messages.value = [
          ...messages.value,
          {'role': 'assistant', 'content': 'Errore: $e'}
        ];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
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
                          ref.read(aiSettingsProvider.notifier).updateSelectedProvider(provider);
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
                          ref.read(aiSettingsProvider.notifier).updateSelectedModel(model);
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
                      onSubmitted: (_) => sendMessage(_.trim()),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () => sendMessage(textController.text.trim()),
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
