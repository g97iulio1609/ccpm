import 'package:alphanessone/trainingBuilder/exercise_dialog.dart';
import 'package:alphanessone/trainingBuilder/series_dialog.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'trainingModel.dart';
import 'trainingServices.dart';
import '../usersServices.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
 return FirestoreService();
});

final trainingProgramControllerProvider = ChangeNotifierProvider((ref) {
 final service = ref.watch(firestoreServiceProvider);
 final usersService = ref.watch(usersServiceProvider);
 return TrainingProgramController(service, usersService);
});

class TrainingProgramController extends ChangeNotifier {
 final FirestoreService _service;
 final UsersService _usersService;

 TrainingProgramController(this._service, this._usersService);

 TrainingProgram _program = TrainingProgram();
 TextEditingController _nameController = TextEditingController();
 TextEditingController _descriptionController = TextEditingController();
 TextEditingController _athleteIdController = TextEditingController();
 TextEditingController _athleteNameController = TextEditingController();
 TextEditingController _mesocycleNumberController = TextEditingController();

 TrainingProgram get program => _program;
 TextEditingController get nameController => _nameController;
 TextEditingController get descriptionController => _descriptionController;
 TextEditingController get athleteIdController => _athleteIdController;
 TextEditingController get athleteNameController => _athleteNameController;
 TextEditingController get mesocycleNumberController => _mesocycleNumberController;

 void loadProgram(String? programId) {
   if (programId != null) {
     _service.fetchTrainingProgram(programId).then((program) {
       _program = program;
       _nameController.text = program.name;
       _descriptionController.text = program.description;
       _athleteIdController.text = program.athleteId;
       _mesocycleNumberController.text = program.mesocycleNumber.toString();
       _rebuildWeekProgressions();
       notifyListeners();
     }).catchError((error) {
       // Handle error
     });
   }
 }

 void addWeek() {
   final newWeek = Week(number: _program.weeks.length + 1, workouts: []);
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
   for (final workout in week.workouts) {
     _removeWorkoutAndRelatedData(workout);
   }
 }

 void addWorkout(int weekIndex) {
   final newWorkout = Workout(
       order: _program.weeks[weekIndex].workouts.length + 1, exercises: []);
   _program.weeks[weekIndex].workouts.add(newWorkout);
   notifyListeners();
 }

 void removeWorkout(int weekIndex, int workoutIndex) {
   final workout = _program.weeks[weekIndex].workouts[workoutIndex];
   _removeWorkoutAndRelatedData(workout);
   _program.weeks[weekIndex].workouts.removeAt(workoutIndex);
   _updateWorkoutOrders(weekIndex, workoutIndex);
   notifyListeners();
 }

 void _removeWorkoutAndRelatedData(Workout workout) {
   if (workout.id != null) {
     _program.trackToDeleteWorkouts.add(workout.id!);
   }
   for (final exercise in workout.exercises) {
     _removeExerciseAndRelatedData(exercise);
   }
 }

 Future<void> addExercise(int weekIndex, int workoutIndex, BuildContext context) async {
   final exercise = await showDialog<Exercise>(
     context: context,
     builder: (context) => ExerciseDialog(
       usersService: _usersService,
       athleteId: _athleteIdController.text,
     ),
   );
   if (exercise != null) {
     exercise.id = UniqueKey().toString();
     exercise.order = _program.weeks[weekIndex].workouts[workoutIndex].exercises.length + 1;
     _program.weeks[weekIndex].workouts[workoutIndex].exercises.add(exercise);
     notifyListeners();
   }
 }

