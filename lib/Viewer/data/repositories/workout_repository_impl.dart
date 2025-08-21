import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alphanessone/shared/models/week.dart';
import 'package:alphanessone/shared/models/workout.dart';
import 'package:alphanessone/shared/models/exercise.dart';
import 'package:alphanessone/shared/models/series.dart';
import 'package:alphanessone/Viewer/domain/repositories/workout_repository.dart';

class WorkoutRepositoryImpl implements WorkoutRepository {
  final FirebaseFirestore _firestore;

  WorkoutRepositoryImpl(this._firestore);

  // --- Week Operations ---
  @override
  Stream<List<Week>> getTrainingWeeks(String programId) {
    return _firestore
        .collection('weeks')
        .where('programId', isEqualTo: programId)
        .orderBy('number')
        .snapshots()
        .asyncMap((snapshot) async {
          // Parallelizza il caricamento dei workout per tutte le settimane
          final futures = snapshot.docs.map((doc) async {
            final workouts = await getWorkouts(doc.id).first;
            final week = Week.fromMap(doc.data(), doc.id);
            return week.copyWith(workouts: workouts);
          }).toList();
          return await Future.wait(futures);
        });
  }

  @override
  Future<String> getWeekName(String weekId) async {
    try {
      final weekDoc = await _firestore.collection('weeks').doc(weekId).get();
      if (weekDoc.exists && weekDoc.data() != null) {
        final number = weekDoc.data()!['number']?.toString() ?? '';
        return number.isNotEmpty ? 'Settimana $number' : 'Settimana';
      }
      return 'Settimana';
    } catch (e) {
      return 'Settimana';
    }
  }

  @override
  Future<Week> getWeek(String weekId) async {
    final weekDoc = await _firestore.collection('weeks').doc(weekId).get();
    if (!weekDoc.exists || weekDoc.data() == null) {
      throw Exception('Settimana non trovata con ID: $weekId');
    }
    final workouts = await getWorkouts(weekId).first;
    final week = Week.fromMap(weekDoc.data()!, weekDoc.id);
    // Populate workouts separately since they're not part of fromMap
    return week.copyWith(workouts: workouts);
  }

  @override
  Future<void> createWeek(Week week) async {
    await _firestore.collection('weeks').doc(week.id).set(week.toMap());
    // La creazione dei workout figli è responsabilità di un UseCase
    // for (final workout in week.workouts) {
    //   await createWorkout(workout.copyWith(weekId: week.id));
    // }
  }

  @override
  Future<void> updateWeek(Week week) async {
    await _firestore.collection('weeks').doc(week.id).update(week.toMap());
  }

  @override
  Future<void> deleteWeek(String weekId) async {
    // L'eliminazione di una settimana implica l'eliminazione a cascata di:
    // 1. Tutti i workout nella settimana.
    // 2. Tutti gli esercizi in quei workout.
    // 3. Tutte le serie associate a quegli esercizi.
    // 4. Tutte le note associate a quegli esercizi.

    final batch = _firestore.batch();

    // 1. Trova e workouts della settimana
    final workoutsSnapshot = await _firestore
        .collection('workouts')
        .where('weekId', isEqualTo: weekId)
        .get();
    for (final workoutDoc in workoutsSnapshot.docs) {
      final workoutId = workoutDoc.id;
      // Elimina esercizi del workout, le loro serie e note (logica già in deleteWorkout, ma la replichiamo qui per il batch)
      final exercisesSnapshot = await _firestore
          .collection('exercisesWorkout')
          .where('workoutId', isEqualTo: workoutId)
          .get();
      for (final exerciseDoc in exercisesSnapshot.docs) {
        final exerciseId = exerciseDoc.id;
        // Elimina serie dell'esercizio
        final seriesSnapshot = await _firestore
            .collection('series')
            .where('exerciseId', isEqualTo: exerciseId)
            .get();
        for (final seriesDoc in seriesSnapshot.docs) {
          batch.delete(seriesDoc.reference);
        }
        // Elimina nota dell'esercizio
        final noteDocId = '${workoutId}_$exerciseId';
        batch.delete(_firestore.collection('exercise_notes').doc(noteDocId));
        // Elimina esercizio
        batch.delete(exerciseDoc.reference);
      }
      // Elimina il workout
      batch.delete(workoutDoc.reference);
    }

    // 2. Elimina la settimana stessa
    batch.delete(_firestore.collection('weeks').doc(weekId));

    await batch.commit();
  }

