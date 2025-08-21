import 'package:alphanessone/providers/providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:alphanessone/models/ai_keys_model.dart';
import 'package:alphanessone/services/users_services.dart';

class AIKeysService {
  final FirebaseFirestore _firestore;
  final UsersService _usersService;
  final Logger _logger = Logger(printer: PrettyPrinter());

  AIKeysService(this._firestore, this._usersService);

  Future<AIKeysModel?> getKeys() async {
    try {
      final userId = _usersService.getCurrentUserId();

      // Prima cerca le chiavi personali dell'utente
      final userKeysDoc = await _firestore.collection('ai_keys').doc(userId).get();

      // Poi cerca le chiavi di default
      final defaultKeysDoc = await _firestore.collection('ai_keys').doc('default').get();

      if (!userKeysDoc.exists && !defaultKeysDoc.exists) {
        return null;
      }

      final defaultData = defaultKeysDoc.exists ? defaultKeysDoc.data() ?? {} : {};
      final userData = userKeysDoc.exists ? userKeysDoc.data() ?? {} : {};

      return AIKeysModel(
        defaultOpenAIKey: defaultData['defaultOpenAIKey'] as String?,
        defaultGeminiKey: defaultData['defaultGeminiKey'] as String?,
        defaultClaudeKey: defaultData['defaultClaudeKey'] as String?,
        defaultAzureKey: defaultData['defaultAzureKey'] as String?,
        defaultAzureEndpoint: defaultData['defaultAzureEndpoint'] as String?,
        personalOpenAIKey: userData['personalOpenAIKey'] as String?,
        personalGeminiKey: userData['personalGeminiKey'] as String?,
        personalClaudeKey: userData['personalClaudeKey'] as String?,
        personalAzureKey: userData['personalAzureKey'] as String?,
        personalAzureEndpoint: userData['personalAzureEndpoint'] as String?,
        userId: userId,
      );
    } catch (e, stackTrace) {
      _logger.e('Error getting AI keys', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  Future<bool> updatePersonalKeys({
    String? openAIKey,
    String? geminiKey,
    String? claudeKey,
    String? azureKey,
    String? azureEndpoint,
  }) async {
    try {
      final userId = _usersService.getCurrentUserId();
      final updates = <String, dynamic>{};

      if (openAIKey != null) updates['personalOpenAIKey'] = openAIKey;
      if (geminiKey != null) updates['personalGeminiKey'] = geminiKey;
      if (claudeKey != null) updates['personalClaudeKey'] = claudeKey;
      if (azureKey != null) updates['personalAzureKey'] = azureKey;
      if (azureEndpoint != null) {
        updates['personalAzureEndpoint'] = azureEndpoint;
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('ai_keys').doc(userId).set(updates, SetOptions(merge: true));
      }

      return true;
    } catch (e, stackTrace) {
      _logger.e('Error updating personal AI keys', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> updateDefaultKeys({
    String? openAIKey,
    String? geminiKey,
    String? claudeKey,
    String? azureKey,
    String? azureEndpoint,
  }) async {
    try {
      // Verifica se l'utente è un amministratore
      final user = await _usersService.getCurrentUser();
      if (user?.role != 'admin') {
        _logger.w('Unauthorized attempt to update default keys');
        return false;
      }

      final updates = <String, dynamic>{};

      if (openAIKey != null) updates['defaultOpenAIKey'] = openAIKey;
      if (geminiKey != null) updates['defaultGeminiKey'] = geminiKey;
      if (claudeKey != null) updates['defaultClaudeKey'] = claudeKey;
      if (azureKey != null) updates['defaultAzureKey'] = azureKey;
      if (azureEndpoint != null) {
        updates['defaultAzureEndpoint'] = azureEndpoint;
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('ai_keys').doc('default').set(updates, SetOptions(merge: true));
      }

      return true;
    } catch (e, stackTrace) {
      _logger.e('Error updating default AI keys', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Stream<AIKeysModel?> keysStream() {
    final userId = _usersService.getCurrentUserId();

    return _firestore
        .collection('ai_keys')
        .where(FieldPath.documentId, whereIn: [userId, 'default'])
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;

          DocumentSnapshot? defaultDoc;
          DocumentSnapshot? userDoc;

          for (var doc in snapshot.docs) {
            if (doc.id == 'default') {
              defaultDoc = doc;
            } else if (doc.id == userId) {
              userDoc = doc;
            }
          }

          final defaultData = defaultDoc?.data() as Map<String, dynamic>? ?? {};
          final userData = userDoc?.data() as Map<String, dynamic>? ?? {};

          return AIKeysModel(
            defaultOpenAIKey: defaultData['defaultOpenAIKey'] as String?,
            defaultGeminiKey: defaultData['defaultGeminiKey'] as String?,
            defaultClaudeKey: defaultData['defaultClaudeKey'] as String?,
            defaultAzureKey: defaultData['defaultAzureKey'] as String?,
            defaultAzureEndpoint: defaultData['defaultAzureEndpoint'] as String?,
            personalOpenAIKey: userData['personalOpenAIKey'] as String?,
            personalGeminiKey: userData['personalGeminiKey'] as String?,
            personalClaudeKey: userData['personalClaudeKey'] as String?,
            personalAzureKey: userData['personalAzureKey'] as String?,
            personalAzureEndpoint: userData['personalAzureEndpoint'] as String?,
            userId: userId,
          );
        });
  }
}

final aiKeysServiceProvider = Provider<AIKeysService>((ref) {
  final firestore = FirebaseFirestore.instance;
  final usersService = ref.watch(usersServiceProvider);
  return AIKeysService(firestore, usersService);
});

final aiKeysStreamProvider = StreamProvider<AIKeysModel?>((ref) {
  final aiKeysService = ref.watch(aiKeysServiceProvider);
  return aiKeysService.keysStream();
});
