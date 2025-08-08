import 'package:cloud_firestore/cloud_firestore.dart';

class TimerPreset {
  final String
  id; // Potrebbe essere l'ID del documento Firestore o un UUID generato localmente
  final String userId; // ID dell'utente a cui appartiene questo preset
  final String label;
  final int seconds;
  final DateTime? createdAt;

  TimerPreset({
    required this.id,
    required this.userId,
    required this.label,
    required this.seconds,
    this.createdAt,
  });

  factory TimerPreset.empty() {
    return TimerPreset(id: '', userId: '', label: '', seconds: 0);
  }

  TimerPreset copyWith({
    String? id,
    String? userId,
    String? label,
    int? seconds,
    DateTime? createdAt,
  }) {
    return TimerPreset(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      label: label ?? this.label,
      seconds: seconds ?? this.seconds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // 'id' è l'ID del documento
      'userId': userId,
      'label': label,
      'seconds': seconds,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(), // Usa serverTimestamp se createdAt è null durante la creazione
    };
  }

  factory TimerPreset.fromMap(Map<String, dynamic> map, String documentId) {
    return TimerPreset(
      id: documentId,
      userId: map['userId'] as String,
      label: map['label'] as String,
      seconds: map['seconds'] as int,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  // Per SharedPreferences, potremmo volere metodi toJson/fromJson diversi
  // se non vogliamo salvare/caricare tutti i campi (es. userId se la cache è per utente)
  Map<String, dynamic> toJsonForCache() {
    return {
      'id': id,
      'label': label,
      'seconds': seconds,
      // Non includiamo userId o createdAt per la cache semplice per ora
    };
  }

  factory TimerPreset.fromJsonFromCache(
    Map<String, dynamic> json,
    String userId,
  ) {
    return TimerPreset(
      id: json['id'] as String,
      userId: userId, // userId iniettato perché non presente nella cache entry
      label: json['label'] as String,
      seconds: json['seconds'] as int,
      // createdAt non viene dalla cache in questo esempio
    );
  }
}