  // --- Workout Operations ---
  @override
  Stream<List<Workout>> getWorkouts(String weekId) {
    return _firestore
        .collection('workouts')
        .where('weekId', isEqualTo: weekId)
        .orderBy('order')
        .snapshots()
        .asyncMap((snapshot) async {
          // Parallelizza il caricamento degli esercizi per tutti i workout
          final futures = snapshot.docs.map((doc) async {
            final exercises = await getExercisesForWorkout(doc.id).first;
            final workout = Workout.fromMap(doc.data(), doc.id);
            return workout.copyWith(exercises: exercises);
          }).toList();
          return await Future.wait(futures);
        });
  }

  @override
  Future<Workout> getWorkout(String workoutId) async {
    final doc = await _firestore.collection('workouts').doc(workoutId).get();
    if (!doc.exists || doc.data() == null) {
      throw Exception('Workout non trovato con ID: $workoutId');
    }
    final exercises = await getExercisesForWorkout(doc.id).first;
    // Simile a getWorkouts, la gestione delle note degli esercizi è separata.
    final workout = Workout.fromMap(doc.data()!, doc.id);
    // Populate exercises separately since they're not part of fromMap
    return workout.copyWith(exercises: exercises);
  }

  @override
  Future<String> getWorkoutName(String workoutId) async {
    try {
      final workoutDoc = await _firestore.collection('workouts').doc(workoutId).get();
      if (workoutDoc.exists && workoutDoc.data() != null) {
        final name = workoutDoc.data()!['name'] as String?;
        final order = workoutDoc.data()!['order']?.toString() ?? '';
        return name ?? (order.isNotEmpty ? 'Allenamento $order' : 'Allenamento');
      }
      return 'Allenamento';
    } catch (e) {
      return 'Allenamento';
    }
  }

  @override
  Future<void> createWorkout(Workout workout) async {
    await _firestore.collection('workouts').doc(workout.id).set(workout.toMap());
    // La creazione degli esercizi figli è responsabilità di un UseCase
    // for (final exercise in workout.exercises) {
    //   await createExercise(exercise.copyWith(workoutId: workout.id));
    // }
  }

  @override
  Future<void> updateWorkout(Workout workout) async {
    await _firestore.collection('workouts').doc(workout.id).update(workout.toMap());
  }

  @override
  Future<void> deleteWorkout(String workoutId) async {
    // L'eliminazione di un workout implica l'eliminazione a cascata di:
    // 1. Tutti gli esercizi nel workout.
    // 2. Tutte le serie associate a quegli esercizi.
    // 3. Tutte le note associate a quegli esercizi.

    final batch = _firestore.batch();

    // 1. Trova ed elimina esercizi e le loro serie/note
    final exercisesSnapshot = await _firestore
        .collection('exercisesWorkout')
        .where('workoutId', isEqualTo: workoutId)
        .get();
    for (final exerciseDoc in exercisesSnapshot.docs) {
      final exerciseId = exerciseDoc.id;
      // Elimina serie dell'esercizio
      final seriesSnapshot = await _firestore
          .collection('series')
          .where('exerciseId', isEqualTo: exerciseId)
          .get();
      for (final seriesDoc in seriesSnapshot.docs) {
        batch.delete(seriesDoc.reference);
      }
      // Elimina nota dell'esercizio (l'ID della nota è ${workoutId}_$exerciseId)
      final noteDocId = '${workoutId}_$exerciseId';
      batch.delete(_firestore.collection('exercise_notes').doc(noteDocId));

      // Elimina esercizio
      batch.delete(exerciseDoc.reference);
    }

    // 2. Elimina il workout stesso
    batch.delete(_firestore.collection('workouts').doc(workoutId));

    await batch.commit();
  }

  // --- Exercise Operations ---
  @override
  Stream<List<Exercise>> getExercisesForWorkout(String workoutId) {
    return _firestore
        .collection('exercisesWorkout')
        .where('workoutId', isEqualTo: workoutId)
        .orderBy('order')
        .snapshots()
        .asyncMap((snapshot) async {
          // Parallelizza il caricamento di serie e note per tutti gli esercizi
          final futures = snapshot.docs.map((doc) async {
            final data = doc.data();
            final results = await Future.wait([
              getSeriesForExercise(doc.id).first,
              getNoteForExercise(workoutId, doc.id),
            ]);
            final series = results[0] as List<Series>;
            final note = results[1] as String?;
            final exercise = Exercise.fromMap(data, doc.id);
            return exercise.copyWith(series: series, note: note);
          }).toList();
          return await Future.wait(futures);
        });
  }

