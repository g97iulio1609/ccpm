import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:alphanessone/models/user_model.dart';
import 'package:alphanessone/exerciseManager/exercises_services.dart';
import 'package:alphanessone/exerciseManager/exercise_model.dart';
import 'ai_extension.dart';

class ExercisesExtension implements AIExtension {
  final Logger _logger = Logger(
    printer: PrettyPrinter(),
  );
  final ExercisesService _exercisesService =
      ExercisesService(FirebaseFirestore.instance);

  @override
  Future<bool> canHandle(Map<String, dynamic> interpretation) async {
    return interpretation['featureType'] == 'exercises';
  }

  @override
  Future<String?> handle(Map<String, dynamic> interpretation, String userId,
      UserModel user) async {
    final action = interpretation['action'] as String?;
    _logger.d('Handling exercises action: $action');

    if (action == null) {
      return 'Azione non specificata per gli esercizi.';
    }

    switch (action) {
      case 'add_exercise':
        return await _handleAddExercise(interpretation, userId);
      case 'update_exercise':
        return await _handleUpdateExercise(interpretation);
      case 'delete_exercise':
        return await _handleDeleteExercise(interpretation);
      case 'approve_exercise':
        return await _handleApproveExercise(interpretation);
      case 'query_exercises':
        return await _handleQueryExercises(interpretation);
      case 'list_exercises':
        return await _handleListExercises();
      default:
        _logger.w('Unrecognized action for exercises: $action');
        return 'Azione non riconosciuta per gli esercizi.';
    }
  }

  Future<String?> _handleAddExercise(
      Map<String, dynamic> interpretation, String userId) async {
    final name = interpretation['name'] as String?;
    final type = interpretation['type'] as String?;
    final muscleGroups =
        (interpretation['muscleGroups'] as List<dynamic>?)?.cast<String>();

    if (name == null || type == null || muscleGroups == null) {
      return 'Nome, tipo e gruppi muscolari sono richiesti per aggiungere un esercizio.';
    }

    try {
      await _exercisesService.addExercise(name, muscleGroups, type, userId);
      return 'Ho aggiunto l\'esercizio "$name" con successo.';
    } catch (e) {
      _logger.e('Error adding exercise', error: e);
      return 'Si è verificato un errore durante l\'aggiunta dell\'esercizio.';
    }
  }

  Future<String?> _handleUpdateExercise(
      Map<String, dynamic> interpretation) async {
    final id = interpretation['id'] as String?;
    final name = interpretation['name'] as String?;
    final type = interpretation['type'] as String?;
    final muscleGroups =
        (interpretation['muscleGroups'] as List<dynamic>?)?.cast<String>();

    if (id == null || name == null || type == null || muscleGroups == null) {
      return 'ID, nome, tipo e gruppi muscolari sono richiesti per aggiornare un esercizio.';
    }

    try {
      await _exercisesService.updateExercise(id, name, muscleGroups, type);
      return 'Ho aggiornato l\'esercizio "$name" con successo.';
    } catch (e) {
      _logger.e('Error updating exercise', error: e);
      return 'Si è verificato un errore durante l\'aggiornamento dell\'esercizio.';
    }
  }

  Future<String?> _handleDeleteExercise(
      Map<String, dynamic> interpretation) async {
    final id = interpretation['id'] as String?;
    final name = interpretation['name'] as String?;

    try {
      if (id != null) {
        await _exercisesService.deleteExercise(id);
        return 'Ho eliminato l\'esercizio con successo.';
      } else if (name != null) {
        // Se abbiamo il nome ma non l'ID, cerchiamo prima l'esercizio
        final exercise = await _exercisesService.getExerciseByName(name);
        await _exercisesService.deleteExercise(exercise.id);
        return 'Ho eliminato l\'esercizio "$name" con successo.';
      } else {
        return 'È necessario specificare l\'ID o il nome dell\'esercizio da eliminare.';
      }
    } catch (e) {
      _logger.e('Error deleting exercise', error: e);
      return 'Si è verificato un errore durante l\'eliminazione dell\'esercizio.';
    }
  }

