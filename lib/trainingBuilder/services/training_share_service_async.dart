import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Async wrappers via compute to offload heavy (de)serialization

// JSON encode
Future<String> encodeJsonAsync(Map<String, dynamic> exportMap, {bool pretty = true}) {
  return compute(_encodeJsonIsolate, {'map': exportMap, 'pretty': pretty});
}

String _encodeJsonIsolate(Map args) {
  final map = Map<String, dynamic>.from(args['map'] as Map);
  final pretty = args['pretty'] == true;
  final encoder = pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
  return encoder.convert(map);
}

// JSON parse to export map
Future<Map<String, dynamic>> parseJsonToExportMapAsync(String jsonString) {
  return compute(_parseJsonIsolate, jsonString);
}

Map<String, dynamic> _parseJsonIsolate(String jsonString) {
  final parsed = json.decode(jsonString);
  if (parsed is! Map) {
    throw ArgumentError('JSON non valido: root non è un oggetto');
  }
  // Accetta sia il formato con root {"program": {...}} sia direttamente l'oggetto programma {...}
  if (parsed.containsKey('program')) {
    final p = Map<String, dynamic>.from(parsed['program'] as Map);
    return {'program': p};
  }
  // Fallback: se è un programma diretto (contiene settimane o metadati previsti), wrappalo
  if (parsed.containsKey('weeks') || parsed.containsKey('name')) {
    final p = Map<String, dynamic>.from(parsed);
    return {'program': p};
  }
  throw ArgumentError('JSON non valido: atteso {"program": {...}} o un oggetto programma');
}

// CSV builder from export map
Future<String> buildCsvAsync(Map<String, dynamic> exportMap) {
  return compute(_buildCsvIsolate, exportMap);
}

String _buildCsvIsolate(Map<String, dynamic> exportMap) {
  String q(String v) => '"${v.replaceAll('"', '""')}"';

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
    // cardio extensions
    'durationSeconds',
    'distanceMeters',
    'speedKmh',
    'paceSecPerKm',
    'inclinePercent',
    'hrPercent',
    'hrBpm',
    'avgHr',
    'kcal',
    'executedDurationSeconds',
    'executedDistanceMeters',
    'executedAvgHr',
  ];

  final buf = StringBuffer();
  buf.writeln(headers.map(q).join(','));

  final program = Map<String, dynamic>.from(exportMap['program'] ?? exportMap);
  final weeks = (program['weeks'] as List? ?? []);
  for (final w in weeks) {
    final week = Map<String, dynamic>.from(w as Map);
    final workouts = (week['workouts'] as List? ?? []);
    for (final wo in workouts) {
      final workout = Map<String, dynamic>.from(wo as Map);
      final exercises = (workout['exercises'] as List? ?? []);
      if (exercises.isEmpty) {
        final row = [
          '1',
          program['id'] ?? '',
          program['name'] ?? '',
          program['description'] ?? '',
          program['athleteId'] ?? '',
          '${program['mesocycleNumber'] ?? 0}',
          '${program['hide'] ?? false}',
          program['status'] ?? 'private',
          '${week['number'] ?? 1}',
          '${workout['order'] ?? 1}',
          workout['name'] ?? '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
        ];
        buf.writeln(row.map((e) => q(e.toString())).join(','));
        continue;
      }
      for (final ex in exercises) {
        final exercise = Map<String, dynamic>.from(ex as Map);
        final series = (exercise['series'] as List? ?? []);
        if (series.isEmpty) {
          final row = [
            '1',
            program['id'] ?? '',
            program['name'] ?? '',
            program['description'] ?? '',
            program['athleteId'] ?? '',
            '${program['mesocycleNumber'] ?? 0}',
            '${program['hide'] ?? false}',
            program['status'] ?? 'private',
            '${week['number'] ?? 1}', '${workout['order'] ?? 1}', workout['name'] ?? '',
            '${exercise['order'] ?? 1}', exercise['name'] ?? '', exercise['exerciseId'] ?? '',
            exercise['type'] ?? 'weight', exercise['variant'] ?? '', exercise['superSetId'] ?? '',
            '', '0', '', '', '', '', '', '', '', '',
            // cardio blanks
            '', '', '', '', '', '', '', '', '', '', '',
          ];
          buf.writeln(row.map((e) => q(e.toString())).join(','));
          continue;
        }
        for (int i = 0; i < series.length; i++) {
          final s = Map<String, dynamic>.from(series[i] as Map);
          final row = [
            '1',
            program['id'] ?? '',
            program['name'] ?? '',
            program['description'] ?? '',
            program['athleteId'] ?? '',
            '${program['mesocycleNumber'] ?? 0}',
            '${program['hide'] ?? false}',
            program['status'] ?? 'private',
            '${week['number'] ?? 1}', '${workout['order'] ?? 1}', workout['name'] ?? '',
            '${exercise['order'] ?? 1}', exercise['name'] ?? '', exercise['exerciseId'] ?? '',
            exercise['type'] ?? 'weight', exercise['variant'] ?? '', exercise['superSetId'] ?? '',
            '${i + 1}',
            '${s['sets'] ?? 1}',
            '${s['reps'] ?? 0}',
            '${s['maxReps'] ?? ''}',
            '${s['weight'] ?? 0.0}',
            '${s['maxWeight'] ?? ''}',
            '${s['intensity'] ?? ''}',
            '${s['maxIntensity'] ?? ''}',
            '${s['rpe'] ?? ''}',
            '${s['maxRpe'] ?? ''}',
            '${s['restTimeSeconds'] ?? ''}',
            // cardio
            '${s['durationSeconds'] ?? ''}',
            '${s['distanceMeters'] ?? ''}',
            '${s['speedKmh'] ?? ''}',
            '${s['paceSecPerKm'] ?? ''}',
            '${s['inclinePercent'] ?? ''}',
            '${s['hrPercent'] ?? ''}',
            '${s['hrBpm'] ?? ''}',
            '${s['avgHr'] ?? ''}',
            '${s['kcal'] ?? ''}',
            '${s['executedDurationSeconds'] ?? ''}',
            '${s['executedDistanceMeters'] ?? ''}',
            '${s['executedAvgHr'] ?? ''}',
          ];
          buf.writeln(row.map((e) => q(e.toString())).join(','));
        }
      }
    }
  }

  return buf.toString();
}

