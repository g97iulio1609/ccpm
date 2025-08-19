import 'dart:convert';


import '../../shared/shared.dart';

/// Utility per esportare/importare programmi di allenamento
/// - Export: JSON e CSV (stringhe)
/// - Import: da JSON o CSV in `TrainingProgram`
/// KISS/SOLID: singola responsabilità, funzioni pure, nessuna I/O file.
class TrainingShareService {
  TrainingShareService._();

  // -------------------------
  // JSON
  // -------------------------

  static Map<String, dynamic> programToExportMap(TrainingProgram program) {
    return {
      'formatVersion': 1,
      'program': {
        'id': program.id,
        'name': program.name,
        'description': program.description,
        'athleteId': program.athleteId,
        'mesocycleNumber': program.mesocycleNumber,
        'hide': program.hide,
        'status': program.status,
        'weeks': program.weeks.map((w) => _weekToMap(w)).toList(),
      },
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  static String programToJson(TrainingProgram program) {
    final map = programToExportMap(program);
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  static Map<String, dynamic> _weekToMap(Week week) {
    return {
      'id': week.id,
      'number': week.number,
      'name': week.name,
      'description': week.description,
      'isCompleted': week.isCompleted,
      'workouts': week.workouts.map((w) => _workoutToMap(w)).toList(),
    };
  }

  static Map<String, dynamic> _workoutToMap(Workout workout) {
    return {
      'id': workout.id,
      'order': workout.order,
      'name': workout.name,
      'description': workout.description,
      'isCompleted': workout.isCompleted,
      'superSets': workout.superSets,
      'exercises': workout.exercises.map((e) => _exerciseToMap(e)).toList(),
    };
  }

  static Map<String, dynamic> _exerciseToMap(Exercise e) {
    return {
      'id': e.id,
      'exerciseId': e.exerciseId,
      'name': e.name,
      'type': e.type,
      'variant': e.variant,
      'order': e.order,
      'superSetId': e.superSetId,
      'series': e.series.map((s) => s.toMap()).toList(),
      if (e.weekProgressions != null)
        'weekProgressions': e.weekProgressions!
            .map((week) => week.map((wp) => wp.toMap()).toList())
            .toList(),
    };
  }

  static TrainingProgram programFromJson(String jsonString) {
    final dynamic parsed = json.decode(jsonString);
    if (parsed is! Map || parsed['program'] == null) {
      throw ArgumentError('JSON non valido: manca la chiave program');
    }
    final Map<String, dynamic> p = Map<String, dynamic>.from(parsed['program']);

    final program = TrainingProgram(
      id: (p['id'] ?? '') as String?,
      name: (p['name'] ?? '') as String,
      description: (p['description'] ?? '') as String,
      athleteId: (p['athleteId'] ?? '') as String,
      mesocycleNumber: (p['mesocycleNumber'] ?? 0) as int,
      hide: (p['hide'] ?? false) as bool,
      status: (p['status'] ?? 'private') as String,
      weeks: _parseWeeks(p['weeks']),
    );
    return program;
  }

  /// Costruisce un TrainingProgram da una mappa export (programma già parsato)
  static TrainingProgram programFromExportMap(Map<String, dynamic> p) {
    final program = TrainingProgram(
      id: (p['id'] ?? '') as String?,
      name: (p['name'] ?? '') as String,
      description: (p['description'] ?? '') as String,
      athleteId: (p['athleteId'] ?? '') as String,
      mesocycleNumber: (p['mesocycleNumber'] ?? 0) as int,
      hide: (p['hide'] ?? false) as bool,
      status: (p['status'] ?? 'private') as String,
      weeks: _parseWeeks(p['weeks']),
    );
    return program;
  }

  static List<Week> _parseWeeks(dynamic data) {
    if (data == null) return [];
    if (data is! List) return [];
    return data.map((w) => _weekFromMap(Map<String, dynamic>.from(w))).toList();
  }

  static Week _weekFromMap(Map<String, dynamic> map) {
    return Week(
      id: map['id'],
      number: (map['number'] ?? 1) as int,
      name: map['name'],
      description: map['description'],
      isCompleted: (map['isCompleted'] ?? false) as bool,
      workouts: _parseWorkouts(map['workouts']),
    );
  }

  static List<Workout> _parseWorkouts(dynamic data) {
    if (data == null) return [];
    if (data is! List) return [];
    return data
        .map((w) => _workoutFromMap(Map<String, dynamic>.from(w)))
        .toList();
  }

  static Workout _workoutFromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'],
      order: (map['order'] ?? 0) as int,
      name: (map['name'] ?? '') as String,
      description: map['description'],
      isCompleted: (map['isCompleted'] ?? false) as bool,
      superSets: (map['superSets'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      exercises: _parseExercises(map['exercises']),
    );
  }

  static List<Exercise> _parseExercises(dynamic data) {
    if (data == null) return [];
    if (data is! List) return [];
    return data.map((e) => _exerciseFromMap(Map<String, dynamic>.from(e))).toList();
  }

  static Exercise _exerciseFromMap(Map<String, dynamic> map) {
    final series = _parseSeries(map['series']);
    return Exercise(
      id: map['id'],
      exerciseId: map['exerciseId'],
      name: (map['name'] ?? '') as String,
      type: (map['type'] ?? 'weight') as String,
      variant: map['variant'],
      order: (map['order'] ?? 0) as int,
      superSetId: map['superSetId'],
      series: series,
      weekProgressions: _parseWeekProgressions(map['weekProgressions']),
    );
  }

  static List<Series> _parseSeries(dynamic data) {
    if (data == null) return [];
    if (data is! List) return [];
    return data
        .map((s) => Series.fromMap(Map<String, dynamic>.from(s)))
        .toList();
  }

  static List<List<WeekProgression>>? _parseWeekProgressions(dynamic data) {
    if (data == null) return null;
    if (data is! List) return null;
    return data
        .map((week) => (week as List)
            .map((wp) => WeekProgression.fromMap(Map<String, dynamic>.from(wp)))
            .toList())
        .toList();
  }

  // -------------------------
  // CSV
  // -------------------------

  /// Esporta il programma in CSV (una riga per serie).
  /// Delimitatore: ","; i campi testuali sono sempre tra doppi apici con escaping RFC4180.
  static String programToCsv(TrainingProgram program) {
    final headers = [
      'formatVersion',
      'programId',
      'programName',
      'programDescription',
      'athleteId',
      'mesocycleNumber',
      'hide',
      'status',
      'weekNumber',
      'workoutOrder',
      'workoutName',
      'exerciseOrder',
      'exerciseName',
      'exerciseId',
      'type',
      'variant',
      'superSetId',
      'seriesOrder',
      'sets',
      'reps',
      'maxReps',
      'weight',
      'maxWeight',
      'intensity',
      'maxIntensity',
      'rpe',
      'maxRpe',
      'restTimeSeconds',
    ];

    final rows = <List<String>>[];
    rows.add(headers);

    for (final week in program.weeks) {
      for (final workout in week.workouts) {
        if (workout.exercises.isEmpty) {
          // Riga placeholder per workout senza esercizi
          rows.add([
            '1',
            program.id ?? '',
            _q(program.name),
            _q(program.description),
            program.athleteId,
            program.mesocycleNumber.toString(),
            program.hide.toString(),
            program.status,
            week.number.toString(),
            workout.order.toString(),
            _q(workout.name),
            '', // exerciseOrder
            '', // exerciseName
            '', // exerciseId
            '', // type
            '', // variant
            '', // superSetId
            '', // seriesOrder
            '', // sets
            '', // reps
            '', // maxReps
            '', // weight
            '', // maxWeight
            '', // intensity
            '', // maxIntensity
            '', // rpe
            '', // maxRpe
            '', // restTimeSeconds
          ]);
          continue;
        }

        for (final exercise in workout.exercises) {
          if (exercise.series.isEmpty) {
            rows.add([
              '1',
              program.id ?? '',
              _q(program.name),
              _q(program.description),
              program.athleteId,
              program.mesocycleNumber.toString(),
              program.hide.toString(),
              program.status,
              week.number.toString(),
              workout.order.toString(),
              _q(workout.name),
              exercise.order.toString(),
              _q(exercise.name),
              exercise.exerciseId ?? '',
              exercise.type,
              _q(exercise.variant ?? ''),
              exercise.superSetId ?? '',
              '', // seriesOrder
              '0', // sets=0 per placeholder
              '',
              '',
              '',
              '',
              '',
              '',
              '',
              '',
              '',
            ]);
            continue;
          }

          for (var i = 0; i < exercise.series.length; i++) {
            final s = exercise.series[i];
            rows.add([
              '1',
              program.id ?? '',
              _q(program.name),
              _q(program.description),
              program.athleteId,
              program.mesocycleNumber.toString(),
              program.hide.toString(),
              program.status,
              week.number.toString(),
              workout.order.toString(),
              _q(workout.name),
              exercise.order.toString(),
              _q(exercise.name),
              exercise.exerciseId ?? '',
              exercise.type,
              _q(exercise.variant ?? ''),
              exercise.superSetId ?? '',
              (i + 1).toString(),
              (s.sets).toString(),
              (s.reps).toString(),
              s.maxReps?.toString() ?? '',
              s.weight.toString(),
              s.maxWeight?.toString() ?? '',
              s.intensity ?? '',
              s.maxIntensity ?? '',
              s.rpe ?? '',
              s.maxRpe?.toString() ?? '',
              s.restTimeSeconds?.toString() ?? '',
            ]);
          }
        }
      }
    }

    return rows.map((r) => r.map(_csvEscape).join(',')).join('\n');
  }

  /// Importa un programma da CSV. Si aspetta l'header generato da `programToCsv`.
  static TrainingProgram programFromCsv(String csv) {
    final lines = csv.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) throw ArgumentError('CSV vuoto');

    final headers = _parseCsvLine(lines.first);
    final idx = _CsvIndex(headers);
    final rows = lines.skip(1).map(_parseCsvLine).toList();

    String programName = '';
    String programDescription = '';
    String athleteId = '';
    int meso = 0;
    bool hide = false;
    String status = 'private';

    // Aggregazioni: week -> workout -> exercise -> series
    final Map<int, Map<int, Map<int, _ExerciseAgg>>> agg = {};

    for (final row in rows) {
      if (row.isEmpty) continue;

      programName = _get(row, idx.programName) ?? programName;
      programDescription = _get(row, idx.programDescription) ?? programDescription;
      athleteId = _get(row, idx.athleteId) ?? athleteId;
      meso = int.tryParse(_get(row, idx.mesocycleNumber) ?? '') ?? meso;
      hide = (_get(row, idx.hide) ?? hide.toString()) == 'true';
      status = _get(row, idx.status) ?? status;

      final weekNumber = int.tryParse(_get(row, idx.weekNumber) ?? '1') ?? 1;
      final workoutOrder = int.tryParse(_get(row, idx.workoutOrder) ?? '1') ?? 1;
      final exerciseOrder = int.tryParse(_get(row, idx.exerciseOrder) ?? '0') ?? 0;
      final exerciseName = _get(row, idx.exerciseName) ?? '';
      final exerciseId = _get(row, idx.exerciseId);
      final type = _get(row, idx.type) ?? 'weight';
      final variant = _get(row, idx.variant);
      final superSetId = _get(row, idx.superSetId);

      final seriesOrder = int.tryParse(_get(row, idx.seriesOrder) ?? '0') ?? 0;
      final sets = int.tryParse(_get(row, idx.sets) ?? '1') ?? 1;
      final reps = int.tryParse(_get(row, idx.reps) ?? '0') ?? 0;
      final maxReps = _toIntOrNull(_get(row, idx.maxReps));
      final weight = double.tryParse(_get(row, idx.weight) ?? '0') ?? 0.0;
      final maxWeight = _toDoubleOrNull(_get(row, idx.maxWeight));
      final intensity = _get(row, idx.intensity);
      final maxIntensity = _get(row, idx.maxIntensity);
      final rpe = _get(row, idx.rpe);
      final maxRpe = _get(row, idx.maxRpe);
      final restTimeSeconds = _toIntOrNull(_get(row, idx.restTimeSeconds));

      agg.putIfAbsent(weekNumber, () => {});
      agg[weekNumber]!.putIfAbsent(workoutOrder, () => {});
      agg[weekNumber]![workoutOrder]!.putIfAbsent(
        exerciseOrder,
        () => _ExerciseAgg(
          order: exerciseOrder,
          name: exerciseName,
          exerciseId: exerciseId,
          type: type,
          variant: variant,
          superSetId: superSetId,
        ),
      );

      // Se seriesOrder==0 e sets==0 la riga rappresenta solo l'esercizio (placeholder)
      if (seriesOrder > 0 || sets > 0 || reps > 0 || weight > 0) {
        agg[weekNumber]![workoutOrder]![exerciseOrder]!.series.add(
          Series(
            exerciseId: '', // verrà popolato a salvataggio in Firestore
            order: seriesOrder == 0
                ? (agg[weekNumber]![workoutOrder]![exerciseOrder]!.series.length + 1)
                : seriesOrder,
            sets: sets,
            reps: reps,
            maxReps: maxReps,
            weight: weight,
            maxWeight: maxWeight,
            intensity: intensity,
            maxIntensity: maxIntensity,
            rpe: rpe,
            maxRpe: maxRpe,
            restTimeSeconds: restTimeSeconds,
          ),
        );
      }
    }

    final weeks = <Week>[];
    final superSetBuilder = _SuperSetBuilder();

    final sortedWeekKeys = agg.keys.toList()..sort();
    for (final wk in sortedWeekKeys) {
      final workouts = <Workout>[];
      final wkMap = agg[wk]!;
      final sortedWorkoutKeys = wkMap.keys.toList()..sort();
      for (final wod in sortedWorkoutKeys) {
        final exercises = <Exercise>[];
        final exMap = wkMap[wod]!;
        final sortedExKeys = exMap.keys.toList()..sort();
        for (final exKey in sortedExKeys) {
          final eAgg = exMap[exKey]!;
          final ex = Exercise(
            id: null,
            exerciseId: eAgg.exerciseId,
            name: eAgg.name,
            type: eAgg.type ?? 'weight',
            variant: eAgg.variant,
            order: eAgg.order,
            superSetId: eAgg.superSetId,
            series: eAgg.series
                .asMap()
                .entries
                .map((entry) => entry.value.copyWith(order: entry.key + 1))
                .toList(),
          );
          exercises.add(ex);
          if (eAgg.superSetId != null && eAgg.superSetId!.isNotEmpty) {
            superSetBuilder.addExerciseToSet(eAgg.superSetId!, ex);
          }
        }
        workouts.add(Workout(
          id: null,
          order: wod,
          name: 'Workout $wod',
          exercises: exercises,
          superSets: superSetBuilder.buildForExercises(exercises),
        ));
        superSetBuilder.reset();
      }
      weeks.add(Week(id: null, number: wk, workouts: workouts));
    }

    return TrainingProgram(
      name: programName,
      description: programDescription,
      athleteId: athleteId,
      mesocycleNumber: meso,
      hide: hide,
      status: status,
      weeks: weeks,
    );
  }

  // -------------------------
  // Helpers
  // -------------------------

  static String? _get(List<String> row, int? idx) {
    if (idx == null || idx < 0 || idx >= row.length) return null;
    final v = row[idx].trim();
    return v.isEmpty ? null : v;
  }

  static int? _toIntOrNull(String? v) => v == null || v.isEmpty ? null : int.tryParse(v);
  static double? _toDoubleOrNull(String? v) => v == null || v.isEmpty ? null : double.tryParse(v);

  static String _q(String s) => s;

  static String _csvEscape(String value) {
    // Mettiamo tra doppi apici e raddoppiamo eventuali doppi apici interni
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  static List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final sb = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          // Escaped quote
          sb.write('"');
          i++; // skip next
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(sb.toString());
        sb.clear();
      } else {
        sb.write(char);
      }
    }
    result.add(sb.toString());
    return result;
  }
}

