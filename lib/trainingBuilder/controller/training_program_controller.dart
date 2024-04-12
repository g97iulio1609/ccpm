import 'dart:math';

import 'package:alphanessone/trainingBuilder/exercise_dialog.dart';
import 'package:alphanessone/trainingBuilder/series_dialog.dart';
import 'package:alphanessone/trainingBuilder/training_model.dart';
import 'package:alphanessone/trainingBuilder/training_program_state_provider.dart';
import 'package:alphanessone/trainingBuilder/training_services.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../utility_functions.dart';
import 'package:alphanessone/users_services.dart';

part 'training_program_controller.service.dart';
part 'training_program_controller.program.dart';
part 'training_program_controller.week.dart';
part 'training_program_controller.workout.dart';
part 'training_program_controller.exercise.dart';
part 'training_program_controller.series.dart';
part 'training_program_controller.super_set.dart';
part 'training_program_controller.ui.dart';

final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

final trainingProgramControllerProvider = ChangeNotifierProvider((ref) {
  final service = ref.watch(firestoreServiceProvider);
  final usersService = ref.watch(usersServiceProvider);
  final programStateNotifier = ref.watch(trainingProgramStateProvider.notifier);
  return TrainingProgramController(service, usersService, programStateNotifier);
});

class TrainingProgramController extends ChangeNotifier {
  final FirestoreService _service;
  final UsersService _usersService;
  final TrainingProgramStateNotifier _programStateNotifier;

  TrainingProgramController(
      this._service, this._usersService, this._programStateNotifier) {
    _initProgram();
  }

  late TrainingProgram _program;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _athleteIdController;
  late TextEditingController _mesocycleNumberController;

  TrainingProgram get program => _programStateNotifier.state;
  TextEditingController get nameController => _nameController;
  TextEditingController get descriptionController => _descriptionController;
  TextEditingController get athleteIdController => _athleteIdController;
  TextEditingController get mesocycleNumberController =>
      _mesocycleNumberController;

  void _initProgram() {
    _program = _programStateNotifier.state;
    _nameController = TextEditingController(text: _program.name);
    _descriptionController = TextEditingController(text: _program.description);
    _athleteIdController = TextEditingController(text: _program.athleteId);
    _mesocycleNumberController =
        TextEditingController(text: _program.mesocycleNumber.toString());
  }

  void resetFields() {
    _initProgram();
    notifyListeners();
  }
}