  @override
  Future<Exercise> getExercise(String exerciseId) async {
    final doc = await _firestore.collection('exercisesWorkout').doc(exerciseId).get();
    if (!doc.exists || doc.data() == null) {
      throw Exception('Esercizio non trovato con ID: $exerciseId');
    }
    final data = doc.data()!;
    final series = await getSeriesForExercise(doc.id).first;
    final String? workoutIdForNote = data['workoutId'] as String?;
    String? note;
    if (workoutIdForNote != null) {
      note = await getNoteForExercise(workoutIdForNote, doc.id);
    }
    final exercise = Exercise.fromMap(data, doc.id);
    // Populate series and note separately since they're not part of fromMap
    return exercise.copyWith(series: series, note: note);
  }

  @override
  Future<void> createExercise(Exercise exercise) async {
    await _firestore.collection('exercisesWorkout').doc(exercise.id).set(exercise.toMap());
    // La creazione delle serie e della nota è responsabilità di un UseCase.
    // Se exercise.series non è vuota:
    // for (final s in exercise.series) {
    //   await createSeries(s.copyWith(exerciseId: exercise.id));
    // }
    // Se exercise.note non è null:
    // await saveNoteForExercise(exercise.workoutId, exercise.id, exercise.note!)
  }

  @override
  Future<void> updateExercise(Exercise exercise) async {
    await _firestore.collection('exercisesWorkout').doc(exercise.id).update(exercise.toMap());
    // L'aggiornamento di serie e note è gestito separatamente.
    // Se exercise.note è cambiato:
    // if (exercise.note != null) { await saveNoteForExercise(exercise.workoutId, exercise.id, exercise.note!); }
    // else { await deleteNoteForExercise(exercise.workoutId, exercise.id); }
  }

