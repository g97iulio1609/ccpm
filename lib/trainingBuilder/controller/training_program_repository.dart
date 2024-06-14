import 'package:alphanessone/trainingBuilder/models/training_model.dart';
import '../training_services.dart';

class TrainingProgramRepository {
  final FirestoreService _service;

  TrainingProgramRepository(this._service);

  Future<TrainingProgram> fetchTrainingProgram(String programId) async {
    return await _service.fetchTrainingProgram(programId);
  }

  Future<void> addOrUpdateTrainingProgram(TrainingProgram program) async {
    await _service.addOrUpdateTrainingProgram(program);
  }

  Future<void> removeToDeleteItems(TrainingProgram program) async {
    await _service.removeToDeleteItems(program);
  }
}