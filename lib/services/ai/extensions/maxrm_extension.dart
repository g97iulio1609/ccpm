import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:alphanessone/models/user_model.dart';
import 'package:alphanessone/models/exercise_record.dart';
import 'ai_extension.dart';

class MaxRMExtension implements AIExtension {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  @override
  Future<bool> canHandle(Map<String, dynamic> interpretation) async {
    return interpretation['featureType'] == 'maxrm';
  }

  @override
  Future<String?> handle(Map<String, dynamic> interpretation, String userId,
      UserModel user) async {
    final action = interpretation['action'];
    if (action == 'update') {
      return await _handleUpdate(interpretation, userId);
    } else if (action == 'query') {
      return await _handleQuery(interpretation, userId);
    } else if (action == 'list') {
      return await _handleList(userId);
    } else if (action == 'calculate') {
      return await _handleCalculate(interpretation);
    } else {
      return null;
    }
  }

  Future<String?> _handleCalculate(Map<String, dynamic> interpretation) async {
    final weight = interpretation['weight'];
    final reps = interpretation['reps'];

    // Caso standard: weight e reps numerici
    if (weight != null && reps != null && reps is num && weight is num) {
      final w = double.tryParse(weight.toString()) ?? 0;
      final r = double.tryParse(reps.toString()) ?? 0;

      if (w <= 0 || r <= 0) {
        // Dati non validi, fallback
        return null;
      }

      // Calcolo 1RM standard
      final oneRM = w * (1 + r / 30.0);
      return 'Il tuo 1RM stimato è di circa ${oneRM.toStringAsFixed(1)} kg.';
    }

    // Caso non standard, fallback
    return null;
  }

  Future<String?> _handleUpdate(
      Map<String, dynamic> interpretation, String userId) async {
    final exerciseName = interpretation['exercise'];
    final weight = interpretation['weight'];
    final reps = interpretation['reps'];

    if (exerciseName == null || weight == null || reps == null) {
      return null;
    }

    final exerciseId = await _findExerciseId(exerciseName);
    if (exerciseId == null) {
      return null;
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

      return 'Ho aggiornato il massimale di $exerciseName a ${weight}kg x $reps reps.';
    } catch (e) {
      return null;
    }
  }

  Future<String?> _handleQuery(
      Map<String, dynamic> interpretation, String userId) async {
    final exerciseName = interpretation['exercise'];
    if (exerciseName == null) {
      return null;
    }

    final formattedName = _formatExerciseName(exerciseName);
    final exerciseId = await _findExerciseId(formattedName);
    if (exerciseId == null) {
      return null;
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
      return null;
    }

    final record = ExerciseRecord.fromFirestore(recordsQuery.docs.first);
    return 'Il tuo massimale più recente per $formattedName è: ${record.maxWeight}kg x ${record.repetitions} ripetizioni (${record.date.toIso8601String()})';
  }

  Future<String?> _handleList(String userId) async {
    final exercisesRef =
        _firestore.collection('users').doc(userId).collection('exercises');

    final exercisesSnapshot = await exercisesRef.get();
    if (exercisesSnapshot.docs.isEmpty) {
      return null;
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
            '- **$exerciseName**: ${record.maxWeight}kg x ${record.repetitions} reps _(${record.date.toIso8601String()})_');
        foundSomething = true;
      }
    }

    if (!foundSomething) {
      return null;
    }

    return buffer.toString();
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
        _logger.w('Exercise not found: $exerciseName');
        return null;
      }

      final exerciseId = exerciseQuery.docs.first.id;
      return exerciseId;
    } catch (e) {
      _logger.e('Error finding exercise: $e');
      return null;
    }
  }

  String _formatExerciseName(String name) {
    return name
        .split(' ')
        .map((word) => word.isEmpty
            ? ''
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }
}
