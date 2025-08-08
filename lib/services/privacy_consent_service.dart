import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/privacy_consent_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PrivacyConsentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Versione corrente della privacy policy
  static const String currentPrivacyPolicyVersion = '1.0.0';

  /// Salva il consenso privacy per un utente durante la registrazione
  static Future<void> saveConsentOnRegistration({
    required String userId,
    required bool consentGiven,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      final consent = PrivacyConsentModel.forRegistration(
        userId: userId,
        consentGiven: consentGiven,
        ipAddress: ipAddress ?? await _getClientIP(),
        userAgent: userAgent ?? _getUserAgent(),
        privacyPolicyVersion: currentPrivacyPolicyVersion,
      );

      // Salva il consenso nella collezione privacy_consents
      await _firestore
          .collection('privacy_consents')
          .doc(userId)
          .set(consent.toMap());

      // Aggiorna anche i campi nel documento utente
      await _updateUserConsentFields(userId, consent);
    } catch (e) {
      throw Exception('Errore nel salvare il consenso privacy: $e');
    }
  }

  /// Aggiorna il consenso privacy per un utente esistente
  static Future<void> updateConsent({
    required String userId,
    required bool consentGiven,
    String? ipAddress,
    String? userAgent,
    String consentMethod = 'update',
  }) async {
    try {
      final consent = PrivacyConsentModel(
        id: userId, // Usa userId come id per il documento
        userId: userId,
        consentGiven: consentGiven,
        consentTimestamp: DateTime.now(),
        ipAddress: ipAddress ?? await _getClientIP(),
        userAgent: userAgent ?? _getUserAgent(),
        privacyPolicyVersion: currentPrivacyPolicyVersion,
        consentMethod: consentMethod,
      );

      // Aggiorna il consenso nella collezione privacy_consents
      await _firestore
          .collection('privacy_consents')
          .doc(userId)
          .set(consent.toMap(), SetOptions(merge: true));

      // Aggiorna anche i campi nel documento utente
      await _updateUserConsentFields(userId, consent);
    } catch (e) {
      throw Exception('Errore nell\'aggiornare il consenso privacy: $e');
    }
  }

  /// Ritira il consenso privacy per un utente
  static Future<void> withdrawConsent(String userId) async {
    try {
      final currentConsent = await getConsentForUser(userId);
      if (currentConsent != null) {
        final withdrawnConsent = currentConsent.withdraw();

        // Salva il consenso ritirato
        await _firestore
            .collection('privacy_consents')
            .doc(userId)
            .set(withdrawnConsent.toMap(), SetOptions(merge: true));

        // Aggiorna i campi nel documento utente
        await _updateUserConsentFields(userId, withdrawnConsent);
      }
    } catch (e) {
      throw Exception('Errore nel ritirare il consenso privacy: $e');
    }
  }

  /// Ottiene il consenso privacy per un utente
  static Future<PrivacyConsentModel?> getConsentForUser(String userId) async {
    try {
      final doc = await _firestore
          .collection('privacy_consents')
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        return PrivacyConsentModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Errore nel recuperare il consenso privacy: $e');
    }
  }

  /// Verifica se un utente ha dato il consenso valido
  static Future<bool> hasValidConsent(String userId) async {
    try {
      final consent = await getConsentForUser(userId);
      return consent?.isValidGDPRConsent() ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Verifica se è necessario richiedere un nuovo consenso
  static Future<bool> needsConsentUpdate(String userId) async {
    try {
      final consent = await getConsentForUser(userId);
      if (consent == null) return true;

      // Verifica se la versione della privacy policy è cambiata
      return consent.privacyPolicyVersion != currentPrivacyPolicyVersion;
    } catch (e) {
      return true;
    }
  }

  /// Ottiene tutti i consensi per audit (solo per admin)
  static Future<List<PrivacyConsentModel>> getAllConsents() async {
    try {
      final querySnapshot = await _firestore
          .collection('privacy_consents')
          .orderBy('consentTimestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PrivacyConsentModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Errore nel recuperare tutti i consensi: $e');
    }
  }

  /// Aggiorna i campi di consenso nel documento utente
  static Future<void> _updateUserConsentFields(
    String userId,
    PrivacyConsentModel consent,
  ) async {
    await _firestore.collection('users').doc(userId).update({
      'privacyConsentGiven': consent.consentGiven,
      'privacyConsentTimestamp': Timestamp.fromDate(consent.consentTimestamp),
      'privacyPolicyVersion': consent.privacyPolicyVersion,
      'lastConsentMethod': consent.consentMethod,
    });
  }

  /// Ottiene l'indirizzo IP del client (simulato per web/mobile)
  static Future<String> _getClientIP() async {
    // In un'app reale, dovresti implementare la logica per ottenere l'IP
    // Per ora restituiamo un placeholder
    if (kIsWeb) {
      return 'web-client-ip';
    } else {
      return 'mobile-client-ip';
    }
  }

  /// Ottiene il user agent del client
  static String _getUserAgent() {
    if (kIsWeb) {
      return 'Web Browser';
    } else if (Platform.isAndroid) {
      return 'Android App';
    } else if (Platform.isIOS) {
      return 'iOS App';
    } else {
      return 'Unknown Platform';
    }
  }

  /// Esporta i dati di consenso per un utente (per GDPR data portability)
  static Future<Map<String, dynamic>> exportUserConsentData(
    String userId,
  ) async {
    try {
      final consent = await getConsentForUser(userId);
      if (consent == null) {
        return {'error': 'Nessun consenso trovato per l\'utente'};
      }

      return {
        'userId': consent.userId,
        'consentGiven': consent.consentGiven,
        'consentTimestamp': consent.consentTimestamp.toIso8601String(),
        'privacyPolicyVersion': consent.privacyPolicyVersion,
        'consentMethod': consent.consentMethod,
        'exportedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Errore nell\'esportare i dati di consenso: $e');
    }
  }

  /// Elimina tutti i dati di consenso per un utente (per GDPR right to be forgotten)
  static Future<void> deleteUserConsentData(String userId) async {
    try {
      // Elimina dalla collezione privacy_consents
      await _firestore.collection('privacy_consents').doc(userId).delete();

      // Rimuove i campi di consenso dal documento utente
      await _firestore.collection('users').doc(userId).update({
        'privacyConsentGiven': FieldValue.delete(),
        'privacyConsentTimestamp': FieldValue.delete(),
        'privacyPolicyVersion': FieldValue.delete(),
        'lastConsentMethod': FieldValue.delete(),
      });
    } catch (e) {
      throw Exception('Errore nell\'eliminare i dati di consenso: $e');
    }
  }
}