class _CsvIndex {
  final int? formatVersion;
  final int? programId;
  final int? programName;
  final int? programDescription;
  final int? athleteId;
  final int? mesocycleNumber;
  final int? hide;
  final int? status;
  final int? weekNumber;
  final int? workoutOrder;
  final int? workoutName;
  final int? exerciseOrder;
  final int? exerciseName;
  final int? exerciseId;
  final int? type;
  final int? variant;
  final int? superSetId;
  final int? seriesOrder;
  final int? sets;
  final int? reps;
  final int? maxReps;
  final int? weight;
  final int? maxWeight;
  final int? intensity;
  final int? maxIntensity;
  final int? rpe;
  final int? maxRpe;
  final int? restTimeSeconds;

  _CsvIndex(List<String> headers)
      : formatVersion = headers.indexOf('formatVersion'),
        programId = headers.indexOf('programId'),
        programName = headers.indexOf('programName'),
        programDescription = headers.indexOf('programDescription'),
        athleteId = headers.indexOf('athleteId'),
        mesocycleNumber = headers.indexOf('mesocycleNumber'),
        hide = headers.indexOf('hide'),
        status = headers.indexOf('status'),
        weekNumber = headers.indexOf('weekNumber'),
        workoutOrder = headers.indexOf('workoutOrder'),
        workoutName = headers.indexOf('workoutName'),
        exerciseOrder = headers.indexOf('exerciseOrder'),
        exerciseName = headers.indexOf('exerciseName'),
        exerciseId = headers.indexOf('exerciseId'),
        type = headers.indexOf('type'),
        variant = headers.indexOf('variant'),
        superSetId = headers.indexOf('superSetId'),
        seriesOrder = headers.indexOf('seriesOrder'),
        sets = headers.indexOf('sets'),
        reps = headers.indexOf('reps'),
        maxReps = headers.indexOf('maxReps'),
        weight = headers.indexOf('weight'),
        maxWeight = headers.indexOf('maxWeight'),
        intensity = headers.indexOf('intensity'),
        maxIntensity = headers.indexOf('maxIntensity'),
        rpe = headers.indexOf('rpe'),
        maxRpe = headers.indexOf('maxRpe'),
        restTimeSeconds = headers.indexOf('restTimeSeconds');
}

