// lib/services/ai/extensions/maxrm_extension.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:alphanessone/models/user_model.dart';
import 'ai_extension.dart';

class MaxRMExtension implements AIExtension {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger(printer: PrettyPrinter());

  @override
  Future<bool> canHandle(Map<String, dynamic> interpretation) async {
    return interpretation['featureType'] == 'maxrm';
  }

  @override
  Future<String?> handle(Map<String, dynamic> interpretation, String userId, UserModel user) async {
    final action = interpretation['action'] as String?;
    _logger.d('Handling maxrm action: $action');

    switch (action) {
      case 'query':
        return await _handleQuery(interpretation, userId);
      case 'update':
        return await _handleUpdate(interpretation, userId);
      case 'list':
        return await _handleList(userId);
      case 'calculate':
        return await _handleCalculate(interpretation);
      default:
        _logger.w('Unrecognized action for maxrm: $action');
        return 'Azione non riconosciuta per maxrm.';
    }
  }

  Future<String?> _handleCalculate(Map<String, dynamic> interpretation) async {
    final weight = interpretation['weight'];
    final reps = interpretation['reps'];

    if (weight != null && reps != null && reps is num && weight is num) {
      final w = double.tryParse(weight.toString()) ?? 0;
      final r = double.tryParse(reps.toString()) ?? 0;
      if (w <= 0 || r <= 0) {
        _logger.w('Invalid weight or reps for calculation.');
        return 'Peso o ripetizioni non validi per il calcolo.';
      }
      final oneRM = w * (1 + r / 30.0);
      _logger.d('Calculated 1RM: $oneRM kg');
      return 'Il tuo 1RM stimato è di circa ${oneRM.toStringAsFixed(1)} kg.';
    }
    _logger.w('Missing weight or reps for calculation.');
    return 'Per calcolare il 1RM, forniscimi peso e ripetizioni.';
  }

  Future<String?> _handleUpdate(Map<String, dynamic> interpretation, String userId) async {
    final exerciseName = interpretation['exercise'];
    final weight = interpretation['weight'];
    final reps = interpretation['reps'];

    if (exerciseName == null || weight == null || reps == null) {
      _logger.w('Missing exerciseName, weight, or reps for update.');
      return 'Per aggiornare il massimale, forniscimi esercizio, peso e ripetizioni.';
    }

    final exerciseId = await _findExerciseId(exerciseName);
    if (exerciseId == null) {
      _logger.w('Exercise not found: $exerciseName');
      return 'Esercizio "$exerciseName" non trovato.';
    }

    final recordId = '${userId}_${DateTime.now().millisecondsSinceEpoch}';
    final recordData = {
      'id': recordId,
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'maxWeight': weight,
      'repetitions': reps,
      'date': Timestamp.fromDate(DateTime.now()),
      'userId': userId,
    };

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('exercises')
          .doc(exerciseId)
          .collection('records')
          .doc(recordId)
          .set(recordData);

      _logger.i('Updated maxrm for $exerciseName: $weight kg x $reps reps.');
      return 'Ho aggiornato il massimale di $exerciseName a ${weight}kg x $reps ripetizioni.';
    } catch (e, stackTrace) {
      _logger.e('Error updating maxrm', error: e, stackTrace: stackTrace);
      return 'Si è verificato un errore durante l\'aggiornamento del massimale.';
    }
  }

  Future<String?> _handleQuery(Map<String, dynamic> interpretation, String userId) async {
    final exerciseName = interpretation['exercise'] as String?;
    if (exerciseName == null) {
      _logger.w('Exercise name not provided for query.');
      return 'Per quale esercizio desideri conoscere il massimale?';
    }

    final formattedName = _formatExerciseName(exerciseName);
    final exerciseId = await _findExerciseId(formattedName);
    if (exerciseId == null) {
      _logger.w('Exercise not found for query: $formattedName');
      return 'Esercizio "$formattedName" non trovato.';
    }

    final recordsQuery = await _firestore
        .collection('users')
        .doc(userId)
        .collection('exercises')
        .doc(exerciseId)
        .collection('records')
        .orderBy('date', descending: true)
        .limit(1)
        .get();

    if (recordsQuery.docs.isEmpty) {
      _logger.w('No records found for exercise: $formattedName');
      return 'Non hai ancora registrato un massimale per "$formattedName".';
    }

    final record = ExerciseRecord.fromFirestore(recordsQuery.docs.first);
    _logger.d('Queried maxrm: ${record.maxWeight} kg x ${record.repetitions} reps');
    return 'Il tuo massimale per $exerciseName è ${record.maxWeight} kg per ${record.repetitions} ripetizioni (aggiornato il ${record.date.toLocal().toString().split(' ')[0]}).';
  }

  Future<String?> _handleList(String userId) async {
    _logger.i('Listing all maxrm records for user: $userId');
    final exercisesRef = _firestore.collection('users').doc(userId).collection('exercises');

    final exercisesSnapshot = await exercisesRef.get();
    if (exercisesSnapshot.docs.isEmpty) {
      _logger.d('No exercises found for user: $userId');
      return 'Non hai ancora nessun esercizio registrato.';
    }

    final buffer = StringBuffer('# I tuoi massimali più recenti\n\n');

    bool foundSomething = false;
    for (var exerciseDoc in exercisesSnapshot.docs) {
      final exerciseId = exerciseDoc.id;
      final exerciseData = exerciseDoc.data();
      final exerciseName = exerciseData['name'] as String?;

      if (exerciseName == null) {
        continue;
      }

      final recordsQuery = await exercisesRef
          .doc(exerciseId)
          .collection('records')
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (recordsQuery.docs.isNotEmpty) {
        final record = ExerciseRecord.fromFirestore(recordsQuery.docs.first);
        buffer.writeln(
          '- **$exerciseName**: ${record.maxWeight}kg x ${record.repetitions} reps _(${record.date.toLocal().toString().split(' ')[0]})_',
        );
        foundSomething = true;
      }
    }

    if (!foundSomething) {
      _logger.d('No maxrm records found for user: $userId');
      return 'Non hai ancora registrato alcun massimale.';
    }

    final result = buffer.toString();
    _logger.d('Maxrm list: $result');
    return result;
  }

  Future<String?> _findExerciseId(String exerciseName) async {
    final formattedName = _formatExerciseName(exerciseName);
    _logger.d('Searching for exercise: $formattedName');

    try {
      final exerciseQuery = await _firestore
          .collection('exercises')
          .where('name', isEqualTo: formattedName)
          .get();

      if (exerciseQuery.docs.isEmpty) {
        _logger.w('Exercise not found in global exercises: $formattedName');
        return null;
      }

      final exerciseId = exerciseQuery.docs.first.id;
      return exerciseId;
    } catch (e, stackTrace) {
      _logger.e('Error finding exercise: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  String _formatExerciseName(String name) {
    return name
        .split(' ')
        .map(
          (word) =>
              word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

class ExerciseRecord {
  final String id;
  final String exerciseId;
  final String exerciseName;
  final num maxWeight;
  final int repetitions;
  final DateTime date;
  final String userId;

  ExerciseRecord({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.maxWeight,
    required this.repetitions,
    required this.date,
    required this.userId,
  });

  factory ExerciseRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExerciseRecord(
      id: data['id'] ?? '',
      exerciseId: data['exerciseId'] ?? '',
      exerciseName: data['exerciseName'] ?? '',
      maxWeight: data['maxWeight'] ?? 0,
      repetitions: data['repetitions'] ?? 0,
      date: (data['date'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
    );
  }
}
