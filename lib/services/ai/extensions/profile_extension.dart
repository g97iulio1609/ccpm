import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:alphanessone/models/user_model.dart';
import 'ai_extension.dart';

class ProfileExtension implements AIExtension {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  @override
  Future<bool> canHandle(Map<String, dynamic> interpretation) async {
    return interpretation['featureType'] == 'profile';
  }

  @override
  Future<String> handle(Map<String, dynamic> interpretation, String userId,
      UserModel user) async {
    final action = interpretation['action'];
    if (action == 'update_profile') {
      return await _handleUpdateProfile(interpretation, userId, user);
    } else if (action == 'query_profile') {
      return await _handleQueryProfile(interpretation, user);
    } else {
      return 'Non ho capito l\'azione richiesta sul profilo.';
    }
  }

  Future<String> _handleUpdateProfile(Map<String, dynamic> interpretation,
      String userId, UserModel user) async {
    final updates = <String, dynamic>{};

    // L'AI restituirà i campi che devono essere aggiornati, es: "phoneNumber", "height", "birthdate", "activityLevel"
    if (interpretation.containsKey('phoneNumber')) {
      updates['phoneNumber'] = interpretation['phoneNumber'];
    }

    if (interpretation.containsKey('height')) {
      final heightVal = double.tryParse(interpretation['height'].toString());
      if (heightVal == null || heightVal < 50 || heightVal > 250) {
        return 'Altezza non valida. Inserisci un valore tra 50 e 250 cm';
      }
      updates['height'] = heightVal;
    }

    if (interpretation.containsKey('birthdate')) {
      // birthdate in formato YYYY-MM-DD
      try {
        final date = DateTime.parse(interpretation['birthdate']);
        updates['birthdate'] = Timestamp.fromDate(date);
      } catch (e) {
        return 'Formato data non valido. Usa YYYY-MM-DD';
      }
    }

    if (interpretation.containsKey('activityLevel')) {
      final level =
          _stringToActivityLevel(interpretation['activityLevel'].toString());
      updates['activityLevel'] = level;
    }

    if (updates.isEmpty) {
      return 'Non ho trovato nessun campo aggiornabile nel profilo.';
    }

    try {
      await _firestore.collection('users').doc(userId).update(updates);
      return 'Ho aggiornato il tuo profilo con i dati forniti.';
    } catch (e) {
      return 'Errore durante l\'aggiornamento del profilo: $e';
    }
  }

  Future<String> _handleQueryProfile(
      Map<String, dynamic> interpretation, UserModel user) async {
    // L'AI dovrebbe specificare quale campo vuole conoscere. Ad esempio "query_profile" con "field": "height"
    if (!interpretation.containsKey('field')) {
      return 'Non ho capito quale informazione del profilo vuoi conoscere.';
    }

    final field = interpretation['field'].toString().toLowerCase();
    switch (field) {
      case 'phone':
      case 'telefono':
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
      case 'livello di attività':
        return user.activityLevel != null
            ? _activityLevelToString(user.activityLevel!)
            : 'Livello di attività non impostato';
      default:
        return 'Informazione non disponibile o non riconosciuta.';
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