// CSV parse to export map
Future<Map<String, dynamic>> parseCsvToExportMapAsync(String csv) {
  return compute(_parseCsvIsolate, csv);
}

Map<String, dynamic> _parseCsvIsolate(String csv) {
  final lines = csv.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
  if (lines.isEmpty) throw ArgumentError('CSV vuoto');
  List<String> parse(String line) {
    final result = <String>[];
    final sb = StringBuffer();
    bool inQuotes = false;
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          sb.write('"');
          i++;
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

  final headers = parse(lines.first);
  int idx(String h) => headers.indexOf(h);
  final iWeek = idx('weekNumber');
  final iWO = idx('workoutOrder');
  // workoutName present but ignored; will be rebuilt deterministically
  final iEOrder = idx('exerciseOrder');
  final iEName = idx('exerciseName');
  final iEId = idx('exerciseId');
  final iType = idx('type');
  final iVariant = idx('variant');
  final iSS = idx('superSetId');
  final iSOrder = idx('seriesOrder');
  final iSets = idx('sets');
  final iReps = idx('reps');
  final iMaxReps = idx('maxReps');
  final iWeight = idx('weight');
  final iMaxWeight = idx('maxWeight');
  final iInt = idx('intensity');
  final iMaxInt = idx('maxIntensity');
  final iRpe = idx('rpe');
  final iMaxRpe = idx('maxRpe');
  final iRest = idx('restTimeSeconds');

  String? g(List<String> row, int index) =>
      (index >= 0 && index < row.length) ? (row[index].isEmpty ? null : row[index]) : null;

  final Map<int, Map<int, Map<int, Map<String, dynamic>>>> weeks = {};
  String programName = '';
  String programDescription = '';
  String athleteId = '';
  int meso = 0;
  bool hide = false;
  String status = 'private';

  // pick program-level fields from first content row
  for (final line in lines.skip(1)) {
    final row = parse(line);
    if (row.isEmpty) continue;
    programName = g(row, idx('programName')) ?? programName;
    programDescription = g(row, idx('programDescription')) ?? programDescription;
    athleteId = g(row, idx('athleteId')) ?? athleteId;
    meso = int.tryParse(g(row, idx('mesocycleNumber')) ?? '') ?? meso;
    hide = (g(row, idx('hide')) ?? hide.toString()) == 'true';
    status = g(row, idx('status')) ?? status;

    final wk = int.tryParse(g(row, iWeek) ?? '1') ?? 1;
    final wod = int.tryParse(g(row, iWO) ?? '1') ?? 1;
    // workout name is rebuilt deterministically; header value ignored
    final eOrder = int.tryParse(g(row, iEOrder) ?? '0') ?? 0;
    final eName = g(row, iEName) ?? '';
    final eId = g(row, iEId);
    final eType = g(row, iType) ?? 'weight';
    final eVariant = g(row, iVariant);
    final ss = g(row, iSS);

    final sOrder = int.tryParse(g(row, iSOrder) ?? '0') ?? 0;
    final sets = int.tryParse(g(row, iSets) ?? '1') ?? 1;
    final reps = int.tryParse(g(row, iReps) ?? '0') ?? 0;
    final maxReps = int.tryParse(g(row, iMaxReps) ?? '');
    final weight = double.tryParse(g(row, iWeight) ?? '0') ?? 0.0;
    final maxWeight = double.tryParse(g(row, iMaxWeight) ?? '');
    final intensity = g(row, iInt);
    final maxIntensity = g(row, iMaxInt);
    final rpe = g(row, iRpe);
    final maxRpe = g(row, iMaxRpe);
    final rest = int.tryParse(g(row, iRest) ?? '');

    weeks.putIfAbsent(wk, () => <int, Map<int, Map<String, dynamic>>>{});
    weeks[wk]!.putIfAbsent(wod, () => <int, Map<String, dynamic>>{});
    final exLevel = weeks[wk]![wod]!;
    exLevel.putIfAbsent(
      eOrder,
      () => {
        'order': eOrder,
        'name': eName,
        'exerciseId': eId,
        'type': eType,
        'variant': eVariant,
        'superSetId': ss,
        'series': <Map<String, dynamic>>[],
      },
    );

    if (sOrder > 0 || sets > 0 || reps > 0 || weight > 0) {
      (exLevel[eOrder]!['series'] as List).add({
        'order': sOrder == 0 ? ((exLevel[eOrder]!['series'] as List).length + 1) : sOrder,
        'sets': sets,
        'reps': reps,
        'maxReps': maxReps,
        'weight': weight,
        'maxWeight': maxWeight,
        'intensity': intensity,
        'maxIntensity': maxIntensity,
        'rpe': rpe,
        'maxRpe': maxRpe,
        'restTimeSeconds': rest,
      });
    }
  }

  final weeksOut = <Map<String, dynamic>>[];
  final wkKeys = weeks.keys.toList()..sort();
  for (final wk in wkKeys) {
    final wodList = <Map<String, dynamic>>[];
    final wodMap = weeks[wk]!;
    final wodKeys = wodMap.keys.toList()..sort();
    for (final wod in wodKeys) {
      final exList = <Map<String, dynamic>>[];
      final eMap = wodMap[wod]!;
      final eKeys = eMap.keys.toList()..sort();
      for (final exOrder in eKeys) {
        final ex = eMap[exOrder]!;
        exList.add({
          'order': ex['order'],
          'name': ex['name'],
          'exerciseId': ex['exerciseId'],
          'type': ex['type'],
          'variant': ex['variant'],
          'superSetId': ex['superSetId'],
          'series': (ex['series'] as List).asMap().entries.map((e) {
            final s = Map<String, dynamic>.from(e.value as Map);
            s['order'] = e.key + 1;
            return s;
          }).toList(),
        });
      }
      wodList.add({'order': wod, 'name': 'Workout $wod', 'exercises': exList});
    }
    weeksOut.add({'number': wk, 'workouts': wodList});
  }

  return {
    'program': {
      'name': programName,
      'description': programDescription,
      'athleteId': athleteId,
      'mesocycleNumber': meso,
      'hide': hide,
      'status': status,
      'weeks': weeksOut,
    },
  };
}