  Future<String?> _handleApproveExercise(
      Map<String, dynamic> interpretation) async {
    final id = interpretation['id'] as String?;
    final name = interpretation['name'] as String?;

    try {
      if (id != null) {
        await _exercisesService.approveExercise(id);
        return 'Ho approvato l\'esercizio con successo.';
      } else if (name != null) {
        // Se abbiamo il nome ma non l'ID, cerchiamo prima l'esercizio
        final exercise = await _exercisesService.getExerciseByName(name);
        await _exercisesService.approveExercise(exercise.id);
        return 'Ho approvato l\'esercizio "$name" con successo.';
      } else {
        return 'È necessario specificare l\'ID o il nome dell\'esercizio da approvare.';
      }
    } catch (e) {
      _logger.e('Error approving exercise', error: e);
      return 'Si è verificato un errore durante l\'approvazione dell\'esercizio.';
    }
  }

  Future<String?> _handleQueryExercises(
      Map<String, dynamic> interpretation) async {
    try {
      final exercises = await _exercisesService.getExercises().first;

      // Filtra per tipo se specificato
      final type = interpretation['type'] as String?;
      if (type != null) {
        exercises
            .removeWhere((e) => e.type.toLowerCase() != type.toLowerCase());
      }

      // Filtra per gruppi muscolari se specificati
      final muscleGroups =
          (interpretation['muscleGroups'] as List<dynamic>?)?.cast<String>();
      if (muscleGroups != null && muscleGroups.isNotEmpty) {
        exercises.removeWhere((e) => !e.muscleGroups.any((g) =>
            muscleGroups.any((mg) => mg.toLowerCase() == g.toLowerCase())));
      }

      // Filtra per stato se specificato
      final status = interpretation['status'] as String?;
      if (status != null) {
        exercises.removeWhere(
            (e) => e.status?.toLowerCase() != status.toLowerCase());
      }

      if (exercises.isEmpty) {
        return 'Nessun esercizio trovato con i criteri specificati.';
      }

      final buffer = StringBuffer();
      buffer.writeln('Ecco gli esercizi trovati:');

      for (var exercise in exercises) {
        buffer.writeln('\n• ${exercise.name}');
        buffer.writeln('  Tipo: ${exercise.type}');
        buffer
            .writeln('  Gruppi muscolari: ${exercise.muscleGroups.join(", ")}');
        if (exercise.status != null) {
          buffer.writeln('  Stato: ${exercise.status}');
        }
      }

      return buffer.toString();
    } catch (e) {
      _logger.e('Error querying exercises', error: e);
      return 'Si è verificato un errore durante la ricerca degli esercizi.';
    }
  }

  Future<String?> _handleListExercises() async {
    try {
      final exercises = await _exercisesService.getExercises().first;

      if (exercises.isEmpty) {
        return 'Non ci sono esercizi nel database.';
      }

      // Raggruppa gli esercizi per tipo
      final exercisesByType = <String, List<ExerciseModel>>{};
      for (var exercise in exercises) {
        if (!exercisesByType.containsKey(exercise.type)) {
          exercisesByType[exercise.type] = [];
        }
        exercisesByType[exercise.type]!.add(exercise);
      }

      final buffer = StringBuffer();
      buffer.writeln('Lista completa degli esercizi:');

      // Ordina i tipi alfabeticamente
      final sortedTypes = exercisesByType.keys.toList()..sort();

      for (var type in sortedTypes) {
        buffer.writeln('\n📋 $type:');
        // Ordina gli esercizi per nome all'interno di ogni tipo
        final sortedExercises = exercisesByType[type]!
          ..sort((a, b) => a.name.compareTo(b.name));

        for (var exercise in sortedExercises) {
          buffer.write('  • ${exercise.name}');
          if (exercise.status == 'pending') {
            buffer.write(' (in attesa di approvazione)');
          }
          buffer.writeln();
          buffer.writeln(
              '    Gruppi muscolari: ${exercise.muscleGroups.join(", ")}');
        }
      }

      // Aggiungi statistiche
      buffer.writeln('\n📊 Statistiche:');
      buffer.writeln('• Totale esercizi: ${exercises.length}');
      buffer.writeln('• Tipi di esercizi: ${exercisesByType.length}');
      final pendingCount = exercises.where((e) => e.status == 'pending').length;
      if (pendingCount > 0) {
        buffer.writeln('• Esercizi in attesa di approvazione: $pendingCount');
      }

      return buffer.toString();
    } catch (e) {
      _logger.e('Error listing exercises', error: e);
      return 'Si è verificato un errore durante il recupero della lista degli esercizi.';
    }
  }
}