  @override
  Future<void> deleteExercise(String exerciseId) async {
    // L'eliminazione di un esercizio dovrebbe anche eliminare le serie associate e la nota.
    final batch = _firestore.batch();

    // 0. Recupera l'esercizio per ottenere il workoutId (necessario per l'ID della nota)
    final exerciseDocSnapshot = await _firestore
        .collection('exercisesWorkout')
        .doc(exerciseId)
        .get();
    String? workoutId;
    if (exerciseDocSnapshot.exists && exerciseDocSnapshot.data() != null) {
      workoutId = exerciseDocSnapshot.data()!['workoutId'] as String?;
    }

    // 1. Elimina le serie
    final seriesSnapshot = await _firestore
        .collection('series')
        .where('exerciseId', isEqualTo: exerciseId)
        .get();
    for (final doc in seriesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 2. Elimina la nota associata, se workoutId è stato trovato
    if (workoutId != null && workoutId.isNotEmpty) {
      final noteDocId = '${workoutId}_$exerciseId';
      batch.delete(_firestore.collection('exercise_notes').doc(noteDocId));
    } else {
      // Logga un avviso o gestisci il caso in cui workoutId non sia recuperabile
      // Potrebbe significare che l'esercizio non era ben formato o è un dato orfano.
    }

    // 3. Elimina l'esercizio
    batch.delete(_firestore.collection('exercisesWorkout').doc(exerciseId));

    await batch.commit();
  }

  @override
  Future<void> updateExercisesInWorkout(String workoutId, List<Exercise> exercises) async {
    // Implementazione completa e robusta per aggiornare gli esercizi di un workout

    // Preparo un batch di operazioni per garantire la consistenza
    final batch = _firestore.batch();

    // 1. Ottengo gli esercizi attuali per il workout
    final currentExercisesSnapshot = await _firestore
        .collection('exercisesWorkout')
        .where('workoutId', isEqualTo: workoutId)
        .get();

    // Mappa per accesso rapido agli esercizi attuali per ID

    // Insieme degli ID degli esercizi che vogliamo mantenere
    final Set<String> exerciseIdsToKeep = {};

    // 2. Processa ogni esercizio nella nuova lista
    for (final exercise in exercises) {
      final String exerciseId = exercise.id ?? '';

      // Se l'ID esercizio è vuoto, crea un nuovo esercizio
      if (exerciseId.isEmpty) {
        // Generiamo un nuovo ID
        final newExerciseRef = _firestore.collection('exercisesWorkout').doc();
        // Assicuriamoci che l'esercizio abbia il workoutId corretto
        final exerciseData = exercise.copyWith(id: newExerciseRef.id, workoutId: workoutId).toMap();

        batch.set(newExerciseRef, exerciseData);

        // Crea le serie per il nuovo esercizio
        for (final series in exercise.series) {
          final newSeriesRef = _firestore.collection('series').doc();
          batch.set(
            newSeriesRef,
            series.copyWith(id: newSeriesRef.id, exerciseId: newExerciseRef.id).toMap(),
          );
        }

        // Salva la nota se presente
        if (exercise.note != null && exercise.note!.isNotEmpty) {
          final noteDocId = '${workoutId}_${newExerciseRef.id}';
          batch.set(_firestore.collection('exercise_notes').doc(noteDocId), {
            'workoutId': workoutId,
            'exerciseId': newExerciseRef.id,
            'note': exercise.note,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      // Se l'ID esercizio esiste già, aggiorna l'esercizio
      else {
        exerciseIdsToKeep.add(exerciseId);

        // Aggiorna l'esercizio (assicurandoci che il workoutId sia corretto)
        final exerciseData = exercise.copyWith(workoutId: workoutId).toMap();
        batch.update(_firestore.collection('exercisesWorkout').doc(exerciseId), exerciseData);

        // Recupera le serie esistenti per questo esercizio
        final existingSeriesSnapshot = await _firestore
            .collection('series')
            .where('exerciseId', isEqualTo: exerciseId)
            .get();

        // Mappa per accesso rapido alle serie esistenti per ID

        // Insieme degli ID delle serie che vogliamo mantenere
        final Set<String> seriesIdsToKeep = {};

        // Processa ogni serie nella nuova lista
        for (final series in exercise.series) {
          // Se l'ID serie è vuota, crea una nuova serie
          if (series.id?.isEmpty ?? true) {
            final newSeriesRef = _firestore.collection('series').doc();
            batch.set(
              newSeriesRef,
              series.copyWith(id: newSeriesRef.id, exerciseId: exerciseId).toMap(),
            );
          }
          // Se l'ID serie esiste già, aggiorna la serie
          else {
            seriesIdsToKeep.add(series.id!);
            batch.update(
              _firestore.collection('series').doc(series.id!),
              series.copyWith(exerciseId: exerciseId).toMap(),
            );
          }
        }

        // Elimina le serie che non sono più presenti
        for (var seriesDoc in existingSeriesSnapshot.docs) {
          if (!seriesIdsToKeep.contains(seriesDoc.id)) {
            batch.delete(seriesDoc.reference);
          }
        }

        // Gestisci la nota (salva o aggiorna o elimina)
        final noteDocId = '${workoutId}_$exerciseId';
        final noteRef = _firestore.collection('exercise_notes').doc(noteDocId);

        if (exercise.note == null || exercise.note!.isEmpty) {
          // Se la nota è vuota, elimina il documento se esiste
          final noteDoc = await noteRef.get();
          if (noteDoc.exists) {
            batch.delete(noteRef);
          }
        } else {
          // Se la nota esiste, aggiorna o crea il documento
          batch.set(noteRef, {
            'workoutId': workoutId,
            'exerciseId': exerciseId,
            'note': exercise.note,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    }

    // 3. Elimina gli esercizi che non sono più presenti
    for (var exerciseDoc in currentExercisesSnapshot.docs) {
      if (!exerciseIdsToKeep.contains(exerciseDoc.id)) {
        // Elimina l'esercizio
        batch.delete(exerciseDoc.reference);

        // Elimina le serie associate all'esercizio
        final seriesSnapshot = await _firestore
            .collection('series')
            .where('exerciseId', isEqualTo: exerciseDoc.id)
            .get();
        for (var seriesDoc in seriesSnapshot.docs) {
          batch.delete(seriesDoc.reference);
        }

        // Elimina la nota associata
        final noteDocId = '${workoutId}_${exerciseDoc.id}';
        batch.delete(_firestore.collection('exercise_notes').doc(noteDocId));
      }
    }

    // 4. Esegui tutte le operazioni in una volta sola
    await batch.commit();
  }

  // --- Series Operations ---
  @override
  Stream<List<Series>> getSeriesForExercise(String exerciseId) {
    return _firestore
        .collection('series')
        .where('exerciseId', isEqualTo: exerciseId)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Series.fromMap(doc.data(), doc.id)).toList());
  }

  @override
  Future<Series> getSeries(String seriesId) async {
    final doc = await _firestore.collection('series').doc(seriesId).get();
    if (!doc.exists || doc.data() == null) {
      throw Exception('Serie non trovata con ID: $seriesId');
    }
    return Series.fromMap(doc.data()!, doc.id);
  }

  @override
  Future<void> updateSeriesRepsAndWeight(String seriesId, int repsDone, double weightDone) async {
    // Logica simile a TrainingProgramServices.updateSeries o WorkoutService.updateSeriesData
    final seriesRef = _firestore.collection('series').doc(seriesId);
    final seriesDoc = await seriesRef.get();
    final seriesData = seriesDoc.data();

    if (seriesData != null) {
      await seriesRef.update({'reps_done': repsDone, 'weight_done': weightDone});
    } else {}
  }

  @override
  Future<void> updateSeriesDoneStatus(
    String seriesId,
    bool isDone,
    int repsDone,
    double weightDone,
  ) async {
    // Questo metodo combina l'aggiornamento dello stato 'done'
    // con l'aggiornamento di reps_done e weight_done,
    // simile a TrainingProgramServices.updateSeriesWithMaxValues ma più focalizzato sullo stato 'done' effettivo.
    // Se isDone è true, repsDone e weightDone dovrebbero riflettere i valori che completano la serie.
    // Se isDone è false, repsDone e weightDone potrebbero essere 0 o i valori parziali.
    await _firestore.collection('series').doc(seriesId).update({
      'done': isDone,
      'reps_done': repsDone,
      'weight_done': weightDone,
    });
  }

  @override
  Future<void> createSeries(Series series) async {
    await _firestore.collection('series').doc(series.id).set(series.toMap());
  }

  @override
  Future<void> updateSeries(Series series) async {
    await _firestore.collection('series').doc(series.id).update(series.toMap());
  }

  @override
  Future<void> deleteSeries(String seriesId) async {
    await _firestore.collection('series').doc(seriesId).delete();
  }

  @override
  Future<void> updateMultipleSeries(List<Series> seriesList) async {
    final batch = _firestore.batch();
    for (final series in seriesList) {
      final docRef = _firestore.collection('series').doc(series.id);
      batch.update(docRef, series.toMap());
    }
    await batch.commit();
  }

  // --- Note Operations ---
  @override
  Future<String?> getNoteForExercise(String workoutId, String exerciseId) async {
    // L'ID del documento nota è una combinazione di workoutId e exerciseId
    final noteDocId = '${workoutId}_$exerciseId';
    try {
      final docSnapshot = await _firestore.collection('exercise_notes').doc(noteDocId).get();
      if (docSnapshot.exists) {
        return docSnapshot.data()?['note'] as String?;
      }
      return null;
    } catch (e) {
      // Log dell'errore o gestione specifica
      return null;
    }
  }

  @override
  Future<void> saveNoteForExercise(String workoutId, String exerciseId, String note) async {
    final noteDocId = '${workoutId}_$exerciseId';
    await _firestore.collection('exercise_notes').doc(noteDocId).set({
      'workoutId': workoutId,
      'exerciseId': exerciseId,
      'note': note,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteNoteForExercise(String workoutId, String exerciseId) async {
    final noteDocId = '${workoutId}_$exerciseId';
    try {
      await _firestore.collection('exercise_notes').doc(noteDocId).delete();
    } catch (e) {
      // Log dell'errore o gestione specifica
    }
  }

  @override
  Stream<Map<String, String>> getNotesForWorkoutStream(String workoutId) {
    return _firestore
        .collection('exercise_notes')
        .where('workoutId', isEqualTo: workoutId)
        .snapshots()
        .map((snapshot) {
          final notes = <String, String>{};
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final exerciseId = data['exerciseId'] as String?;
            final noteContent = data['note'] as String?;
            if (exerciseId != null && noteContent != null) {
              notes[exerciseId] = noteContent;
            }
          }
          return notes;
        });
  }
}
