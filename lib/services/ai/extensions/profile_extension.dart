// lib/services/ai/extensions/profile_extension.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:alphanessone/models/user_model.dart';
import 'ai_extension.dart';

class ProfileExtension implements AIExtension {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger(printer: PrettyPrinter());

  @override
  Future<bool> canHandle(Map<String, dynamic> interpretation) async {
    return interpretation['featureType'] == 'profile';
  }

  @override
  Future<String?> handle(
    Map<String, dynamic> interpretation,
    String userId,
    UserModel user,
  ) async {
    final action = interpretation['action'] as String?;
    _logger.d('Handling profile action: $action');

    if (action == null) {
      _logger.w('Action is null for profile.');
      return 'Azione non specificata per il profilo.';
    }

    if (action == 'update_profile') {
      return await _handleUpdateProfile(interpretation, userId, user);
    } else if (action == 'query_profile') {
      return await _handleQueryProfile(interpretation, user);
    } else {
      _logger.w('Unrecognized action for profile: $action');
      return 'Azione non riconosciuta per profile.';
    }
  }

  Future<String?> _handleUpdateProfile(
    Map<String, dynamic> interpretation,
    String userId,
    UserModel user,
  ) async {
    _logger.i('Updating profile with interpretation: $interpretation');
    final updates = <String, dynamic>{};

    if (interpretation.containsKey('phoneNumber')) {
      updates['phoneNumber'] = interpretation['phoneNumber'];
    }

    if (interpretation.containsKey('height')) {
      final heightVal = double.tryParse(interpretation['height'].toString());
      if (heightVal == null || heightVal < 50 || heightVal > 250) {
        _logger.w('Invalid height value: ${interpretation['height']}');
        return 'Altezza non valida.';
      }
      updates['height'] = heightVal;
    }

    if (interpretation.containsKey('birthdate')) {
      try {
        final date = DateTime.parse(interpretation['birthdate']);
        updates['birthdate'] = Timestamp.fromDate(date);
      } catch (e, stackTrace) {
        _logger.e(
          'Invalid birthdate format: ${interpretation['birthdate']}',
          error: e,
          stackTrace: stackTrace,
        );
        return 'Formato data di nascita non valido.';
      }
    }

    if (interpretation.containsKey('activityLevel')) {
      final level = _stringToActivityLevel(
        interpretation['activityLevel'].toString(),
      );
      updates['activityLevel'] = level;
    }

    if (updates.isEmpty) {
      _logger.w('No valid fields provided for profile update.');
      return 'Nessun campo valido fornito per l\'aggiornamento del profilo.';
    }

    try {
      await _firestore.collection('users').doc(userId).update(updates);
      _logger.i('Profile updated successfully for userId: $userId');
      return 'Ho aggiornato il tuo profilo con i dati forniti.';
    } catch (e, stackTrace) {
      _logger.e('Error updating profile', error: e, stackTrace: stackTrace);
      return 'Si è verificato un errore durante l\'aggiornamento del profilo.';
    }
  }

  Future<String?> _handleQueryProfile(
    Map<String, dynamic> interpretation,
    UserModel user,
  ) async {
    _logger.i('Querying profile with interpretation: $interpretation');
    if (!interpretation.containsKey('field')) {
      _logger.w('Field not specified for profile query.');
      return 'Per quale campo del profilo desideri informazioni?';
    }

    final field = interpretation['field'].toString().toLowerCase();
    switch (field) {
      case 'phone':
      case 'telefono':
        return user.phoneNumber ?? 'Numero di telefono non impostato.';
      case 'height':
      case 'altezza':
        return user.height != null
            ? '${user.height} cm'
            : 'Altezza non impostata.';
      case 'birthdate':
      case 'data di nascita':
      case 'compleanno':
        return user.birthdate?.toString().split(' ')[0] ??
            'Data di nascita non impostata.';
      case 'activity':
      case 'livello di attività':
        return user.activityLevel != null
            ? _activityLevelToString(user.activityLevel!)
            : 'Livello di attività non impostato.';
      default:
        _logger.w('Unrecognized field for profile query: $field');
        return 'Campo del profilo non riconosciuto.';
    }
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
        return 3.0;
    }
  }

  String _activityLevelToString(double level) {
    if (level < 1.5) return 'Sedentario';
    if (level < 3.0) return 'Leggero';
    if (level < 4.5) return 'Moderato';
    if (level < 6.0) return 'Molto attivo';
    return 'Estremamente attivo';
  }
}
