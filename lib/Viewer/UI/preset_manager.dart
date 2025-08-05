import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'timer_constants.dart';

class PresetManager {
  final String userId;
  final Function(List<Map<String, dynamic>>) onPresetsUpdated;

  PresetManager({
    required this.userId,
    required this.onPresetsUpdated,
  });

  Future<void> loadUserPresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Carica dati dalla cache
      final cachedPresets =
          _loadPresetsFromCache(prefs, 'timer_presets_$userId');

      // Sincronizza con Firestore
      try {
        final presets = await FirebaseFirestore.instance
            .collection('timer_presets')
            .where('userId', isEqualTo: userId)
            .orderBy('seconds')
            .get();

        if (presets.docs.isNotEmpty) {
          final updatedPresets = _removeDuplicatePresets(presets.docs
              .map((doc) => {
                    'id': doc.id,
                    'label': doc.data()['label'] as String,
                    'seconds': doc.data()['seconds'] as int,
                  })
              .toList());

          // Aggiorna cache
          await _saveToCache(prefs, 'timer_presets_$userId', updatedPresets);
          onPresetsUpdated(updatedPresets);
          return;
        }

        // Se non ci sono preset, crea quelli predefiniti
        final batch = FirebaseFirestore.instance.batch();
        final defaultPresets = await Future.wait(
          TimerConstants.defaultPresets.map((preset) async {
            final docRef =
                FirebaseFirestore.instance.collection('timer_presets').doc();
            batch.set(docRef, {
              'userId': userId,
              'label': preset['label'],
              'seconds': preset['seconds'],
              'createdAt': FieldValue.serverTimestamp(),
            });
            return {
              'id': docRef.id,
              ...preset,
            };
          }),
        );

        await batch.commit();
        await _saveToCache(prefs, 'timer_presets_$userId', defaultPresets);
        onPresetsUpdated(defaultPresets);
      } catch (_) {
        // Usa dati dalla cache se Firestore non disponibile
        onPresetsUpdated(_removeDuplicatePresets(cachedPresets));
      }
    } catch (_) {
      onPresetsUpdated([]);
    }
  }

  List<Map<String, dynamic>> _loadPresetsFromCache(
      SharedPreferences prefs, String key) {
    final data = prefs.getString(key);
    if (data == null) return [];
    try {
      final decoded = jsonDecode(data);
      return decoded is List
          ? decoded.map((item) => Map<String, dynamic>.from(item)).toList()
          : [];
    } catch (_) {
      return [];
    }
  }

  List<Map<String, dynamic>> _removeDuplicatePresets(
      List<Map<String, dynamic>> presets) {
    final uniquePresets = <int, Map<String, dynamic>>{};
    for (final preset in presets) {
      final seconds = preset['seconds'] as int;
      if (!uniquePresets.containsKey(seconds)) {
        uniquePresets[seconds] = preset;
      }
    }
    return uniquePresets.values.toList()
      ..sort((a, b) => a['seconds'].compareTo(b['seconds']));
  }

  Future<void> savePreset(
      String label, int seconds, BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('timer_presets').add({
        'userId': userId,
        'label': label,
        'seconds': seconds,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Ricarica i preset per aggiornare la lista
      loadUserPresets();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore nel salvare il preset')),
        );
      }
    }
  }

  Future<void> updatePreset(
      String presetId, String label, int seconds, BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('timer_presets')
          .doc(presetId)
          .update({
        'label': label,
        'seconds': seconds,
      });

      // Ricarica i preset per aggiornare la lista
      loadUserPresets();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore nell\'aggiornare il preset')),
        );
      }
    }
  }

  Future<void> deletePreset(String presetId) async {
    try {
      await FirebaseFirestore.instance
          .collection('timer_presets')
          .doc(presetId)
          .delete();

      // Ricarica i preset per aggiornare la lista
      loadUserPresets();
    } catch (_) {}
  }

  Future<void> _saveToCache(
      SharedPreferences prefs, String key, dynamic data) async {
    await prefs.setString(key, jsonEncode(data));
  }

  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return remainingSeconds > 0
          ? '${minutes}m ${remainingSeconds}s'
          : '${minutes}m';
    }
    return '${remainingSeconds}s';
  }
}
