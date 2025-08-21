import 'package:alphanessone/shared/shared.dart';

/// Business logic pura e riutilizzabile per la gestione delle Series.
///
/// - Operazioni immutabili: ogni metodo ritorna nuove liste/istanze
/// - Nessuna dipendenza da UI/Controller
class SeriesBusinessService {
  /// Reordina la lista delle serie restituendo una nuova lista con `order` ricalcolato (1-based).
  static List<Series> reorderSeries(List<Series> originalSeries, int oldIndex, int newIndex) {
    if (originalSeries.isEmpty) {
      return originalSeries;
    }
    if (oldIndex < 0 || oldIndex >= originalSeries.length) {
      return originalSeries;
    }
    if (newIndex < 0 || newIndex > originalSeries.length) {
      return originalSeries;
    }

    // Copia difensiva
    final List<Series> updated = List<Series>.from(originalSeries);
    int targetIndex = newIndex;
    if (oldIndex < targetIndex) {
      targetIndex -= 1;
    }

    final Series moved = updated.removeAt(oldIndex);
    updated.insert(targetIndex, moved);

    return recalculateOrders(updated);
  }

  /// Ricalcola il campo `order` per tutte le serie (1-based). Facoltativo `startIndex`.
  static List<Series> recalculateOrders(List<Series> originalSeries, {int startIndex = 0}) {
    final List<Series> updated = List<Series>.from(originalSeries);
    for (int i = startIndex; i < updated.length; i++) {
      updated[i] = updated[i].copyWith(order: i + 1);
    }
    return updated;
  }

  /// Sostituisce in modo immutabile l'elemento in posizione [index].
  static List<Series> replaceAt(List<Series> originalSeries, int index, Series newValue) {
    if (index < 0 || index >= originalSeries.length) {
      return originalSeries;
    }
    final List<Series> updated = List<Series>.from(originalSeries);
    updated[index] = newValue;
    return updated;
  }

  /// Aggiorna i campi di range/valori su una Series in modo tipizzato.
  /// Accetta [field] per compatibilità col controller esistente.
  static Series updateRangeField(
    Series series, {
    required String field,
    required dynamic value,
    required dynamic maxValue,
  }) {
    switch (field) {
      case 'reps':
        return series.copyWith(reps: value, maxReps: maxValue);
      case 'sets':
        return series.copyWith(sets: value, maxSets: maxValue);
      case 'intensity':
        return series.copyWith(intensity: value, maxIntensity: maxValue);
      case 'rpe':
        return series.copyWith(rpe: value, maxRpe: maxValue);
      case 'weight':
        return series.copyWith(weight: value, maxWeight: maxValue);
      default:
        return series; // Nessuna modifica per campo non valido
    }
  }
}