class _ExerciseAgg {
  final int order;
  final String name;
  final String? exerciseId;
  final String? type;
  final String? variant;
  final String? superSetId;
  final List<Series> series = [];

  _ExerciseAgg({
    required this.order,
    required this.name,
    required this.exerciseId,
    required this.type,
    required this.variant,
    required this.superSetId,
  });
}

class _SuperSetBuilder {
  final Map<String, List<String>> _setIdToExerciseIds = {};

  void addExerciseToSet(String setId, Exercise exercise) {
    _setIdToExerciseIds.putIfAbsent(setId, () => []);
    if (exercise.id != null) {
      _setIdToExerciseIds[setId]!.add(exercise.id!);
    }
  }

  List<Map<String, dynamic>>? buildForExercises(List<Exercise> exercises) {
    if (_setIdToExerciseIds.isEmpty) return null;
    // Se non abbiamo ID esercizio (in import) possiamo usare placeholder temporanei
    // che verranno riallineati al salvataggio
    return _setIdToExerciseIds.entries
        .map((e) => {
              'id': e.key,
              'name': '',
              'exerciseIds': e.value.isEmpty
                  ? exercises
                      .where((ex) => ex.superSetId == e.key)
                      .map((ex) => ex.id ?? ex.exerciseId ?? '')
                      .toList()
                  : e.value,
            })
        .toList();
  }

  void reset() {
    _setIdToExerciseIds.clear();
  }
}