 Future<void> editExercise(int weekIndex, int workoutIndex, int exerciseIndex, BuildContext context) async {
   final exercise = _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
   final updatedExercise = await showDialog<Exercise>(
     context: context,
     builder: (context) => ExerciseDialog(
       usersService: _usersService,
       athleteId: _athleteIdController.text,
       exercise: exercise,
     ),
   );
   if (updatedExercise != null) {
     updatedExercise.order = exercise.order;
     _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex] = updatedExercise;
     notifyListeners();
   }
 }

 void removeExercise(int weekIndex, int workoutIndex, int exerciseIndex) {
   final exercise = _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
   _removeExerciseAndRelatedData(exercise);
   _program.weeks[weekIndex].workouts[workoutIndex].exercises.removeAt(exerciseIndex);
   _updateExerciseOrders(weekIndex, workoutIndex, exerciseIndex);
   notifyListeners();
 }

 void _removeExerciseAndRelatedData(Exercise exercise) {
   if (exercise.id != null) {
     _program.trackToDeleteExercises.add(exercise.id!);
   }
   for (final series in exercise.series) {
     _removeSeriesData(series);
   }
 }

 Future<void> addSeries(int weekIndex, int workoutIndex, int exerciseIndex, BuildContext context) async {
   final exercise = _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
   final seriesList = await showDialog<List<Series>>(
     context: context,
     builder: (context) => SeriesDialog(
       usersService: _usersService,
       athleteId: _athleteIdController.text,
       exerciseId: exercise.exerciseId ?? '',
       weekIndex: weekIndex,
       exercise: exercise,
     ),
   );
   if (seriesList != null) {
     exercise.series.addAll(seriesList);
     notifyListeners();
   }
 }

 Future<void> editSeries(int weekIndex, int workoutIndex, int exerciseIndex, int seriesIndex, BuildContext context) async {
   final series = _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex].series[seriesIndex];
   final exercise = _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];

   final updatedSeriesList = await showDialog<List<Series>>(
     context: context,
     builder: (context) => SeriesDialog(
       usersService: _usersService,
       athleteId: _athleteIdController.text,
       exerciseId: exercise.exerciseId ?? '',
       weekIndex: weekIndex,
       exercise: exercise,
       series: series,
     ),
   );
   if (updatedSeriesList != null) {
     _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex].series.replaceRange(seriesIndex, seriesIndex + 1, updatedSeriesList);
     notifyListeners();
   }
 }

 void removeSeries(int weekIndex, int workoutIndex, int exerciseIndex, int seriesIndex) {
   final series = _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex].series[seriesIndex];
   _removeSeriesData(series);
   _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex].series.removeAt(seriesIndex);
   _updateSeriesOrders(weekIndex, workoutIndex, exerciseIndex, seriesIndex);
   notifyListeners();
 }

 void _removeSeriesData(Series series) {
   if (series.serieId != null) {
     _program.trackToDeleteSeries.add(series.serieId!);
   }
 }

 void updateWeekProgression(int weekIndex, int workoutIndex, int exerciseIndex, WeekProgression weekProgression) {
   if (weekIndex < _program.weeks.length &&
       workoutIndex < _program.weeks[weekIndex].workouts.length &&
       exerciseIndex < _program.weeks[weekIndex].workouts[workoutIndex].exercises.length) {
     _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex]
         .weekProgressions[weekProgression.weekNumber - 1] = weekProgression;
     notifyListeners();
   } else {
     // Handle error or ignore if necessary
   }
 }

 void updateSeries(int weekIndex, int workoutIndex, int exerciseIndex, List<Series> updatedSeries) {
   _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex].series = updatedSeries;
   notifyListeners();
 }

 void applyWeekProgressions(int exerciseIndex, List<WeekProgression> weekProgressions) {
   for (int weekIndex = 0; weekIndex < _program.weeks.length; weekIndex++) {
     final week = _program.weeks[weekIndex];
     for (final workout in week.workouts) {
       for (int currentExerciseIndex = 0; currentExerciseIndex < workout.exercises.length; currentExerciseIndex++) {
         final exercise = workout.exercises[currentExerciseIndex];
         if (currentExerciseIndex == exerciseIndex) {
           final progression = weekIndex < weekProgressions.length
               ? weekProgressions[weekIndex]
               : WeekProgression(
                   weekNumber: weekIndex + 1,
                   reps: 0,
                   sets: 0,
                   intensity: '',
                   rpe: '',
                   weight: 0.0,
                 );

           _updateOrCreateSeries(exercise, progression, weekIndex);
           _updateOrAddWeekProgression(exercise, progression, weekIndex);
         }
       }
     }
   }
   notifyListeners();
 }

 void _updateOrCreateSeries(Exercise exercise, WeekProgression progression, int weekIndex) {
   if (exercise.series.isEmpty) {
     exercise.series = [
       Series(
         serieId: '${weekIndex}_0',
         reps: progression.reps,
         sets: progression.sets,
         intensity: progression.intensity,
         rpe: progression.rpe,
         weight: progression.weight,
         order: 1,
         done: false,
         reps_done: 0,
         weight_done: 0.0,
       ),
     ];
   } else {
     exercise.series[0] = Series(
       serieId: exercise.series[0].serieId,
       reps: progression.reps,
       sets: progression.sets,
       intensity: progression.intensity,
       rpe: progression.rpe,
       weight: progression.weight,
       order: exercise.series[0].order,
       done: exercise.series[0].done,
       reps_done: exercise.series[0].reps_done,
       weight_done: exercise.series[0].weight_done,
     );
   }
 }

 void _updateOrAddWeekProgression(Exercise exercise, WeekProgression progression, int weekIndex) {
   if (weekIndex < exercise.weekProgressions.length) {
     exercise.weekProgressions[weekIndex] = progression;
   } else {
     exercise.weekProgressions.add(progression);
   }
 }

 WeekProgression getWeekProgression(int weekIndex, int exerciseIndex) {
   final week = _program.weeks[weekIndex];
   for (final workout in week.workouts) {
     if (workout.exercises.length > exerciseIndex) {
       final exercise = workout.exercises[exerciseIndex];
       if (exercise.weekProgressions.length > weekIndex) {
         return exercise.weekProgressions[weekIndex];
       }
     }
   }
   return WeekProgression(weekNumber: weekIndex + 1, reps: 0, sets: 0, intensity: '', rpe: '', weight: 0);
 }

 void _rebuildWeekProgressions() {
   for (int weekIndex = 0; weekIndex < _program.weeks.length; weekIndex++) {
     final week = _program.weeks[weekIndex];
     for (final workout in week.workouts) {
       for (final exercise in workout.exercises) {
         final exerciseId = exercise.exerciseId;

         final weekProgressions = List<WeekProgression>.generate(
           _program.weeks.length,
           (index) => WeekProgression(
             weekNumber: index + 1,
             reps: 0,
             sets: 0,
             intensity: '',
             rpe: '',
             weight: 0.0,
           ),
         );

         for (int progressionWeekIndex = 0; progressionWeekIndex < _program.weeks.length; progressionWeekIndex++) {
           final progressionWeek = _program.weeks[progressionWeekIndex];
           for (final progressionWorkout in progressionWeek.workouts) {
             for (final progressionExercise in progressionWorkout.exercises) {
               if (progressionExercise.exerciseId == exerciseId && progressionExercise.series.isNotEmpty) {
                 final series = progressionExercise.series[0];
                 weekProgressions[progressionWeekIndex] = WeekProgression(
                   weekNumber: progressionWeekIndex + 1,
                   reps: series.reps,
                   sets: series.sets,
                   intensity: series.intensity,
                   rpe: series.rpe,
                   weight: series.weight,
                 );
               }
             }
           }
         }

         exercise.weekProgressions = weekProgressions;
       }
     }
   }

   notifyListeners();
 }

 void _rebuildExerciseProgressions(Exercise exercise, int currentWeekIndex) {
   final weekProgressions = List<WeekProgression>.generate(
     _program.weeks.length,
     (index) => WeekProgression(
       weekNumber: index + 1,
       reps: 0,
       sets: 0,
       intensity: '',
       rpe: '',
       weight: 0.0,
     ),
   );

   for (int weekIndex = 0; weekIndex < _program.weeks.length; weekIndex++) {
     final week = _program.weeks[weekIndex];
     for (final workout in week.workouts) {
       for (final currentExercise in workout.exercises) {
         if (currentExercise.id == exercise.id && currentExercise.series.isNotEmpty) {
           final series = currentExercise.series[0];
           weekProgressions[weekIndex] = WeekProgression(
             weekNumber: weekIndex + 1,
             reps: series.reps,
             sets: series.sets,
             intensity: series.intensity,
             rpe: series.rpe,
             weight: series.weight,
           );
         }
       }
     }
   }

   exercise.weekProgressions = weekProgressions;
 }

 void updateExerciseProgressions(Exercise exercise, List<WeekProgression> updatedProgressions) {
   for (int weekIndex= 0; weekIndex < _program.weeks.length; weekIndex++) {
     final week = _program.weeks[weekIndex];
     for (final workout in week.workouts) {
       for (final currentExercise in workout.exercises) {
         if (currentExercise.id == exercise.id) {
           currentExercise.weekProgressions = updatedProgressions;
           _updateOrCreateSeries(currentExercise, updatedProgressions[weekIndex], weekIndex);
         }
       }
     }
   }
   notifyListeners();
 }

 // Reorder
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

 void reorderWorkouts(int weekIndex, int oldIndex, int newIndex) {
   if (oldIndex < newIndex) {
     newIndex -= 1;
   }
   final workout = _program.weeks[weekIndex].workouts.removeAt(oldIndex);
   _program.weeks[weekIndex].workouts.insert(newIndex, workout);
   _updateWorkoutOrders(weekIndex, newIndex);
   notifyListeners();
 }

 void _updateWorkoutOrders(int weekIndex, int startIndex) {
   for (int i = startIndex; i < _program.weeks[weekIndex].workouts.length; i++) {
     _program.weeks[weekIndex].workouts[i].order = i + 1;
   }
 }

 void reorderExercises(int weekIndex, int workoutIndex, int oldIndex, int newIndex) {
   if (oldIndex < newIndex) {
     newIndex -= 1;
   }
   final exercise = _program.weeks[weekIndex].workouts[workoutIndex].exercises.removeAt(oldIndex);
   _program.weeks[weekIndex].workouts[workoutIndex].exercises.insert(newIndex, exercise);
   _updateExerciseOrders(weekIndex, workoutIndex, newIndex);
   notifyListeners();
 }

 void _updateExerciseOrders(int weekIndex, int workoutIndex, int startIndex) {
   for (int i = startIndex; i < _program.weeks[weekIndex].workouts[workoutIndex].exercises.length; i++) {
     _program.weeks[weekIndex].workouts[workoutIndex].exercises[i].order = i + 1;
   }
 }

 void reorderSeries(int weekIndex, int workoutIndex, int exerciseIndex, int oldIndex, int newIndex) {
   if (oldIndex < newIndex) {
     newIndex -= 1;
   }
   final exercise = _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
   final series = exercise.series.removeAt(oldIndex);
   exercise.series.insert(newIndex, series);
   _updateSeriesOrders(weekIndex, workoutIndex, exerciseIndex, newIndex);
   notifyListeners();
 }

 void _updateSeriesOrders(int weekIndex, int workoutIndex, int exerciseIndex, int startIndex) {
   final exercise = _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
   for (int i = startIndex; i < exercise.series.length; i++) {
     exercise.series[i].order = i + 1;
   }
 }

 void submitProgram(BuildContext context) {
   _program.name = _nameController.text;
   _program.description = _descriptionController.text;
   _program.athleteId = _athleteIdController.text;
   _program.mesocycleNumber = int.tryParse(_mesocycleNumberController.text) ?? 0;

   _service.addOrUpdateTrainingProgram(_program).then((_) async {
     await _service.removeToDeleteItems(_program);
     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text('Program added/updated successfully')),
     );
     // resetFields();
   }).catchError((error) {
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text('Error adding/updating program: $error')),
     );
   });
 }

 void resetFields() {
   _program = TrainingProgram();
   _nameController.clear();
   _descriptionController.clear();
   _athleteIdController.clear();
   _mesocycleNumberController.clear();
   notifyListeners();
 }
}