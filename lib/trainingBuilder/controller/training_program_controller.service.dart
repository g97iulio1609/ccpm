part of 'training_program_controller.dart';

extension ServiceExtension on TrainingProgramController {
  Future<void> loadProgram(String? programId) async {
    if (programId == null) {
      _initProgram();
      return;
    }

    try {
      _program = await _service.fetchTrainingProgram(programId);
      _updateProgram();
      loadSuperSets();
    } catch (error) {
      // Handle error
    }
  }

  Future<void> submitProgram(BuildContext context) async {
    _updateProgramFields();

    try {
      await _service.addOrUpdateTrainingProgram(_program);
      await _service.removeToDeleteItems(_program);
      await _usersService.updateUser(
          _athleteIdController.text, {'currentProgram': _program.id});

      _showSuccessSnackBar(context, 'Program added/updated successfully');
    } catch (error) {
      _showErrorSnackBar(context, 'Error adding/updating program: $error');
    }
  }

  Future<void> _onExerciseChanged(String exerciseId) async {
    Exercise? changedExercise = _findExerciseById(exerciseId);

    if (changedExercise != null) {
      final newMaxWeight = await getLatestMaxWeight(
          _usersService, _athleteIdController.text, exerciseId);
      _updateExerciseWeights(changedExercise, newMaxWeight as double);
    }
  }
}