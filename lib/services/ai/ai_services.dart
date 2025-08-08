// lib/services/ai/AIServices.dart
import 'dart:convert';
import 'package:alphanessone/services/ai/ai_providers.dart' as ai_providers;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:alphanessone/models/user_model.dart';
import 'ai_service.dart';
import 'package:alphanessone/services/ai/ai_settings_service.dart';
import 'package:alphanessone/services/users_services.dart';
import 'package:alphanessone/services/ai/extensions_manager.dart';
import '../../providers/providers.dart';

class AIServiceManager {
  final AIService primaryAIService;
  final AIService fallbackAIService;
  final UsersService usersService;
  final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 2, errorMethodCount: 8),
  );
  final ExtensionsManager _extensionsManager = ExtensionsManager();

  AIServiceManager(
    this.primaryAIService,
    this.fallbackAIService,
    this.usersService,
  );

  Future<String> handleUserQuery(
    String message, {
    Map<String, dynamic>? context,
  }) async {
    _logger.i('Handling user query: "$message"');

    try {
      // 1. Ottieni il contesto dell'utente
      final userId = usersService.getCurrentUserId();
      final user = await usersService.getUserById(userId);
      if (user == null) {
        return "Non riesco a recuperare il tuo profilo utente. Prova ad effettuare nuovamente l'accesso.";
      }

      // 2. Prepara il contesto completo
      final fullContext = _prepareContext(context ?? {}, user);

      // 3. Ottieni l'interpretazione dall'AI
      final interpretation = await _getInterpretation(message, fullContext);
      if (interpretation == null) {
        return "Mi dispiace, non ho capito la tua richiesta. Puoi riprovare?";
      }

      _logger.d('AI Interpretation: $interpretation');

      // 4. Gestisci l'azione in base al tipo
      switch (interpretation['featureType']) {
        case 'training':
          return await _handleTrainingAction(interpretation, user);
        case 'maxrm':
          return await _handleMaxRMAction(interpretation, user);
        case 'profile':
          return await _handleProfileAction(interpretation, user);
        case 'other':
          return interpretation['responseText'] ??
              "Mi dispiace, non ho capito. Puoi essere più specifico?";
        default:
          return "Non ho capito che tipo di richiesta vuoi fare. Puoi riprovare?";
      }
    } catch (e, stackTrace) {
      _logger.e('Error handling user query', error: e, stackTrace: stackTrace);
      return "Si è verificato un errore. Puoi riprovare?";
    }
  }

  Future<Map<String, dynamic>?> _getInterpretation(
    String message,
    Map<String, dynamic> context,
  ) async {
    try {
      final response = await primaryAIService.processNaturalLanguageQuery(
        message,
        context: context,
      );

      // Pulisci e parsa la risposta
      final cleanedResponse = response
          .replaceAll(RegExp(r'```(?:json)?\s*'), '')
          .replaceAll('```', '')
          .trim();

      return jsonDecode(cleanedResponse);
    } catch (e) {
      _logger.w('Primary AI failed, trying fallback', error: e);
      try {
        final response = await fallbackAIService.processNaturalLanguageQuery(
          message,
          context: context,
        );

        final cleanedResponse = response
            .replaceAll(RegExp(r'```(?:json)?\s*'), '')
            .replaceAll('```', '')
            .trim();

        return jsonDecode(cleanedResponse);
      } catch (e) {
        _logger.e('Both AI services failed', error: e);
        return null;
      }
    }
  }

  Future<String> _handleTrainingAction(
    Map<String, dynamic> interpretation,
    UserModel user,
  ) async {
    _logger.i('Handling training action: ${interpretation['action']}');

    final result = await _extensionsManager.executeAction(interpretation, user);
    if (result == null || result.isEmpty) {
      return "Mi dispiace, non sono riuscito a completare l'operazione sul programma di allenamento.";
    }

    switch (interpretation['action']) {
      case 'query_program':
        if (interpretation['current'] == true) {
          return 'Ecco il tuo programma di allenamento attuale:\n$result';
        }
        return 'Ecco i tuoi programmi di allenamento:\n$result';
      case 'create_program':
        return 'Ho creato il nuovo programma di allenamento:\n$result';
      case 'update_program':
        return 'Ho aggiornato il programma di allenamento:\n$result';
      case 'delete_program':
        return 'Ho eliminato il programma di allenamento:\n$result';
      default:
        return result;
    }
  }

  Future<String> _handleMaxRMAction(
    Map<String, dynamic> interpretation,
    UserModel user,
  ) async {
    _logger.i('Handling maxRM action: ${interpretation['action']}');

    final result = await _extensionsManager.executeAction(interpretation, user);
    if (result == null || result.isEmpty) {
      return "Mi dispiace, non sono riuscito a completare l'operazione sui massimali.";
    }

    switch (interpretation['action']) {
      case 'query':
        return 'Ecco i tuoi massimali:\n$result';
      case 'update':
        return 'Ho aggiornato il massimale:\n$result';
      case 'calculate':
        return 'Ho calcolato il massimale:\n$result';
      default:
        return result;
    }
  }

  Future<String> _handleProfileAction(
    Map<String, dynamic> interpretation,
    UserModel user,
  ) async {
    _logger.i('Handling profile action: ${interpretation['action']}');

    final result = await _extensionsManager.executeAction(interpretation, user);
    if (result == null || result.isEmpty) {
      return "Mi dispiace, non sono riuscito a completare l'operazione sul profilo.";
    }

    switch (interpretation['action']) {
      case 'query_profile':
        return 'Ecco le informazioni del tuo profilo:\n$result';
      case 'update_profile':
        return 'Ho aggiornato il tuo profilo:\n$result';
      default:
        return result;
    }
  }

  Map<String, dynamic> _prepareContext(
    Map<String, dynamic> context,
    UserModel user,
  ) {
    final userProfile = user.toMap();

    // Converti i Timestamp in stringhe ISO
    userProfile.forEach((key, value) {
      if (value is Timestamp) {
        userProfile[key] = value.toDate().toIso8601String();
      }
    });

    return {
      ...context,
      'userProfile': userProfile,
      'features': {'training': true, 'maxrm': true, 'profile': true},
    };
  }
}

final aiServiceManagerProvider = Provider<AIServiceManager>((ref) {
  final aiSettings = ref.watch(ai_providers.aiSettingsProvider);
  final selectedModel = aiSettings.selectedModel;
  final usersService = ref.watch(usersServiceProvider);

  late AIService primaryAIService;
  late AIService fallbackAIService;

  switch (aiSettings.selectedProvider) {
    case AIProvider.openAI:
      primaryAIService = ref.watch(
        ai_providers.openaiServiceProvider(selectedModel.modelId),
      );
      fallbackAIService = aiSettings.hasKeyForProvider(AIProvider.gemini)
          ? ref.watch(ai_providers.geminiServiceProvider(selectedModel.modelId))
          : primaryAIService;
      break;
    case AIProvider.gemini:
      primaryAIService = ref.watch(
        ai_providers.geminiServiceProvider(selectedModel.modelId),
      );
      fallbackAIService = aiSettings.hasKeyForProvider(AIProvider.openAI)
          ? ref.watch(ai_providers.openaiServiceProvider(selectedModel.modelId))
          : primaryAIService;
      break;
    default:
      throw Exception('No AI provider selected');
  }

  return AIServiceManager(primaryAIService, fallbackAIService, usersService);
});
