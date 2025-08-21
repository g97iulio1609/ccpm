import 'package:cloud_firestore/cloud_firestore.dart';

/// Modello per tracciare il consenso alla privacy policy secondo le best practices GDPR
/// Contiene tutti i dati necessari per dimostrare che l'utente ha fornito un consenso valido
class PrivacyConsentModel {
  final String id;
  final String userId;
  final bool consentGiven;
  final DateTime consentTimestamp;
  final String? ipAddress;
  final String? userAgent;
  final String privacyPolicyVersion;
  final String consentMethod; // 'registration', 'update', 'renewal'
  final String? withdrawalTimestamp;
  final bool isActive;
  final Map<String, dynamic>? additionalData;

  const PrivacyConsentModel({
    required this.id,
    required this.userId,
    required this.consentGiven,
    required this.consentTimestamp,
    this.ipAddress,
    this.userAgent,
    required this.privacyPolicyVersion,
    required this.consentMethod,
    this.withdrawalTimestamp,
    this.isActive = true,
    this.additionalData,
  });

  /// Factory constructor per creare un'istanza da Firestore
  factory PrivacyConsentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PrivacyConsentModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      consentGiven: data['consentGiven'] ?? false,
      consentTimestamp: (data['consentTimestamp'] as Timestamp).toDate(),
      ipAddress: data['ipAddress'],
      userAgent: data['userAgent'],
      privacyPolicyVersion: data['privacyPolicyVersion'] ?? '1.0',
      consentMethod: data['consentMethod'] ?? 'unknown',
      withdrawalTimestamp: data['withdrawalTimestamp'],
      isActive: data['isActive'] ?? true,
      additionalData: data['additionalData'] as Map<String, dynamic>?,
    );
  }

  /// Factory constructor per creare un'istanza da una mappa
  factory PrivacyConsentModel.fromMap(Map<String, dynamic> data) {
    return PrivacyConsentModel(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      consentGiven: data['consentGiven'] ?? false,
      consentTimestamp: data['consentTimestamp'] is Timestamp
          ? (data['consentTimestamp'] as Timestamp).toDate()
          : DateTime.parse(data['consentTimestamp'] ?? DateTime.now().toIso8601String()),
      ipAddress: data['ipAddress'],
      userAgent: data['userAgent'],
      privacyPolicyVersion: data['privacyPolicyVersion'] ?? '1.0',
      consentMethod: data['consentMethod'] ?? 'unknown',
      withdrawalTimestamp: data['withdrawalTimestamp'],
      isActive: data['isActive'] ?? true,
      additionalData: data['additionalData'] as Map<String, dynamic>?,
    );
  }

  /// Factory constructor per creare un nuovo consenso durante la registrazione
  factory PrivacyConsentModel.forRegistration({
    required String userId,
    required bool consentGiven,
    required String privacyPolicyVersion,
    String? ipAddress,
    String? userAgent,
    Map<String, dynamic>? additionalData,
  }) {
    return PrivacyConsentModel(
      id: '', // Sarà generato da Firestore
      userId: userId,
      consentGiven: consentGiven,
      consentTimestamp: DateTime.now(),
      ipAddress: ipAddress,
      userAgent: userAgent,
      privacyPolicyVersion: privacyPolicyVersion,
      consentMethod: 'registration',
      isActive: true,
      additionalData: additionalData,
    );
  }

  /// Converte il modello in una mappa per Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'consentGiven': consentGiven,
      'consentTimestamp': Timestamp.fromDate(consentTimestamp),
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'privacyPolicyVersion': privacyPolicyVersion,
      'consentMethod': consentMethod,
      'withdrawalTimestamp': withdrawalTimestamp,
      'isActive': isActive,
      'additionalData': additionalData,
    };
  }

  /// Crea una copia del modello con alcuni campi modificati
  PrivacyConsentModel copyWith({
    String? id,
    String? userId,
    bool? consentGiven,
    DateTime? consentTimestamp,
    String? ipAddress,
    String? userAgent,
    String? privacyPolicyVersion,
    String? consentMethod,
    String? withdrawalTimestamp,
    bool? isActive,
    Map<String, dynamic>? additionalData,
  }) {
    return PrivacyConsentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      consentGiven: consentGiven ?? this.consentGiven,
      consentTimestamp: consentTimestamp ?? this.consentTimestamp,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      privacyPolicyVersion: privacyPolicyVersion ?? this.privacyPolicyVersion,
      consentMethod: consentMethod ?? this.consentMethod,
      withdrawalTimestamp: withdrawalTimestamp ?? this.withdrawalTimestamp,
      isActive: isActive ?? this.isActive,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  /// Crea un nuovo consenso per il ritiro del consenso
  PrivacyConsentModel withdraw() {
    return copyWith(
      consentGiven: false,
      isActive: false,
      withdrawalTimestamp: DateTime.now().toIso8601String(),
      consentMethod: 'withdrawal',
    );
  }

  /// Verifica se il consenso è valido secondo GDPR
  bool isValidGDPRConsent() {
    return consentGiven &&
        isActive &&
        consentTimestamp.isBefore(DateTime.now()) &&
        privacyPolicyVersion.isNotEmpty &&
        userId.isNotEmpty;
  }

  @override
  String toString() {
    return 'PrivacyConsentModel(id: $id, userId: $userId, consentGiven: $consentGiven, timestamp: $consentTimestamp, version: $privacyPolicyVersion, method: $consentMethod, active: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrivacyConsentModel &&
        other.id == id &&
        other.userId == userId &&
        other.consentGiven == consentGiven &&
        other.consentTimestamp == consentTimestamp &&
        other.privacyPolicyVersion == privacyPolicyVersion;
  }

  @override
  int get hashCode {
    return Object.hash(id, userId, consentGiven, consentTimestamp, privacyPolicyVersion);
  }
}

/// Enum per i metodi di consenso
enum ConsentMethod {
  registration('registration'),
  update('update'),
  renewal('renewal'),
  withdrawal('withdrawal'),
  migration('migration');

  const ConsentMethod(this.value);
  final String value;

  static ConsentMethod fromString(String value) {
    return ConsentMethod.values.firstWhere(
      (method) => method.value == value,
      orElse: () => ConsentMethod.registration,
    );
  }
}
