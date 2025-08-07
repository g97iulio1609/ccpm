import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:alphanessone/Viewer/domain/entities/timer_preset.dart';
import 'package:alphanessone/Viewer/domain/repositories/timer_preset_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimerPresetRepositoryImpl implements TimerPresetRepository {
  final FirebaseFirestore _firestore;
  final SharedPreferences _sharedPreferences;
  static const String _cacheKeyPrefix = 'timer_presets_';

  TimerPresetRepositoryImpl(this._firestore, this._sharedPreferences);

  String _getCacheKey(String userId) => '$_cacheKeyPrefix$userId';

  @override
  Future<List<TimerPreset>> getTimerPresets(String userId) async {
    List<TimerPreset> cachedPresets = [];
    final cachedData = _sharedPreferences.getString(_getCacheKey(userId));
    if (cachedData != null) {
      try {
        final decoded = jsonDecode(cachedData) as List;
        cachedPresets = decoded
            .map(
              (item) => TimerPreset.fromJsonFromCache(
                item as Map<String, dynamic>,
                userId,
              ),
            )
            .toList();
      } catch (e) {
        debugPrint('Errore decodifica cache TimerPresets: $e');
        // Non bloccare, procedi a caricare da Firestore
      }
    }

    try {
      final querySnapshot = await _firestore
          .collection('timer_presets')
          .where('userId', isEqualTo: userId)
          .orderBy('seconds') // Ordina per secondi come prima
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final firestorePresets = querySnapshot.docs
            .map((doc) => TimerPreset.fromMap(doc.data(), doc.id))
            .toList();
        await _saveToCache(userId, firestorePresets);
        return _removeDuplicatePresetsAndSort(firestorePresets);
      }
      return _removeDuplicatePresetsAndSort(
        cachedPresets,
      ); // Se Firestore è vuoto, usa la cache
    } catch (e) {
      debugPrint('Errore caricamento TimerPresets da Firestore: $e');
      return _removeDuplicatePresetsAndSort(
        cachedPresets,
      ); // Fallback sulla cache
    }
  }

  @override
  Future<void> saveTimerPreset(String userId, TimerPreset preset) async {
    // L'ID del preset dovrebbe essere generato da Firestore se non fornito
    DocumentReference docRef;
    Map<String, dynamic> presetData = preset.toMap();

    if (preset.id.isEmpty) {
      // Se l'ID è vuoto, Firestore ne genererà uno
      docRef = await _firestore.collection('timer_presets').add(presetData);
    } else {
      // Altrimenti usa l'ID fornito (es. da un preset precedentemente cachato o generato client-side)
      docRef = _firestore.collection('timer_presets').doc(preset.id);
      await docRef.set(presetData);
    }

    // Aggiorna la cache con il nuovo preset (con l'ID corretto)
    final createdPreset = preset.id.isEmpty
        ? preset.copyWith(id: docRef.id, userId: userId)
        : preset.copyWith(userId: userId);
    // createdAt sarà gestito da Firestore (serverTimestamp nel toMap), quindi non è necessario recuperarlo qui per la cache.

    final currentPresets = await getTimerPresets(
      userId,
    ); // Ricarica per consistenza
    // Aggiungi o aggiorna il preset nella lista
    final existingIndex = currentPresets.indexWhere(
      (p) => p.id == createdPreset.id,
    );
    if (existingIndex != -1) {
      currentPresets[existingIndex] = createdPreset;
    } else {
      currentPresets.add(createdPreset);
    }
    await _saveToCache(userId, _removeDuplicatePresetsAndSort(currentPresets));
  }

  @override
  Future<void> updateTimerPreset(String userId, TimerPreset preset) async {
    // Assicurati che l'ID esista per l'update
    if (preset.id.isEmpty) {
      debugPrint("Errore: ID del TimerPreset mancante per l'aggiornamento.");
      return;
    }
    await _firestore
        .collection('timer_presets')
        .doc(preset.id)
        .update(preset.toMap());

    // Aggiorna la cache
    final currentPresets = await getTimerPresets(
      userId,
    ); // Ricarica per consistenza
    final index = currentPresets.indexWhere((p) => p.id == preset.id);
    if (index != -1) {
      currentPresets[index] = preset.copyWith(
        userId: userId,
      ); // Assicura che userId sia corretto
    }
    await _saveToCache(userId, _removeDuplicatePresetsAndSort(currentPresets));
  }

  @override
  Future<void> deleteTimerPreset(String userId, String presetId) async {
    if (presetId.isEmpty) return;
    await _firestore.collection('timer_presets').doc(presetId).delete();

    // Aggiorna la cache
    final currentPresets = await getTimerPresets(userId);
    currentPresets.removeWhere((p) => p.id == presetId);
    await _saveToCache(userId, _removeDuplicatePresetsAndSort(currentPresets));
  }

  @override
  Future<void> saveDefaultTimerPresets(
    String userId,
    List<TimerPreset> defaultPresets,
  ) async {
    final batch = _firestore.batch();
    for (var preset in defaultPresets) {
      // Genera un ID se non presente, o usa quello fornito se i default preset hanno ID significativi
      final docRef = preset.id.isEmpty
          ? _firestore.collection('timer_presets').doc()
          : _firestore.collection('timer_presets').doc(preset.id);
      batch.set(docRef, preset.copyWith(userId: userId).toMap());
    }
    await batch.commit();

    // Ricarica e salva in cache per consistenza
    final allPresets = await getTimerPresets(userId);
    await _saveToCache(userId, _removeDuplicatePresetsAndSort(allPresets));
  }

  Future<void> _saveToCache(String userId, List<TimerPreset> presets) async {
    final dataToCache = presets.map((p) => p.toJsonForCache()).toList();
    await _sharedPreferences.setString(
      _getCacheKey(userId),
      jsonEncode(dataToCache),
    );
  }

  // Rinominato per chiarezza, e assicura l'ordinamento dopo la rimozione duplicati
  List<TimerPreset> _removeDuplicatePresetsAndSort(List<TimerPreset> presets) {
    final uniquePresetsBySeconds = <int, TimerPreset>{};
    for (final preset in presets) {
      // Se ci sono più preset con gli stessi secondi, l'ultimo vince (o il primo, a seconda della logica)
      // Qui, per semplicità, l'ultimo incontrato nella lista sovrascrive.
      // Se gli ID sono importanti per l'unicità oltre ai secondi, la logica cambia.
      uniquePresetsBySeconds[preset.seconds] = preset;
    }
    return uniquePresetsBySeconds.values.toList()
      ..sort((a, b) => a.seconds.compareTo(b.seconds));
  }
}
