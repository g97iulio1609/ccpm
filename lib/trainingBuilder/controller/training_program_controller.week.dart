part of 'training_program_controller.dart';

extension WeekExtension on TrainingProgramController {
  Future<void> addWeek() async {
    final newWeek = Week(
      id: null,
      number: _program.weeks.length + 1,
      workouts: [
        Workout(
          id: '',
          order: 1,
          exercises: [],
        ),
      ],
    );

    _program.weeks.add(newWeek);
    notifyListeners();
  }

  void removeWeek(int index) {
    final week = _program.weeks[index];
    _removeWeekAndRelatedData(week);
    _program.weeks.removeAt(index);
    _updateWeekNumbers(index);
    notifyListeners();
  }

  void _removeWeekAndRelatedData(Week week) {
    if (week.id != null) {
      _program.trackToDeleteWeeks.add(week.id!);
    }
    week.workouts.forEach(_removeWorkoutAndRelatedData);
  }

  void reorderWeeks(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final week = _program.weeks.removeAt(oldIndex);
    _program.weeks.insert(newIndex, week);
    _updateWeekNumbers(newIndex);
    notifyListeners();
  }

  void _updateWeekNumbers(int startIndex) {
    for (int i = startIndex; i < _program.weeks.length; i++) {
      _program.weeks[i].number = i + 1;
    }
  }

  void updateWeek(int weekIndex, Week updatedWeek) {
    _program.weeks[weekIndex] = updatedWeek;
    _programStateNotifier.updateProgram(_program);
    notifyListeners();
  }

  Future<void> copyWeek(int sourceWeekIndex, BuildContext context) async {
    final destinationWeekIndex = await _showCopyWeekDialog(context);
    if (destinationWeekIndex != null) {
      final sourceWeek = _program.weeks[sourceWeekIndex];
      final copiedWeek = _copyWeek(sourceWeek);

      if (destinationWeekIndex < _program.weeks.length) {
        final destinationWeek = _program.weeks[destinationWeekIndex];
        _program.trackToDeleteWeeks.add(destinationWeek.id!);
        _program.weeks[destinationWeekIndex] = copiedWeek;
      } else {
        copiedWeek.number = _program.weeks.length + 1;
        _program.weeks.add(copiedWeek);
      }

      notifyListeners();
    }
  }

  Week _copyWeek(Week sourceWeek) {
    final copiedWorkouts =
        sourceWeek.workouts.map((workout) => _copyWorkout(workout)).toList();

    return Week(
      id: null,
      number: sourceWeek.number,
      workouts: copiedWorkouts,
    );
  }

  Future<int?> _showCopyWeekDialog(BuildContext context) async {
    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Copy Week'),
          content: DropdownButtonFormField<int>(
            value: null,
            items: List.generate(
              _program.weeks.length + 1,
              (index) => DropdownMenuItem(
                value: index,
                child: Text(index < _program.weeks.length
                    ? 'Week ${_program.weeks[index].number}'
                    : 'New Week'),
              ),
            ),
            onChanged: (value) {
              Navigator.pop(context, value);
            },
            decoration: const InputDecoration(
              labelText: 'Destination Week',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}